// @ts-nocheck
/** @type {import('./$types').PageLoad} */

import { API_URL } from '$lib/data/api.svelte';
import { createAdminData } from '$lib/data/admin.svelte';
// import { appointments } from '$lib/data/appointments.svelte';

const adminData = createAdminData();

export const load = async ({ url }) => {
	let id = url.searchParams.get('id');
	let apiResult = await fetch(`${API_URL}/${id}`);
	let appointment = await apiResult.json();
	console.log('page.server appointment', appointment);
    return {
		appointment
	};
}