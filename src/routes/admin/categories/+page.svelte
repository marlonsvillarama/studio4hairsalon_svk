<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { adminError, slugify, removedSlug, restoredSlug } from '$lib/admin';

    const sb = getSupabase();
    let categories = $state([]);
    let loading = $state(true);
    let loadError = $state('');
    let rowMsg = $state({});        // { [id]: { ok?: string, error?: string } }
    let busyId = $state(null);
    let confirmId = $state(null);
    let showRemoved = $state(false);

    // New category form
    let newName = $state('');
    let newDescription = $state('');
    let newActive = $state(true);
    let adding = $state(false);
    let addError = $state('');
    let addOk = $state('');

    async function load() {
        loading = true;
        const { data, error } = await sb.from('s4_categories')
            .select('id, slug, name, description, sort_order, is_active, deleted_at, services:s4_services(id, deleted_at)')
            .order('sort_order').order('id');
        loading = false;
        if (error) { loadError = adminError(error); return; }
        categories = data.map(c => ({
            ...c,
            description: c.description ?? '',
            serviceCount: c.services.filter(s => !s.deleted_at).length,
            anyServices: c.services.length > 0
        }));
    }
    onMount(load);

    let current = $derived(categories.filter(c => !c.deleted_at));
    let removed = $derived(categories.filter(c => c.deleted_at));

    const say = (id, msg) => {
        rowMsg = { ...rowMsg, [id]: msg };
        if (msg.ok) setTimeout(() => { if (rowMsg[id]?.ok === msg.ok) rowMsg = { ...rowMsg, [id]: {} }; }, 2500);
    };

    async function save(c) {
        if (!c.name.trim()) { say(c.id, { error: 'A category needs a name.' }); return; }
        busyId = c.id;
        const { error } = await sb.from('s4_categories').update({
            name: c.name.trim(),
            slug: slugify(c.name),
            description: c.description.trim() || null,
            is_active: c.is_active
        }).eq('id', c.id);
        busyId = null;
        say(c.id, error ? { error: adminError(error) } : { ok: 'Saved' });
    }

    // Swap display order with the neighbour above/below.
    async function move(c, dir) {
        const list = current;
        const i = list.indexOf(c);
        const other = list[i + dir];
        if (!other) return;
        busyId = c.id;
        const a = c.sort_order, b = other.sort_order === a ? a + dir : other.sort_order;
        const r1 = await sb.from('s4_categories').update({ sort_order: b }).eq('id', c.id);
        const r2 = await sb.from('s4_categories').update({ sort_order: a }).eq('id', other.id);
        busyId = null;
        if (r1.error || r2.error) { say(c.id, { error: adminError(r1.error || r2.error) }); return; }
        await load();
    }

    async function add(e) {
        e.preventDefault();
        addError = '';
        addOk = '';
        if (!newName.trim()) { addError = 'Give the category a name.'; return; }
        adding = true;
        const last = Math.max(0, ...categories.map(c => c.sort_order ?? 0));
        const { error } = await sb.from('s4_categories').insert({
            name: newName.trim(),
            slug: slugify(newName),
            description: newDescription.trim() || null,
            is_active: newActive,
            sort_order: last + 1
        });
        adding = false;
        if (error) { addError = adminError(error); return; }
        addOk = `Added "${newName.trim()}". Add its services on the Services page.`;
        newName = '';
        newDescription = '';
        newActive = true;
        load();
    }

    // Delete outright when it never had services; otherwise soft-remove so
    // existing appointments keep their link.
    async function remove(c) {
        busyId = c.id;
        let error;
        if (!c.anyServices) {
            ({ error } = await sb.from('s4_categories').delete().eq('id', c.id));
        }
        if (c.anyServices || error?.code === '23503') {
            ({ error } = await sb.from('s4_categories')
                .update({ deleted_at: new Date().toISOString(), slug: removedSlug(c.slug, c.id) })
                .eq('id', c.id));
        }
        busyId = null;
        confirmId = null;
        if (error) { say(c.id, { error: adminError(error) }); return; }
        load();
    }

    async function restore(c) {
        busyId = c.id;
        const { error } = await sb.from('s4_categories')
            .update({ deleted_at: null, slug: restoredSlug(c.slug) })
            .eq('id', c.id);
        busyId = null;
        if (error) { say(c.id, { error: adminError(error) }); return; }
        load();
    }
</script>

<h1>Categories</h1>
<p class="muted intro">
    The tabs clients choose from when booking. Turning a category off hides it and all its services from clients;
    existing appointments are never affected.
</p>

{#if loading}
    <p class="muted" role="status">Loading…</p>
{:else if loadError}
    <p class="error">{loadError}</p>
{:else}
    <ul class="list">
        {#each current as c, i (c.id)}
            <li class="panel" class:off={!c.is_active}>
                <form class="row" onsubmit={(e) => { e.preventDefault(); save(c); }}>
                    <div class="order">
                        <button type="button" class="icon" aria-label="Move {c.name} up" disabled={i === 0 || busyId === c.id} onclick={() => move(c, -1)}>
                            <i class="ph ph-arrow-up" aria-hidden="true"></i>
                        </button>
                        <button type="button" class="icon" aria-label="Move {c.name} down" disabled={i === current.length - 1 || busyId === c.id} onclick={() => move(c, 1)}>
                            <i class="ph ph-arrow-down" aria-hidden="true"></i>
                        </button>
                    </div>
                    <label class="name">Name <input bind:value={c.name} required /></label>
                    <label class="desc">Short description (optional) <input bind:value={c.description} placeholder="Shown on the home page card" /></label>
                    <label class="check"><input type="checkbox" bind:checked={c.is_active} /> Bookable</label>
                    <div class="actions">
                        <button type="submit" class="secondary" disabled={busyId === c.id}>Save</button>
                        <button type="button" class="danger" onclick={() => confirmId = c.id}>Remove…</button>
                    </div>
                </form>
                <p class="meta muted">
                    {c.serviceCount} {c.serviceCount === 1 ? 'service' : 'services'}{#if !c.is_active} · hidden from clients{/if}
                </p>
                {#if confirmId === c.id}
                    <div class="confirm" role="alert">
                        {#if c.anyServices}
                            <p><strong>Remove "{c.name}"?</strong> Its {c.serviceCount} {c.serviceCount === 1 ? 'service' : 'services'} will stop being bookable. Past and upcoming appointments are kept, and you can restore it later.</p>
                        {:else}
                            <p><strong>Delete "{c.name}"?</strong> It has no services, so it will be deleted completely.</p>
                        {/if}
                        <div class="actions">
                            <button type="button" class="danger" disabled={busyId === c.id} onclick={() => remove(c)}>{c.anyServices ? 'Remove category' : 'Delete category'}</button>
                            <button type="button" class="secondary" onclick={() => confirmId = null}>Keep it</button>
                        </div>
                    </div>
                {/if}
                {#if rowMsg[c.id]?.ok}<p class="ok" role="status">{rowMsg[c.id].ok}</p>{/if}
                {#if rowMsg[c.id]?.error}<p class="error" role="alert">{rowMsg[c.id].error}</p>{/if}
            </li>
        {/each}
    </ul>

    <form class="panel add" onsubmit={add}>
        <h2>Add a category</h2>
        <label>Name <input bind:value={newName} required placeholder="e.g. Waxing" /></label>
        <label>Short description (optional) <input bind:value={newDescription} placeholder="e.g. Brows, lip and chin" /></label>
        <label class="check"><input type="checkbox" bind:checked={newActive} /> Bookable straight away</label>
        <div><button type="submit" class="primary" disabled={adding}>{adding ? 'Adding…' : 'Add category'}</button></div>
        {#if addOk}<p class="ok" role="status">{addOk}</p>{/if}
        {#if addError}<p class="error" role="alert">{addError}</p>{/if}
    </form>

    {#if removed.length}
        <section class="removed">
            <button type="button" class="toggle" aria-expanded={showRemoved} onclick={() => showRemoved = !showRemoved}>
                <i class="ph ph-caret-{showRemoved ? 'down' : 'right'}" aria-hidden="true"></i>
                Removed categories ({removed.length})
            </button>
            {#if showRemoved}
                <ul class="list">
                    {#each removed as c (c.id)}
                        <li class="panel removed-row">
                            <span><strong>{c.name}</strong> <span class="muted">· {c.serviceCount} {c.serviceCount === 1 ? 'service' : 'services'}, kept for existing bookings</span></span>
                            <button type="button" class="secondary" disabled={busyId === c.id} onclick={() => restore(c)}>Restore</button>
                            {#if rowMsg[c.id]?.error}<p class="error" role="alert">{rowMsg[c.id].error}</p>{/if}
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
    .list {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        margin-bottom: 1.5rem;
    }
    .off .name input {
        color: var(--dark);
    }
    .row {
        align-items: end;
        display: grid;
        gap: 0.5rem 0.75rem;
        grid-template-columns: auto minmax(10rem, 1fr) minmax(12rem, 1.5fr) auto auto;
    }
    @media (max-width: 52rem) {
        .row {
            grid-template-columns: auto 1fr;
        }
        .row .desc,
        .row .check,
        .row .actions {
            grid-column: 2;
        }
    }
    .order {
        display: flex;
        flex-direction: column;
        gap: 0.125rem;
    }
    .icon {
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        cursor: pointer;
        display: grid;
        height: 1.75rem;
        place-items: center;
        width: 2.25rem;
    }
    .icon:disabled {
        cursor: default;
        opacity: 0.35;
    }
    label {
        color: var(--dark);
        display: flex;
        flex-direction: column;
        font-size: 0.8125rem;
        font-weight: 600;
        gap: 0.25rem;
    }
    label input:not([type="checkbox"]) {
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
    .actions {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
    }
    .meta {
        font-size: 0.875rem;
        margin-top: 0.5rem;
    }
    .confirm {
        background-color: var(--error-bg);
        border: 1px solid var(--error);
        border-radius: 0.25rem;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        line-height: 1.5;
        margin-top: 0.75rem;
        padding: 0.875rem 1rem;
    }
    .add {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        max-width: 36rem;
    }
    .add label {
        font-size: 0.9375rem;
        color: var(--darkest);
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
    .removed-row {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 1rem;
        justify-content: space-between;
    }
</style>
