<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { adminError } from '$lib/admin';

    const sb = getSupabase();
    let categories = $state([]);
    let rows = $state([]);
    let loading = $state(true);
    let error = $state('');
    let savingId = $state(null);
    let savedId = $state(null);
    let rowError = $state({});

    async function load() {
        loading = true;
        const [c, s] = await Promise.all([
            sb.from('s4_categories').select('id, name').order('sort_order'),
            sb.from('s4_services')
                .select('id, category_id, name, price_cents, gold_card_price_cents, duration_min, price_is_from, is_addon, is_active')
                .order('category_id').order('sort_order')
        ]);
        loading = false;
        if (c.error || s.error) { error = adminError(c.error || s.error); return; }
        categories = c.data;
        // Edit in dollars; store in cents.
        rows = s.data.map(r => ({
            ...r,
            price: r.price_cents / 100,
            gold: r.gold_card_price_cents == null ? '' : r.gold_card_price_cents / 100
        }));
    }
    onMount(load);

    async function save(r) {
        rowError = { ...rowError, [r.id]: '' };
        const price = Number(r.price);
        const gold = r.gold === '' || r.gold == null ? null : Number(r.gold);
        if (!(price >= 0)) { rowError = { ...rowError, [r.id]: 'Enter a price.' }; return; }
        if (gold != null && !(gold >= 0 && gold < price)) {
            rowError = { ...rowError, [r.id]: 'Gold Card price must be lower than the standard price.' };
            return;
        }
        if (!(Number(r.duration_min) > 0)) { rowError = { ...rowError, [r.id]: 'Enter a duration in minutes.' }; return; }
        savingId = r.id;
        const { error: e } = await sb.from('s4_services').update({
            name: r.name.trim(),
            price_cents: Math.round(price * 100),
            gold_card_price_cents: gold == null ? null : Math.round(gold * 100),
            duration_min: Number(r.duration_min),
            price_is_from: r.price_is_from,
            is_active: r.is_active
        }).eq('id', r.id);
        savingId = null;
        if (e) { rowError = { ...rowError, [r.id]: adminError(e) }; return; }
        savedId = r.id;
        setTimeout(() => { if (savedId === r.id) savedId = null; }, 2500);
    }
</script>

<h1>Services & prices</h1>
<p class="muted intro">
    Changes apply to new online bookings straight away. The prices on the home page update on the next site deploy.
    Existing bookings keep the price they were booked at.
</p>

{#if loading}
    <p class="muted" role="status">Loading…</p>
{:else if error}
    <p class="error">{error}</p>
{:else}
    {#each categories as c (c.id)}
        <section class="panel group">
            <h2>{c.name}</h2>
            {#each rows.filter(r => r.category_id === c.id) as r (r.id)}
                <form class="svc" class:off={!r.is_active} onsubmit={(e) => { e.preventDefault(); save(r); }}>
                    <label class="name">Service <input bind:value={r.name} required /></label>
                    <label>Price ($) <input type="number" min="0" step="0.5" bind:value={r.price} required /></label>
                    <label>Gold Card ($) <input type="number" min="0" step="0.5" bind:value={r.gold} placeholder="—" /></label>
                    <label>Minutes <input type="number" min="5" step="5" bind:value={r.duration_min} required /></label>
                    <label class="check"><input type="checkbox" bind:checked={r.price_is_from} /> "from" price</label>
                    <label class="check"><input type="checkbox" bind:checked={r.is_active} /> Bookable</label>
                    <div class="save">
                        <button type="submit" class="secondary" disabled={savingId === r.id}>{savingId === r.id ? 'Saving…' : 'Save'}</button>
                        {#if savedId === r.id}<span class="ok" role="status">Saved</span>{/if}
                    </div>
                    {#if rowError[r.id]}<p class="error row-error" role="alert">{rowError[r.id]}</p>{/if}
                </form>
            {/each}
        </section>
    {/each}
{/if}

<style>
    .intro {
        margin: 0.5rem 0 1.5rem;
        max-width: 48rem;
    }
    .group {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        margin-bottom: 1.25rem;
    }
    .group h2 {
        margin-bottom: 0.5rem;
    }
    .svc {
        align-items: end;
        border-top: 1px solid var(--light);
        display: grid;
        gap: 0.5rem 0.75rem;
        grid-template-columns: minmax(12rem, 1fr) 6.5rem 6.5rem 5.5rem auto auto auto;
        padding: 0.75rem 0;
    }
    .svc.off .name input {
        color: var(--dark);
        text-decoration: line-through;
    }
    @media (max-width: 56rem) {
        .svc {
            grid-template-columns: 1fr 1fr 1fr;
        }
        .svc .name {
            grid-column: 1 / -1;
        }
    }
    label {
        color: var(--dark);
        display: flex;
        flex-direction: column;
        font-size: 0.8125rem;
        font-weight: 600;
        gap: 0.25rem;
    }
    label input {
        font-size: 1rem;
        width: 100%;
    }
    .check {
        align-items: center;
        color: var(--darkest);
        flex-direction: row;
        font-size: 0.875rem;
        gap: 0.375rem;
        min-height: 2.75rem;
        white-space: nowrap;
    }
    .save {
        align-items: center;
        display: flex;
        gap: 0.5rem;
    }
    .row-error {
        grid-column: 1 / -1;
    }
</style>
