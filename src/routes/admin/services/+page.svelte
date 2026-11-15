<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { adminError } from '$lib/admin';

    const sb = getSupabase();
    let categories = $state([]);
    let rows = $state([]);
    let loading = $state(true);
    let error = $state('');
    let busyId = $state(null);
    let rowMsg = $state({});
    let confirmId = $state(null);
    let showRemoved = $state(false);

    // One "add" form open at a time, keyed by category id.
    let addingTo = $state(null);
    let draft = $state(blankDraft());
    let draftError = $state('');
    let savingDraft = $state(false);

    function blankDraft() {
        return { name: '', price: '', gold: '', duration_min: 30, price_is_from: false, is_addon: false, is_active: true };
    }

    const toRow = (r) => ({
        ...r,
        price: r.price_cents / 100,
        gold: r.gold_card_price_cents == null ? '' : r.gold_card_price_cents / 100
    });

    async function load() {
        loading = true;
        const [c, s] = await Promise.all([
            sb.from('s4_categories').select('id, name, is_active, deleted_at').order('sort_order').order('id'),
            sb.from('s4_services')
                .select('id, category_id, name, price_cents, gold_card_price_cents, duration_min, price_is_from, is_addon, is_active, deleted_at, sort_order')
                .order('sort_order').order('id')
        ]);
        loading = false;
        if (c.error || s.error) { error = adminError(c.error || s.error); return; }
        categories = c.data;
        rows = s.data.map(toRow);
    }
    onMount(load);

    let liveCategories = $derived(categories.filter(c => !c.deleted_at));
    let removedCategories = $derived(categories.filter(c => c.deleted_at));
    let removedServices = $derived(rows.filter(r => r.deleted_at));
    const servicesIn = (categoryId) => rows.filter(r => r.category_id === categoryId && !r.deleted_at);

    const say = (id, msg) => {
        rowMsg = { ...rowMsg, [id]: msg };
        if (msg.ok) setTimeout(() => { if (rowMsg[id]?.ok === msg.ok) rowMsg = { ...rowMsg, [id]: {} }; }, 2500);
    };

    /** Shared validation for edits and new services. Returns the DB fields, or an error string. */
    function toFields(r) {
        const price = Number(r.price);
        const gold = r.gold === '' || r.gold == null ? null : Number(r.gold);
        if (!String(r.name).trim()) return 'Give the service a name.';
        if (r.price === '' || !(price >= 0)) return 'Enter a price.';
        if (gold != null && !(gold >= 0 && gold < price)) return 'Gold Card price must be lower than the standard price.';
        if (!(Number(r.duration_min) > 0)) return 'Enter a duration in minutes.';
        return {
            name: String(r.name).trim(),
            price_cents: Math.round(price * 100),
            gold_card_price_cents: gold == null ? null : Math.round(gold * 100),
            duration_min: Number(r.duration_min),
            price_is_from: r.price_is_from,
            is_addon: r.is_addon,
            is_active: r.is_active
        };
    }

    async function save(r) {
        const fields = toFields(r);
        if (typeof fields === 'string') { say(r.id, { error: fields }); return; }
        busyId = r.id;
        const { error: e } = await sb.from('s4_services')
            .update({ ...fields, category_id: Number(r.category_id) })
            .eq('id', r.id);
        busyId = null;
        say(r.id, e ? { error: adminError(e) } : { ok: 'Saved' });
        if (!e) load();
    }

    function openAdd(categoryId) {
        addingTo = categoryId;
        draft = blankDraft();
        draftError = '';
    }

    async function add(e, categoryId) {
        e.preventDefault();
        const fields = toFields(draft);
        if (typeof fields === 'string') { draftError = fields; return; }
        savingDraft = true;
        const last = Math.max(0, ...servicesIn(categoryId).map(r => r.sort_order ?? 0));
        const { error: err } = await sb.from('s4_services')
            .insert({ ...fields, category_id: categoryId, sort_order: last + 1 });
        savingDraft = false;
        if (err) { draftError = adminError(err); return; }
        addingTo = null;
        load();
    }

    // Delete outright if never booked; otherwise keep it (soft-remove) so
    // existing appointments still link to it.
    async function remove(r) {
        busyId = r.id;
        let { error: err } = await sb.from('s4_services').delete().eq('id', r.id);
        let kept = false;
        if (err?.code === '23503') {
            ({ error: err } = await sb.from('s4_services')
                .update({ deleted_at: new Date().toISOString(), is_active: false })
                .eq('id', r.id));
            kept = true;
        }
        busyId = null;
        confirmId = null;
        if (err) { say(r.id, { error: adminError(err) }); return; }
        await load();
        if (kept) say(r.id, { ok: 'Removed from the menu. Kept for existing bookings.' });
    }

    async function restore(r) {
        busyId = r.id;
        const { error: err } = await sb.from('s4_services').update({ deleted_at: null }).eq('id', r.id);
        busyId = null;
        if (err) { say(r.id, { error: adminError(err) }); return; }
        say(r.id, { ok: 'Restored. Tick "Bookable" and save to offer it again.' });
        load();
    }

    const categoryName = (id) => categories.find(c => c.id === id)?.name ?? 'Unknown';
</script>

<h1>Services & prices</h1>
<p class="muted intro">
    New and changed prices apply to online bookings straight away; the home page updates on the next site deploy.
    Existing bookings keep the price they were booked at, and removing a service never removes appointments.
</p>

{#snippet serviceRow(r)}
    <form class="svc" class:off={!r.is_active} onsubmit={(e) => { e.preventDefault(); save(r); }}>
        <label class="name">Service <input bind:value={r.name} required /></label>
        <label>Price ($) <input type="number" min="0" step="0.5" bind:value={r.price} required /></label>
        <label>Gold Card ($) <input type="number" min="0" step="0.5" bind:value={r.gold} placeholder="—" /></label>
        <label>Minutes <input type="number" min="5" step="5" bind:value={r.duration_min} required /></label>
        <label>Category
            <select bind:value={r.category_id}>
                {#each liveCategories as c (c.id)}<option value={c.id}>{c.name}</option>{/each}
            </select>
        </label>
        <div class="flags">
            <label class="check"><input type="checkbox" bind:checked={r.price_is_from} /> "from" price</label>
            <label class="check"><input type="checkbox" bind:checked={r.is_addon} /> Add-on</label>
            <label class="check"><input type="checkbox" bind:checked={r.is_active} /> Bookable</label>
        </div>
        <div class="save">
            <button type="submit" class="secondary" disabled={busyId === r.id}>{busyId === r.id ? 'Saving…' : 'Save'}</button>
            <button type="button" class="link-danger" onclick={() => confirmId = r.id}>Remove…</button>
        </div>
        {#if confirmId === r.id}
            <div class="confirm" role="alert">
                <p><strong>Remove "{r.name}"?</strong> Clients won't be able to book it. Any existing appointments for it stay in Bookings.</p>
                <div class="save">
                    <button type="button" class="danger" disabled={busyId === r.id} onclick={() => remove(r)}>Remove service</button>
                    <button type="button" class="secondary" onclick={() => confirmId = null}>Keep it</button>
                </div>
            </div>
        {/if}
        {#if rowMsg[r.id]?.ok}<p class="ok msg" role="status">{rowMsg[r.id].ok}</p>{/if}
        {#if rowMsg[r.id]?.error}<p class="error msg" role="alert">{rowMsg[r.id].error}</p>{/if}
    </form>
{/snippet}

{#if loading}
    <p class="muted" role="status">Loading…</p>
{:else if error}
    <p class="error">{error}</p>
{:else}
    {#each liveCategories as c (c.id)}
        <section class="panel group">
            <h2>
                {c.name}
                {#if !c.is_active}<span class="note">Category turned off: hidden from clients</span>{/if}
            </h2>
            {#each servicesIn(c.id) as r (r.id)}
                {@render serviceRow(r)}
            {:else}
                <p class="muted empty">No services yet.</p>
            {/each}

            {#if addingTo === c.id}
                <form class="svc new" onsubmit={(e) => add(e, c.id)}>
                    <label class="name">New service <input bind:value={draft.name} required placeholder="e.g. Fringe trim" /></label>
                    <label>Price ($) <input type="number" min="0" step="0.5" bind:value={draft.price} required /></label>
                    <label>Gold Card ($) <input type="number" min="0" step="0.5" bind:value={draft.gold} placeholder="—" /></label>
                    <label>Minutes <input type="number" min="5" step="5" bind:value={draft.duration_min} required /></label>
                    <div class="flags">
                        <label class="check"><input type="checkbox" bind:checked={draft.price_is_from} /> "from" price</label>
                        <label class="check"><input type="checkbox" bind:checked={draft.is_addon} /> Add-on</label>
                        <label class="check"><input type="checkbox" bind:checked={draft.is_active} /> Bookable</label>
                    </div>
                    <div class="save">
                        <button type="submit" class="primary" disabled={savingDraft}>{savingDraft ? 'Adding…' : 'Add service'}</button>
                        <button type="button" class="secondary" onclick={() => addingTo = null}>Cancel</button>
                    </div>
                    {#if draftError}<p class="error msg" role="alert">{draftError}</p>{/if}
                </form>
            {:else}
                <div class="add-row">
                    <button type="button" class="secondary" onclick={() => openAdd(c.id)}>
                        <i class="ph ph-plus" aria-hidden="true"></i> Add a service to {c.name}
                    </button>
                </div>
            {/if}
        </section>
    {/each}

    {#each removedCategories as c (c.id)}
        {#if servicesIn(c.id).length}
            <section class="panel group muted-group">
                <h2>{c.name} <span class="note">Category removed: these services aren't bookable</span></h2>
                {#each servicesIn(c.id) as r (r.id)}
                    {@render serviceRow(r)}
                {/each}
            </section>
        {/if}
    {/each}

    {#if removedServices.length}
        <section class="removed">
            <button type="button" class="toggle" aria-expanded={showRemoved} onclick={() => showRemoved = !showRemoved}>
                <i class="ph ph-caret-{showRemoved ? 'down' : 'right'}" aria-hidden="true"></i>
                Removed services ({removedServices.length})
            </button>
            {#if showRemoved}
                <ul class="removed-list">
                    {#each removedServices as r (r.id)}
                        <li class="panel">
                            <span><strong>{r.name}</strong> <span class="muted">· {categoryName(r.category_id)} · kept for existing bookings</span></span>
                            <button type="button" class="secondary" disabled={busyId === r.id} onclick={() => restore(r)}>Restore</button>
                            {#if rowMsg[r.id]?.ok}<p class="ok msg" role="status">{rowMsg[r.id].ok}</p>{/if}
                            {#if rowMsg[r.id]?.error}<p class="error msg" role="alert">{rowMsg[r.id].error}</p>{/if}
                        </li>
                    {/each}
                </ul>
            {/if}
        </section>
    {/if}
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
        align-items: baseline;
        display: flex;
        flex-wrap: wrap;
        gap: 0.25rem 0.75rem;
        margin-bottom: 0.5rem;
    }
    .note {
        color: var(--color-accent-800);
        font-size: 0.8125rem;
        font-weight: 600;
    }
    .muted-group {
        opacity: 0.85;
    }
    .empty {
        padding: 0.5rem 0;
    }
    .svc {
        align-items: end;
        border-top: 1px solid var(--light);
        display: grid;
        gap: 0.5rem 0.75rem;
        grid-template-columns: minmax(11rem, 1fr) 6rem 6rem 5rem 10rem;
        padding: 0.875rem 0;
    }
    .svc.new {
        background-color: var(--color-accent-50);
        border: 1px solid var(--color-accent-300);
        border-radius: 0.375rem;
        margin-top: 0.5rem;
        padding: 0.875rem;
    }
    .svc.off .name input {
        color: var(--dark);
    }
    .flags,
    .save,
    .msg,
    .confirm {
        grid-column: 1 / -1;
    }
    .flags {
        display: flex;
        flex-wrap: wrap;
        gap: 0 1.25rem;
    }
    .save {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
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
    label input:not([type="checkbox"]),
    label select {
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
    .link-danger {
        color: var(--error);
        cursor: pointer;
        font-weight: 600;
        min-height: 2.75rem;
        padding: 0 0.5rem;
        text-decoration: underline;
        text-underline-offset: 3px;
    }
    .confirm {
        background-color: var(--error-bg);
        border: 1px solid var(--error);
        border-radius: 0.25rem;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        line-height: 1.5;
        padding: 0.875rem 1rem;
    }
    .add-row {
        padding-top: 0.75rem;
    }
    .add-row button {
        align-items: center;
        display: inline-flex;
        gap: 0.375rem;
    }
    .removed {
        margin-top: 2rem;
    }
    .toggle {
        align-items: center;
        color: var(--darkest);
        cursor: pointer;
        display: inline-flex;
        font-weight: 600;
        gap: 0.375rem;
        margin-bottom: 0.75rem;
        min-height: 2.75rem;
    }
    .removed-list {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .removed-list li {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 1rem;
        justify-content: space-between;
    }
</style>
