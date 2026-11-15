// Helpers for the /admin pages. Everything is shown in salon time.

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
    return error.message || 'Something went wrong.';
};
