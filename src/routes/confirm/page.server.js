// @ts-nocheck
import { API_URL } from "$lib/data/api.svelte";
/** @type {import('./types').PageServerLoad} */

export const load = async ({ url }) => {
    const getAppointment = async () => {
        const response = await fetch(`${API_URL}?id=${url.searchParams.get('id')}`);
        const jsonResponse = await response.json();
        return jsonResponse;
    };

    return {
        getAppointment
    };
}