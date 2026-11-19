// Helpers for the /admin pages. Everything is shown in salon time.

import { salonInstant } from '$lib/data/availability';

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

/** "+64221885240" → "022 188 5240" for display; leaves other formats alone. */
export const showPhone = (e164) => {
    if (!e164?.startsWith('+64')) return e164 || '';
    const n = `0${e164.slice(3)}`;
    return n.length === 10 ? `${n.slice(0, 3)} ${n.slice(3, 6)} ${n.slice(6)}` : n;
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
export const rangeTitle = (view, iso) => {
    const d = new Date(isoToUtc(iso));
    const fmtUtc = (opts) => new Intl.DateTimeFormat('en-NZ', { timeZone: 'UTC', ...opts });
    if (view === 'day') return fmtUtc({ weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(d);
    if (view === 'month') return fmtUtc({ month: 'long', year: 'numeric' }).format(d);
    const start = new Date(isoToUtc(startOfWeek(iso)));
    const end = new Date(isoToUtc(addDays(startOfWeek(iso), 6)));
    const sameMonth = start.getUTCMonth() === end.getUTCMonth();
    return sameMonth
        ? `${start.getUTCDate()}–${fmtUtc({ day: 'numeric', month: 'long', year: 'numeric' }).format(end)}`
        : `${fmtUtc({ day: 'numeric', month: 'short' }).format(start)} – ${fmtUtc({ day: 'numeric', month: 'short', year: 'numeric' }).format(end)}`;
};

/** Short day label for column headers, e.g. "Thu 19". */
export const dayLabel = (iso) =>
    new Intl.DateTimeFormat('en-NZ', { timeZone: 'UTC', weekday: 'short', day: 'numeric' }).format(new Date(isoToUtc(iso)));

export const STATUS_LABEL = { confirmed: 'Confirmed', cancelled: 'Cancelled', completed: 'Completed', no_show: 'No-show' };
export const isInactive = (b) => b.status === 'cancelled' || b.status === 'no_show';

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
            reason: t.reason ?? ''
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
