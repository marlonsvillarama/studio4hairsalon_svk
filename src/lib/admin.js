// Helpers for the /admin pages. Everything is shown in salon time.

import { salonInstant } from '$lib/data/availability';
import { getSupabase } from '$lib/supabase';
import { parsePhoneNumberFromString } from 'libphonenumber-js/min';

export const SALON_TZ = 'Pacific/Auckland';

const fmt = (opts) => new Intl.DateTimeFormat('en-NZ', { timeZone: SALON_TZ, ...opts });
const dayKeyFmt = fmt({ year: 'numeric', month: '2-digit', day: '2-digit' });

/** Instant → "YYYY-MM-DD" in salon time (for grouping and date inputs). */
export const salonDay = (instant) => {
    const p = Object.fromEntries(dayKeyFmt.formatToParts(new Date(instant)).map(x => [x.type, x.value]));
    return `${p.year}-${p.month}-${p.day}`;
};

/** Instant → "HH:MM" in salon time (for time inputs). */
export const salonTime = (instant) =>
    fmt({ hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(new Date(instant));

export const showTime = (instant) => fmt({ hour: 'numeric', minute: '2-digit' }).format(new Date(instant));
export const showDay = (instant) => fmt({ weekday: 'long', day: 'numeric', month: 'long' }).format(new Date(instant));
export const showShortDay = (instant) => fmt({ weekday: 'short', day: 'numeric', month: 'short' }).format(new Date(instant));

export const dollars = (cents) => new Intl.NumberFormat('en-NZ', {
    style: 'currency', currency: 'NZD', minimumFractionDigits: 0, maximumFractionDigits: 2
}).format((cents ?? 0) / 100);

/** "+64221885240" → "022 188 5240"; other countries "+61 412 345 678". */
export const showPhone = (e164) => {
    if (!e164) return '';
    const p = parsePhoneNumberFromString(e164);
    if (!p) return e164;
    return p.countryCallingCode === '64' ? p.formatNational() : p.formatInternational();
};

/** Friendly text for a Supabase error during an admin action. */
export const adminError = (error) => {
    if (!error) return '';
    if (error.code === '23P01') return 'That time overlaps another confirmed booking.';
    if (error.code === '42501') return "You don't have permission to do that.";
    if (error.code === '23514') return 'One of the values is out of range. Please check and try again.';
    if (error.code === '23505') return 'Something with that name already exists. Please choose another name.';
    if (error.code === '23503') return "It's still used by bookings or services, so it can't be deleted.";
    return error.message || 'Something went wrong.';
};

/** "Hair & Make-up!" → "hair-and-make-up" (for category slugs). */
export const slugify = (name) => name
    .toLowerCase()
    .normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60) || 'category';

/** Soft-removed rows keep a suffix on their slug so the name can be reused. */
export const removedSlug = (slug, id) => `${slug}--removed-${id}`;
export const restoredSlug = (slug) => slug.replace(/--removed-\d+$/, '');

// ─── calendar helpers (dates are "YYYY-MM-DD" in salon time) ─────────────

const isoToUtc = (iso) => {
    const [y, m, d] = iso.split('-').map(Number);
    return Date.UTC(y, m - 1, d);
};
const utcToIso = (ms) => new Date(ms).toISOString().slice(0, 10);

export const addDays = (iso, n) => utcToIso(isoToUtc(iso) + n * 86_400_000);
export const weekdayOf = (iso) => new Date(isoToUtc(iso)).getUTCDay();          // 0 = Sunday
export const startOfWeek = (iso) => addDays(iso, -((weekdayOf(iso) + 6) % 7));  // Monday
export const addMonths = (iso, n) => {
    const d = new Date(isoToUtc(iso));
    return utcToIso(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + n, 1));
};
export const startOfMonth = (iso) => `${iso.slice(0, 7)}-01`;

/** The 42 days (6 weeks, Monday first) shown in a month grid. */
export const monthGrid = (iso) => {
    const first = startOfWeek(startOfMonth(iso));
    return Array.from({ length: 42 }, (_, i) => addDays(first, i));
};

/** Minutes since salon midnight of `iso` for an instant (can be <0 or >1440). */
export const minutesFrom = (iso, instant, dayStartMs) => (new Date(instant).getTime() - dayStartMs) / 60_000;

/** Toolbar heading for the current view. */
// short: phone-width version ("Sat, 28 Nov 2026", "23–29 Nov 2026").
export const rangeTitle = (view, iso, short = false) => {
    const d = new Date(isoToUtc(iso));
    const fmtUtc = (opts) => new Intl.DateTimeFormat('en-NZ', { timeZone: 'UTC', ...opts });
    const month = short ? 'short' : 'long';
    if (view === 'day') return fmtUtc({ weekday: short ? 'short' : 'long', day: 'numeric', month, year: 'numeric' }).format(d);
    if (view === 'month') return fmtUtc({ month: 'long', year: 'numeric' }).format(d);
    const start = new Date(isoToUtc(startOfWeek(iso)));
    const end = new Date(isoToUtc(addDays(startOfWeek(iso), 6)));
    const sameMonth = start.getUTCMonth() === end.getUTCMonth();
    return sameMonth
        ? `${start.getUTCDate()}–${fmtUtc({ day: 'numeric', month, year: 'numeric' }).format(end)}`
        : `${fmtUtc({ day: 'numeric', month: 'short' }).format(start)} – ${fmtUtc({ day: 'numeric', month: 'short', year: 'numeric' }).format(end)}`;
};

/** Short day label for column headers, e.g. "Thu 19". */
export const dayLabel = (iso) =>
    new Intl.DateTimeFormat('en-NZ', { timeZone: 'UTC', weekday: 'short', day: 'numeric' }).format(new Date(isoToUtc(iso)));

export const STATUS_LABEL = { confirmed: 'Confirmed', cancelled: 'Cancelled', completed: 'Completed', no_show: 'No-show' };
export const isInactive = (b) => b.status === 'cancelled' || b.status === 'no_show';

// ─── waiting time inside a booking ───────────────────────────────────────

/** A booking's waiting periods ("{[30,60)}", minutes from its start) as [{ start, end }] in ms. */
export const bookingGaps = (b) => {
    const from = new Date(b.starts_at).getTime();
    return [...(b.gaps ?? '').matchAll(/\[(\d+),(\d+)\)/g)]
        .map(([, s, e]) => ({ start: from + s * 60_000, end: from + e * 60_000 }));
};

/** Whether `inner` sits inside one of `host`'s waiting periods (both going ahead). */
export const sitsInside = (inner, host) => inner.id !== host.id && !isInactive(inner) && !isInactive(host)
    && bookingGaps(host).some(g => g.start <= new Date(inner.starts_at).getTime() && g.end >= new Date(inner.ends_at).getTime());

// ─── paged tables ────────────────────────────────────────────────────────

export const PAGE_SIZES = [10, 20, 50];
export const DEFAULT_PAGE_SIZE = 20;

/** Page 3 of 20 → [40, 59] for PostgREST .range(). */
export const pageRange = (page, size) => [(page - 1) * size, page * size - 1];

/** The rows-per-page choice for a table, remembered on this device. */
export function savedPageSize(table) {
    try {
        const n = Number(localStorage.getItem(`s4.admin.pageSize.${table}`));
        return PAGE_SIZES.includes(n) ? n : DEFAULT_PAGE_SIZE;
    } catch { return DEFAULT_PAGE_SIZE; }
}
export function savePageSize(table, n) {
    try { localStorage.setItem(`s4.admin.pageSize.${table}`, String(n)); } catch { /* private mode: fine */ }
}

/** Read a positive page number / allowed page size from the URL. */
export const urlPage = (url, key = 'page') => Math.max(1, Number.parseInt(url.searchParams.get(key) ?? '', 10) || 1);
export const urlSize = (url, table, key = 'size') => {
    const n = Number(url.searchParams.get(key));
    return PAGE_SIZES.includes(n) ? n : savedPageSize(table);
};

/** Text for a PostgREST ilike filter inside .or(): wildcards escaped, separators removed. */
export const likeText = (q) => q.replace(/[,()]/g, ' ').replace(/[\\%_]/g, '\\$&').trim();

// ─── opening hours and the clock ─────────────────────────────────────────

const toMinutes = (t) => { const [h, m] = t.split(':').map(Number); return h * 60 + m; };

/** Opening hours as { [weekday]: { open, close } (minutes) | null }. Throws on error. */
export async function loadHours() {
    const { data, error } = await getSupabase().from('s4_business_hours').select('weekday, is_open, opens_at, closes_at');
    if (error) throw error;
    return Object.fromEntries(data.map(d => [d.weekday, d.is_open ? { open: toMinutes(d.opens_at), close: toMinutes(d.closes_at) } : null]));
}

/**
 * Calls `tick(Date.now())` at the start of every minute, and straight away
 * when the tab becomes visible again (background tabs slow their timers).
 * Returns a function that stops it.
 */
export function everyMinute(tick) {
    let timer;
    const schedule = () => {
        clearTimeout(timer);
        timer = setTimeout(() => { tick(Date.now()); schedule(); }, 60_000 - (Date.now() % 60_000) + 50);
    };
    const onVisible = () => { if (document.visibilityState === 'visible') { tick(Date.now()); schedule(); } };
    document.addEventListener('visibilitychange', onVisible);
    schedule();
    return () => { clearTimeout(timer); document.removeEventListener('visibilitychange', onVisible); };
}

/** Whether two bookings (both going ahead) share any time, e.g. interleaved in each other's waiting time. */
export const overlapsWith = (a, z) => a.id !== z.id && !isInactive(a) && !isInactive(z)
    && new Date(a.starts_at) < new Date(z.ends_at) && new Date(z.starts_at) < new Date(a.ends_at);

// ─── time off on a given day ─────────────────────────────────────────────

/** 750 → "12:30" */
export const minutesToHHMM = (m) =>
    `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(Math.round(m % 60)).padStart(2, '0')}`;

/**
 * Time off that touches salon day `iso`, as minutes after salon midnight,
 * clipped to that day. `fullDay` is true when the blocks cover the day's
 * opening hours (or the whole day if the salon is closed), i.e. a day off.
 * @returns {{ blocks: { start: number, end: number, reason: string }[], fullDay: boolean, reason: string }}
 */
export function blocksForDay(iso, timeOff, hours) {
    const dayStart = salonInstant(iso, '00:00', SALON_TZ).getTime();
    const dayLen = (salonInstant(addDays(iso, 1), '00:00', SALON_TZ).getTime() - dayStart) / 60_000;
    const blocks = (timeOff ?? [])
        .map(t => ({
            start: Math.max(0, (new Date(t.starts_at).getTime() - dayStart) / 60_000),
            end: Math.min(dayLen, (new Date(t.ends_at).getTime() - dayStart) / 60_000),
            reason: t.reason ?? '',
            hold: t.kind === 'hold'
        }))
        .filter(b => b.end > b.start)
        .sort((a, z) => a.start - z.start);

    // On a day the salon is closed anyway, time off changes nothing: show "Closed".
    const h = hours?.[weekdayOf(iso)];
    if (!h) return { blocks: [], fullDay: false, reason: '' };
    const [from, to] = [h.open, h.close];
    let reach = from;
    for (const b of blocks) {
        if (b.start > reach) break;
        reach = Math.max(reach, b.end);
    }
    const fullDay = blocks.length > 0 && reach >= to;
    const reason = blocks.find(b => b.start <= from && b.end >= Math.min(to, from + 1))?.reason || blocks[0]?.reason || '';
    return { blocks, fullDay, reason };
}
