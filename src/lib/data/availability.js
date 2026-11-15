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

const addDays = (iso, n) => {
    const d = fromISODate(iso);
    d.setDate(d.getDate() + n);
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};

const toMinutes = (time) => {
    const [h, m] = time.split(':').map(Number);
    return h * 60 + m;
};

/**
 * Everything the calendar needs, loaded once per visit to /book.
 * { timezone, slotStep, minNotice, horizonDays, onlineBooking,
 *   hours: { [weekday]: { open, close } | null }, busy: [{ start, end }] }
 */
export async function loadSchedule(now = new Date()) {
    const sb = getSupabase();
    const [settings, hours] = await Promise.all([
        sb.from('s4_settings').select('*').single(),
        sb.from('s4_business_hours').select('weekday, is_open, opens_at, closes_at')
    ]);
    if (settings.error || hours.error) {
        throw new AvailabilityError((settings.error || hours.error).message);
    }

    const s = settings.data;
    const schedule = {
        timezone: s.timezone,
        slotStep: s.slot_step_min,
        minNotice: s.min_notice_min,
        horizonDays: s.horizon_days,
        onlineBooking: s.online_booking_enabled,
        hours: Object.fromEntries(hours.data.map(h => [
            h.weekday,
            h.is_open ? { open: toMinutes(h.opens_at), close: toMinutes(h.closes_at) } : null
        ])),
        busy: []
    };
    await refreshBusy(schedule, now);
    return schedule;
}

/** Re-fetch busy times (after a booking race, or when the client returns to the calendar). */
export async function refreshBusy(schedule, now = new Date()) {
    const today = zonedParts(now, schedule.timezone).iso;
    const { data, error } = await getSupabase().rpc('s4_get_busy_times', {
        p_from: today,
        p_to: addDays(today, schedule.horizonDays)
    });
    if (error) throw new AvailabilityError(error.message);
    schedule.busy = data.map(b => ({ start: new Date(b.busy_start).getTime(), end: new Date(b.busy_end).getTime() }));
    return schedule;
}

const weekdayOf = (iso) => fromISODate(iso).getDay();

/** Days from today up to the booking horizon on which the salon is open. */
export function getOpenDays(schedule, now = new Date()) {
    if (!schedule) return [];
    const today = zonedParts(now, schedule.timezone).iso;
    const days = [];
    for (let i = 0; i <= schedule.horizonDays; i++) {
        const iso = addDays(today, i);
        const hours = schedule.hours[weekdayOf(iso)];
        if (!hours) continue;
        // Skip days John has blocked out completely.
        const open = salonInstant(iso, `${pad(Math.floor(hours.open / 60))}:${pad(hours.open % 60)}`, schedule.timezone).getTime();
        const close = salonInstant(iso, `${pad(Math.floor(hours.close / 60))}:${pad(hours.close % 60)}`, schedule.timezone).getTime();
        const blocked = schedule.busy.some(b => b.start <= open && b.end >= close);
        if (!blocked) days.push(iso);
    }
    return days;
}

/**
 * Start times ("HH:MM", salon time) on `isoDate` where a visit of `duration`
 * minutes fits before closing and doesn't overlap a booking or time off.
 */
export function getSlots(schedule, isoDate, duration, now = new Date()) {
    if (!schedule || !isoDate) return [];
    const hours = schedule.hours[weekdayOf(isoDate)];
    if (!hours) return [];
    const earliest = now.getTime() + schedule.minNotice * 60_000;
    const length = Math.max(duration, 1) * 60_000;

    const slots = [];
    for (let start = hours.open; start + Math.max(duration, 1) <= hours.close; start += schedule.slotStep) {
        const hhmm = `${pad(Math.floor(start / 60))}:${pad(start % 60)}`;
        const from = salonInstant(isoDate, hhmm, schedule.timezone).getTime();
        const to = from + length;
        if (from < earliest) continue;
        if (schedule.busy.some(b => b.start < to && b.end > from)) continue;
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
