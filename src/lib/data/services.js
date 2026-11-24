import { getSupabase } from "$lib/supabase";

// The catalogue lives in Supabase (s4_categories, s4_services). Prices are
// stored in cents and mapped to dollars here, so components keep working
// with the same shape: { id, category, name, price, goldCardPrice, duration, range, addon }.

export class CatalogueError extends Error {}

const toService = (s) => ({
    id: s.id,
    category: s.category_id,
    name: s.name,
    price: s.price_cents / 100,
    goldCardPrice: s.gold_card_price_cents == null ? null : s.gold_card_price_cents / 100,
    duration: s.duration_min,
    // Partway through, John is free: { after, length } minutes, or null.
    wait: s.wait_min ? { after: s.wait_after_min, length: s.wait_min } : null,
    range: s.price_is_from,
    addon: s.is_addon
});

/** Active categories and services, in display order. */
export async function loadCatalogue() {
    const sb = getSupabase();
    const [categories, services] = await Promise.all([
        sb.from('s4_categories').select('id, slug, name, description').eq('is_active', true).is('deleted_at', null).order('sort_order').order('id'),
        sb.from('s4_services')
            // All columns: the site keeps working (without waiting time) on a
            // database that hasn't had the waiting-time migration yet.
            .select('*')
            .eq('is_active', true)
            .is('deleted_at', null)
            .order('category_id')
            .order('sort_order')
            .order('id')
    ]);
    if (categories.error || services.error) {
        throw new CatalogueError((categories.error || services.error).message);
    }
    // Only services whose category is itself offered (a signed-in staff
    // session can read hidden rows through RLS; customers never see them).
    const offered = new Set(categories.data.map(c => c.id));
    return {
        categories: categories.data,
        services: services.data.filter(s => offered.has(s.category_id)).map(toService)
    };
}

const nzd = new Intl.NumberFormat('en-NZ', {
    style: 'currency',
    currency: 'NZD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
});

/** "$35", or "from $130" for services whose price varies. */
export const formatPrice = (price, range = false) =>
    `${range ? 'from ' : ''}${nzd.format(price)}`;

/** 45 → "45 min", 90 → "1 hr 30 min", 120 → "2 hr" */
export const formatDuration = (minutes = 0) => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    if (!hours) return `${mins} min`;
    return mins ? `${hours} hr ${mins} min` : `${hours} hr`;
};

/**
 * What a client pays for a service. Gold Card holders pay `goldCardPrice`
 * on the services that have one; everyone else pays `price`.
 */
export const priceFor = (service, goldCard = false) =>
    goldCard && service.goldCardPrice != null ? service.goldCardPrice : service.price;

/** Lowest standard (non add-on) price in a category. */
export const startingPrice = (services, categoryId) => Math.min(
    ...services
        .filter(s => s.category === categoryId && !s.addon)
        .map(s => s.price)
);

/** Services in a category that have a Gold Card price. */
export const goldCardServices = (services, categoryId) =>
    services.filter(s => s.category === categoryId && s.goldCardPrice != null);
