// Phone numbers in the admin: a country selector plus the number formatted as
// it's typed, saved as E.164 ("+64211234567"). Uses libphonenumber-js.

import { AsYouType, parsePhoneNumberFromString, getCountryCallingCode } from 'libphonenumber-js/min';

/** Countries offered in the selector, NZ first. '' = Other (type a full +number). */
export const COUNTRIES = [
    { code: 'NZ', name: 'New Zealand' },
    { code: 'AU', name: 'Australia' },
    { code: 'US', name: 'United States / Canada' },
    { code: 'GB', name: 'United Kingdom' },
    { code: 'FJ', name: 'Fiji' },
    { code: 'WS', name: 'Samoa' },
    { code: 'TO', name: 'Tonga' },
    { code: 'CK', name: 'Cook Islands' },
    { code: 'PH', name: 'Philippines' },
    { code: 'IN', name: 'India' },
    { code: 'CN', name: 'China' }
].map(c => ({ ...c, dial: `+${getCountryCallingCode(c.code)}` }));

const KNOWN = new Set(COUNTRIES.map(c => c.code));
// Several countries share a code (+44 also covers Jersey, +1 Canada): use the one we list.
const listed = (country, callingCode) => KNOWN.has(country) ? country
    : (callingCode ? COUNTRIES.find(c => c.dial === `+${callingCode}`)?.code ?? null : null);
// Countries where numbers are written with a leading 0 at home ("021 …").
const TRUNK_ZERO = new Set(['NZ', 'AU', 'GB', 'PH', 'IN', 'CN']);

export const countryName = (code) => COUNTRIES.find(c => c.code === code)?.name ?? 'international';

/**
 * Format what's been typed. A full "+…" number switches the country when it's
 * one we list (otherwise to Other). Returns { text, country }.
 */
export function formatPhone(country, raw) {
    const typed = (raw ?? '').trim();
    if (typed.startsWith('+') || !country) {
        const plus = '+' + typed.replace(/\D/g, '');
        if (plus === '+') return { text: typed.startsWith('+') ? '+' : '', country };
        const a = new AsYouType();
        const out = a.input(plus);
        const found = listed(a.getCountry(), a.getCallingCode());
        if (found && KNOWN.has(found)) {
            // Show it the local way under that country's flag.
            const digits = a.getNationalNumber();
            return formatPhone(found, TRUNK_ZERO.has(found) ? `0${digits}` : digits);
        }
        return { text: out, country: '' };
    }
    let digits = typed.replace(/\D/g, '');
    if (!digits) return { text: '', country };
    if (TRUNK_ZERO.has(country) && !digits.startsWith('0')) digits = `0${digits}`;
    return { text: new AsYouType(country).input(digits), country };
}

const parse = (country, text) => {
    const t = (text ?? '').trim();
    if (!t) return null;
    return t.startsWith('+') || !country ? parsePhoneNumberFromString(t.startsWith('+') ? t : `+${t}`) : parsePhoneNumberFromString(t, country);
};

/** Whether the typed number is a real number for that country. */
export const isValidPhone = (country, text) => !!parse(country, text)?.isValid();

/** "+64211234567", or null when it can't be read. */
export const toE164 = (country, text) => parse(country, text)?.number ?? null;

/** For a stored number: { country, text } to put back in the field. */
export function fromE164(e164) {
    if (!e164) return { country: 'NZ', text: '' };
    const p = parsePhoneNumberFromString(e164);
    const c = p && listed(p.country, p.countryCallingCode);
    if (c) {
        const n = parsePhoneNumberFromString(p.nationalNumber, c);
        return { country: c, text: (n ?? p).formatNational() };
    }
    return { country: '', text: p ? p.formatInternational() : e164 };
}

/** The local digits of a "+…" number ("+33 6 12…" → "612…"), for when a country is picked. */
export const nationalDigits = (text) => {
    const t = (text ?? '').trim();
    if (!t.startsWith('+')) return t;
    return parsePhoneNumberFromString(t)?.nationalNumber ?? '';
};

/** "+64 21 123 4567" for summaries. */
export const showInternational = (country, text) => parse(country, text)?.formatInternational() ?? (text ?? '');
