// Tax invoice helpers for the admin. The database (s4_invoice_* functions)
// is the source of truth for numbers and totals; these only format values
// and preview totals while a draft is being edited.

import { getSupabase, errorCode } from '$lib/supabase';
import { adminError } from '$lib/admin';

/** 12 → "INV-0012" */
export const invoiceNumber = (n) => n == null ? 'Draft' : `INV-${String(n).padStart(4, '0')}`;

/** Prices are GST-inclusive at 15%, so GST is 3/23 of the total. */
export const gstOf = (totalCents) => Math.round((totalCents * 3) / 23);

/** Cents → "$1,234.50" (always two decimals on invoices). */
export const money = (cents) => new Intl.NumberFormat('en-NZ', {
    style: 'currency', currency: 'NZD', minimumFractionDigits: 2, maximumFractionDigits: 2
}).format((cents ?? 0) / 100);

/** "123456789" → "123-456-789" (8 digits → "12-345-678"). */
export const showGst = (gst) => {
    const d = (gst || '').replace(/\D/g, '');
    if (d.length === 9) return `${d.slice(0, 3)}-${d.slice(3, 6)}-${d.slice(6)}`;
    if (d.length === 8) return `${d.slice(0, 2)}-${d.slice(2, 5)}-${d.slice(5)}`;
    return gst || '';
};

/** "YYYY-MM-DD" → "20 November 2026" */
export const showIssueDate = (iso) => {
    if (!iso) return '';
    const [y, m, d] = iso.split('-').map(Number);
    return new Date(y, m - 1, d).toLocaleDateString('en-NZ', { day: 'numeric', month: 'long', year: 'numeric' });
};

export const INVOICE_STATUS = { draft: 'Draft', issued: 'Issued', void: 'Void' };

const MESSAGES = {
    not_completed: 'Only completed bookings can be invoiced. Mark the booking completed first.',
    invoice_locked: "This invoice has been issued, so it can't be changed. Void it to make a new one.",
    invalid_lines: 'Check the lines: each needs a description, a quantity of 1–99, and the total can’t be below $0.',
    business_details_missing: 'Add your business name and GST number in Settings before issuing invoices.',
    reason_required: 'Give a reason for voiding this invoice.',
    not_found: 'That invoice no longer exists.',
    not_staff: "You don't have permission to do that."
};

/** Friendly text for an invoice RPC error. */
export const invoiceError = (error) => MESSAGES[errorCode(error)] || adminError(error);

/** Open (or create) the draft/issued invoice for a completed booking; returns its id. */
export async function invoiceForBooking(bookingId) {
    const { data, error } = await getSupabase().rpc('s4_invoice_draft', { p_booking_id: bookingId });
    if (error) throw new Error(invoiceError(error));
    return data;
}

/** An invoice with its lines and booking. */
export async function loadInvoice(id) {
    const { data, error } = await getSupabase().from('s4_invoices')
        .select(`*, lines:s4_invoice_lines(sort_order, description, quantity, unit_cents, line_cents, needs_review),
                 booking:s4_bookings(id, reference, starts_at, client:s4_clients(first_name, last_name, email, phone_e164))`)
        .eq('id', id)
        .single();
    if (error) throw new Error(adminError(error));
    data.lines.sort((a, z) => a.sort_order - z.sort_order);
    return data;
}

/** The single row of business details printed on invoices. */
export async function loadBusiness() {
    const { data, error } = await getSupabase().from('s4_business').select('*').maybeSingle();
    if (error) throw new Error(adminError(error));
    return data;
}

export const businessReady = (b) => !!(b?.trading_name?.trim() && b?.gst_number);
