// @ts-nocheck
/** @type {import('./$types').PageLoad} */

import { appointments } from '$lib/data/appointments.svelte';

export const load = ({ url }) => {
	let id = url.searchParams.get('id');
    let appointment = appointments.find(d => d.id === id);
    return {
		appointment
	};
}