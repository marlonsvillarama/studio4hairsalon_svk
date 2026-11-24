import { getSupabase } from "$lib/supabase";

// Availability comes from Supabase: opening hours (s4_business_hours),
// booking rules (s4_settings) and busy intervals (s4_get_busy_times, which
// returns times only: confirmed bookings and John's time off).
// All calendar maths happens in salon time (Pacific/Auckland), so a visitor
// whose device is set to another timezone still sees the salon's real hours.

export class AvailabilityError extends Error {}

const pad = (n) => String(n).padStart(2, '0');

/** Wall-clock parts of an instant in a given timezone. */
function zonedParts(date, timeZone) {
    const parts = new Intl.DateTimeFormat('en-CA', {
        timeZone, year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit', hourCycle: 'h23', weekday: 'short'
    }).formatToParts(date);
    const get = (type) => parts.find(p => p.type === type)?.value;
    return {
        iso: `${get('year')}-${get('month')}-${get('day')}`,
        minutes: Number(get('hour')) * 60 + Number(get('minute'))
    };
}

/** Salon-local "YYYY-MM-DD" + "HH:MM" → the real instant (handles daylight saving). */
export function salonInstant(isoDate, hhmm, timeZone) {
    const [y, m, d] = isoDate.split('-').map(Number);
    const [hh, mm] = hhmm.split(':').map(Number);
    const wallAsUtc = Date.UTC(y, m - 1, d, hh, mm);
    let guess = wallAsUtc;
    for (let i = 0; i < 2; i++) {
        const p = zonedParts(new Date(guess), timeZone);
        const [py, pm, pd] = p.iso.split('-').map(Number);
        const seenAsUtc = Date.UTC(py, pm - 1, pd, Math.floor(p.minutes / 60), p.minutes % 60);
        guess += wallAsUtc - seenAsUtc;
    }
    return new Date(guess);
}

/** "YYYY-MM-DD" → local Date at midnight (for display only). */
export const fromISODate = (iso) => {
    const [y, m, d] = iso.split('-').map(Number);
    return new Date(y, m - 1, d);
};

export const addDays = (iso, n) => {
    const d = fromISODate(iso);
    d.setDate(d.getDate() + n);
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};

const toMinutes = (time) => {
    const [h, m] = time.split(':').map(Number);
    return h * 60 + m;
};

/** "YYYY-MM-DD" of the salon's today. */
export const salonToday = (schedule, now = new Date()) =>
    zonedParts(now, schedule?.timezone || 'Pacific/Auckland').iso;

/** "YYYY-MM-DD" → "YYYY-MM" */
export const monthKey = (iso) => iso.slice(0, 7);

const lastOfMonth = (key) => {
    const [y, m] = key.split('-').map(Number);
    return `${key}-${pad(new Date(y, m, 0).getDate())}`;
};

/**
 * Everything the calendar needs, loaded once per visit to /book.
 * { timezone, slotStep, onlineBooking,
 *   hours: { [weekday]: { open, close } | null },
 *   busy: { ["YYYY-MM"]: [{ start, end, gaps: [{ start, end }], canNest }] } }   (months are loaded on demand)
 * Online bookings start tomorrow, with no upper limit.
 */
export async function loadSchedule(now = new Date()) {
    const sb = getSupabase();
    const [settings, hours] = await Promise.all([
        sb.from('s4_settings').select('timezone, slot_step_min, online_booking_enabled').single(),
        sb.from('s4_business_hours').select('weekday, is_open, opens_at, closes_at')
    ]);
    if (settings.error || hours.error) {
        throw new AvailabilityError((settings.error || hours.error).message);
    }

    const s = settings.data;
    const schedule = {
        timezone: s.timezone,
        slotStep: s.slot_step_min,
        onlineBooking: s.online_booking_enabled,
        hours: Object.fromEntries(hours.data.map(h => [
            h.weekday,
            h.is_open ? { open: toMinutes(h.opens_at), close: toMinutes(h.closes_at) } : null
        ])),
        busy: {}
    };
    // Tomorrow's month plus the next one, so the default day and a first
    // page forward in the calendar need no extra round trip.
    const first = monthKey(addDays(salonToday(schedule, now), 1));
    await refreshBusy(schedule, [first, monthKey(addDays(`${first}-01`, 32))]);
    return schedule;
}

/**
 * (Re-)fetch busy times for the given months ("YYYY-MM"); with no months,
 * refresh every month already loaded. Past days are never fetched.
 */
export async function refreshBusy(schedule, months = Object.keys(schedule.busy), now = new Date()) {
    const keys = [...new Set(months)].sort();
    if (!keys.length) return schedule;
    const today = salonToday(schedule, now);
    const from = `${keys[0]}-01` < today ? today : `${keys[0]}-01`;
    const to = lastOfMonth(keys[keys.length - 1]);
    if (to < from) {
        for (const k of keys) schedule.busy[k] = [];
        return schedule;
    }
    // The RPC caps a range at 62 days, so fetch anything but a single month
    // or two neighbouring months one by one.
    const neighbours = keys.length === 2 && monthKey(addDays(`${keys[0]}-01`, 32)) === keys[1];
    if (keys.length > 1 && !neighbours) {
        await Promise.all(keys.map(k => refreshBusy(schedule, [k], now)));
        return schedule;
    }
    const { data, error } = await getSupabase().rpc('s4_get_busy_times', { p_from: from, p_to: to });
    if (error) throw new AvailabilityError(error.message);
    const intervals = data.map(b => ({
        start: new Date(b.busy_start).getTime(),
        end: new Date(b.busy_end).getTime(),
        gaps: (b.gaps || []).map(g => ({ start: new Date(g.start).getTime(), end: new Date(g.end).getTime() })),
        canNest: !!b.can_nest
    }));
    for (const k of keys) schedule.busy[k] = intervals;
    return schedule;
}

/** Whether busy times for a month are loaded. */
export const isMonthLoaded = (schedule, key) => !!schedule?.busy[key];

const weekdayOf = (iso) => fromISODate(iso).getDay();
const busyOn = (schedule, iso) => schedule.busy[monthKey(iso)] || [];

/** Whether a day can be booked online: from tomorrow, salon open, not blocked out. */
export function isOpenDay(schedule, iso, now = new Date()) {
    if (!schedule || !isMonthLoaded(schedule, monthKey(iso))) return false;
    if (iso <= salonToday(schedule, now)) return false;
    const hours = schedule.hours[weekdayOf(iso)];
    if (!hours) return false;
    // Skip days John has blocked out completely.
    const open = salonInstant(iso, `${pad(Math.floor(hours.open / 60))}:${pad(hours.open % 60)}`, schedule.timezone).getTime();
    const close = salonInstant(iso, `${pad(Math.floor(hours.close / 60))}:${pad(hours.close % 60)}`, schedule.timezone).getTime();
    return !busyOn(schedule, iso).some(b => b.start <= open && b.end >= close && !b.gaps.length);
}

/** Bookable days in a month ("YYYY-MM"); [] until that month is loaded. */
export function getOpenDays(schedule, key, now = new Date()) {
    if (!schedule || !isMonthLoaded(schedule, key)) return [];
    const days = [];
    for (let iso = `${key}-01`; monthKey(iso) === key; iso = addDays(iso, 1)) {
        if (isOpenDay(schedule, iso, now)) days.push(iso);
    }
    return days;
}

const within = (inner, gaps) => gaps.some(g => g.start <= inner.start && g.end >= inner.end);

/**
 * Whether a visit clashes with what's booked. Visits may overlap only when one
 * sits wholly inside a waiting period of the other, one level deep. Mirrors
 * s4_bookings_check_overlap in the database, which has the final say.
 */
export function clashes(visit, busy) {
    let inside = 0, around = 0;
    for (const b of busy) {
        if (b.start >= visit.end || b.end <= visit.start) continue;
        if (within(visit, b.gaps)) inside += 1;
        else if (b.canNest && within(b, visit.gaps)) around += 1;
        else return true;
    }
    return inside > 1 || (inside > 0 && around > 0);
}

/**
 * Start times ("HH:MM", salon time) on `isoDate` where a visit of `duration`
 * minutes fits before closing and doesn't clash with a booking or time off.
 * `gaps` are the visit's own waiting periods, in minutes from its start.
 */
export function getSlots(schedule, isoDate, duration, gaps = [], now = new Date()) {
    if (!schedule || !isoDate || !isOpenDay(schedule, isoDate, now)) return [];
    const hours = schedule.hours[weekdayOf(isoDate)];
    const length = Math.max(duration, 1) * 60_000;
    const busy = busyOn(schedule, isoDate);

    const slots = [];
    for (let start = hours.open; start + Math.max(duration, 1) <= hours.close; start += schedule.slotStep) {
        const hhmm = `${pad(Math.floor(start / 60))}:${pad(start % 60)}`;
        const from = salonInstant(isoDate, hhmm, schedule.timezone).getTime();
        const to = from + length;
        const ownGaps = gaps.map(g => ({ start: from + g.start * 60_000, end: from + g.end * 60_000 }));
        if (clashes({ start: from, end: to, gaps: ownGaps }, busy)) continue;
        slots.push(hhmm);
    }
    return slots;
}

/** "14:30" → "2:30 pm" */
export const formatTime = (hhmm) => {
    const [h, m] = hhmm.split(':').map(Number);
    return new Date(2000, 0, 1, h, m).toLocaleTimeString('en-NZ', { hour: 'numeric', minute: '2-digit' });
};

/** "YYYY-MM-DD" → "Tuesday 18 November" */
export const formatLongDate = (iso) =>
    fromISODate(iso).toLocaleDateString('en-NZ', { weekday: 'long', day: 'numeric', month: 'long' });
