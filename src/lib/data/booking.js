import { getSupabase, errorCode } from "$lib/supabase";
import { salonInstant } from "./availability";

// Bookings are created by the s4_create_booking database function. It prices
// the visit, checks the slot and saves everything in one transaction, so the
// browser never decides what something costs or whether a time is free.

export class BookingError extends Error {
    constructor(code, message) {
        super(message);
        this.code = code;
    }
}

const MESSAGES = {
    slot_taken: 'Someone has just booked that time.',
    too_soon: "That time is too soon to book online.",
    too_far: "That date is further ahead than I take online bookings.",
    outside_hours: "That time is outside opening hours.",
    invalid_services: "One of those services isn't available any more.",
    invalid_phone: "That mobile number doesn't look right.",
    invalid_details: 'Please add your first name.',
    phone_in_use: 'That mobile number is already linked to another account.',
    contact_required: 'Add a mobile number or an email so I can reach you.',
    booking_disabled: "Online booking is paused at the moment."
};

/**
 * @param {{ services: number[], date: string, time: string, timezone: string, goldCard: boolean,
 *           client: { firstName: string, lastName: string, phone: string, email: string, notes: string } }} booking
 * @returns {Promise<{ reference: string, startsAt: string, endsAt: string, total: number, variablePrice: boolean }>}
 */
export async function submitBooking(booking) {
    const { data, error } = await getSupabase().rpc('s4_create_booking', {
        p_service_ids: booking.services,
        p_starts_at: salonInstant(booking.date, booking.time, booking.timezone).toISOString(),
        p_gold_card: booking.goldCard,
        p_first_name: booking.client.firstName,
        p_last_name: booking.client.lastName,
        p_phone: booking.client.phone,
        p_email: booking.client.email,
        p_notes: booking.client.notes
    });

    if (error) {
        const code = errorCode(error);
        throw new BookingError(code, MESSAGES[code] || "Your booking couldn't be saved. Please check your connection.");
    }
    return {
        reference: data.reference,
        startsAt: data.starts_at,
        endsAt: data.ends_at,
        total: data.total_cents / 100,
        variablePrice: data.has_variable_price
    };
}
