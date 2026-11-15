import { loadCatalogue } from '$lib/data/services';

// Prerendered at build time. When John changes a price in Supabase, a
// database webhook triggers a Vercel deploy hook so this page is rebuilt.
export async function load() {
    return { catalogue: await loadCatalogue() };
}
