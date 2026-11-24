<script>
    import { onMount } from 'svelte';
    import { page } from '$app/state';
    import { getSupabase } from '$lib/supabase';
    import { adminError, dollars } from '$lib/admin';
    import { formatDuration } from '$lib/data/services';
    import Modal from '$lib/components/admin/modal.svelte';
    import Switch from '$lib/components/admin/switch.svelte';

    const sb = getSupabase();
    let categories = $state([]);
    let rows = $state([]);
    let loading = $state(true);
    let error = $state('');
    let busyId = $state(null);
    let rowError = $state({});
    let showRemoved = $state(false);
    let status = $state(null);      // { kind: 'ok' | 'error', text }

    // Toolbar
    let search = $state('');
    let filter = $state('all');     // 'all' or a category id (string)

    // Add/Edit modal
    let slotStep = $state(30);
    let formOpen = $state(false);
    let form = $state(blankForm());
    let formError = $state('');
    let saving = $state(false);

    // Remove confirmation
    let confirmOpen = $state(false);
    let toRemove = $state(null);

    function blankForm(categoryId = null) {
        return { id: null, category_id: categoryId, name: '', price: '', gold: '', duration_min: 30,
                 has_wait: false, wait_after_min: '', wait_min: '',
                 price_is_from: false, is_addon: false, is_active: true };
    }

    const toRow = (r) => ({
        ...r,
        price: r.price_cents / 100,
        gold: r.gold_card_price_cents == null ? '' : r.gold_card_price_cents / 100
    });

    async function load() {
        loading = true;
        const [c, s, st] = await Promise.all([
            sb.from('s4_categories').select('id, name, is_active, deleted_at').order('sort_order').order('id'),
            sb.from('s4_services')
                .select('id, category_id, name, price_cents, gold_card_price_cents, duration_min, price_is_from, is_addon, is_active, deleted_at, sort_order, wait_after_min, wait_min')
                .order('sort_order').order('id'),
            sb.from('s4_settings').select('slot_step_min').single()
        ]);
        if (st.data) slotStep = st.data.slot_step_min;
        loading = false;
        if (c.error || s.error) { error = adminError(c.error || s.error); return; }
        categories = c.data;
        rows = s.data.map(toRow);
    }
    onMount(() => {
        // Arriving from the Categories page: /admin/services?category=3
        const fromLink = page.url.searchParams.get('category');
        if (fromLink) filter = fromLink;
        load();
    });

    let liveCategories = $derived(categories.filter(c => !c.deleted_at));
    let removedCategories = $derived(categories.filter(c => c.deleted_at));
    let removedServices = $derived(rows.filter(r => r.deleted_at));
    const categoryName = (id) => categories.find(c => c.id === id)?.name ?? 'Unknown';

    // Groups shown in the table, after search + category filter.
    let term = $derived(search.trim().toLowerCase());
    const matches = (r) => !term || r.name.toLowerCase().includes(term);
    let groups = $derived(
        [...liveCategories.map(c => ({ c, removedCategory: false })), ...removedCategories.map(c => ({ c, removedCategory: true }))]
            .filter(g => filter === 'all' || String(g.c.id) === filter)
            .map(g => ({ ...g, services: rows.filter(r => r.category_id === g.c.id && !r.deleted_at && matches(r)) }))
            .filter(g => !g.removedCategory || g.services.length)
            .filter(g => !term || g.services.length)
    );
    let shownCount = $derived(groups.reduce((n, g) => n + g.services.length, 0));

    function announce(kind, text) {
        status = { kind, text };
        if (kind === 'ok') setTimeout(() => { if (status?.text === text) status = null; }, 3000);
    }

    /** Shared validation for edits and new services. Returns the DB fields, or an error string. */
    function toFields(r) {
        const price = Number(r.price);
        const gold = r.gold === '' || r.gold == null ? null : Number(r.gold);
        if (!String(r.name).trim()) return 'Give the service a name.';
        if (!r.category_id) return 'Choose a category.';
        if (r.price === '' || !(price >= 0)) return 'Enter a price.';
        if (gold != null && !(gold >= 0 && gold < price)) return 'Gold Card price must be lower than the standard price.';
        if (!(Number(r.duration_min) > 0)) return 'Enter a duration in minutes.';
        const after = Number(r.wait_after_min), wait = Number(r.wait_min);
        if (r.has_wait) {
            if (!(Number.isInteger(after) && after > 0 && Number.isInteger(wait) && wait > 0)) return 'Enter the hands-on and waiting minutes.';
            if (after + wait >= Number(r.duration_min)) return 'Hands-on and waiting time must leave some finishing time within the total minutes.';
        }
        return {
            name: String(r.name).trim(),
            category_id: Number(r.category_id),
            price_cents: Math.round(price * 100),
            gold_card_price_cents: gold == null ? null : Math.round(gold * 100),
            duration_min: Number(r.duration_min),
            price_is_from: r.price_is_from,
            is_addon: r.is_addon,
            wait_after_min: r.has_wait ? after : null,
            wait_min: r.has_wait ? wait : null,
            is_active: r.is_active
        };
    }

    // How the visit splits up, and whether anything could be booked in the wait.
    let split = $derived.by(() => {
        const after = Number(form.wait_after_min), wait = Number(form.wait_min), finish = Number(form.duration_min) - after - wait;
        if (!form.has_wait || !(after > 0 && wait > 0 && finish > 0)) return null;
        const firstStart = Math.ceil(after / slotStep) * slotStep;
        const bookable = rows.filter(r => !r.deleted_at && r.is_active && !r.is_addon && r.id !== form.id).map(r => r.duration_min);
        const fits = bookable.length > 0 && firstStart + Math.min(...bookable) <= after + wait;
        return { after, wait, finish, fits };
    });

    // ─── Add / Edit ─────────────────────────────────────────────────────
    function openAdd(categoryId = null) {
        const preset = categoryId ?? (filter !== 'all' ? Number(filter) : liveCategories[0]?.id ?? null);
        form = blankForm(preset);
        formError = '';
        formOpen = true;
    }
    function openEdit(r) {
        form = { id: r.id, category_id: r.category_id, name: r.name, price: r.price, gold: r.gold, duration_min: r.duration_min,
                 has_wait: r.wait_min != null, wait_after_min: r.wait_after_min ?? '', wait_min: r.wait_min ?? '',
                 price_is_from: r.price_is_from, is_addon: r.is_addon, is_active: r.is_active };
        formError = '';
        formOpen = true;
    }

    async function submitForm(e) {
        e.preventDefault();
        formError = '';
        const fields = toFields(form);
        if (typeof fields === 'string') { formError = fields; return; }
        saving = true;
        let err;
        if (form.id) {
            ({ error: err } = await sb.from('s4_services').update(fields).eq('id', form.id));
        } else {
            const inCategory = rows.filter(r => r.category_id === fields.category_id);
            const last = Math.max(0, ...inCategory.map(r => r.sort_order ?? 0));
            ({ error: err } = await sb.from('s4_services').insert({ ...fields, sort_order: last + 1 }));
        }
        saving = false;
        if (err) { formError = adminError(err); return; }
        formOpen = false;
        announce('ok', form.id ? `Saved "${fields.name}".` : `Added "${fields.name}" to ${categoryName(fields.category_id)}.`);
        load();
    }

    // ─── Quick actions in the table ─────────────────────────────────────
    async function toggleActive(r, value) {
        busyId = r.id;
        rowError = { ...rowError, [r.id]: '' };
        const { error: err } = await sb.from('s4_services').update({ is_active: value }).eq('id', r.id);
        busyId = null;
        if (err) {
            r.is_active = !value;   // put the switch back
            rowError = { ...rowError, [r.id]: adminError(err) };
        }
    }

    function askRemove(r) {
        toRemove = r;
        confirmOpen = true;
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
        confirmOpen = false;
        if (err) { announce('error', adminError(err)); return; }
        announce('ok', kept ? `Removed "${r.name}" from the menu. Kept for existing bookings.` : `Deleted "${r.name}".`);
        load();
    }

    async function restore(r) {
        busyId = r.id;
        const { error: err } = await sb.from('s4_services').update({ deleted_at: null }).eq('id', r.id);
        busyId = null;
        if (err) { announce('error', adminError(err)); return; }
        announce('ok', `Restored "${r.name}". Turn on Bookable to offer it again.`);
        load();
    }
</script>

<div class="page-head">
    <div>
        <h1>Services & prices</h1>
        <p>New and changed prices apply to online bookings straight away; the home page updates on the next site deploy. Existing bookings keep the price they were booked at.</p>
    </div>
    <button type="button" class="primary with-icon" onclick={() => openAdd()}>
        <i class="ph ph-plus" aria-hidden="true"></i> Add service
    </button>
</div>

<div class="toolbar">
    <label class="search">
        <i class="ph ph-magnifying-glass" aria-hidden="true"></i>
        <span class="sr-only">Search services</span>
        <input type="search" placeholder="Search services" bind:value={search} />
    </label>
    <label class="filter">
        <span class="sr-only">Category</span>
        <select bind:value={filter}>
            <option value="all">All categories</option>
            {#each liveCategories as c (c.id)}<option value={String(c.id)}>{c.name}</option>{/each}
        </select>
    </label>
    {#if !loading}<span class="muted count" role="status">{shownCount} {shownCount === 1 ? 'service' : 'services'}</span>{/if}
</div>

{#if status}
    <p class="status-line {status.kind}" role={status.kind === 'error' ? 'alert' : 'status'}>
        <i class="ph ph-{status.kind === 'ok' ? 'check-circle' : 'warning-circle'}" aria-hidden="true"></i>{status.text}
    </p>
{/if}

{#if loading && !rows.length}
    <p class="muted" role="status">Loading…</p>
{:else if error}
    <p class="error">{error}</p>
{:else if !groups.length}
    <div class="panel"><p class="muted">{term ? 'No services match your search.' : 'No services yet. Add one to get started.'}</p></div>
{:else}
    <table class="admin-table">
        <caption class="sr-only">Services and prices, grouped by category</caption>
        <thead>
            <tr>
                <th scope="col">Service</th>
                <th scope="col" class="num">Price</th>
                <th scope="col" class="num">Gold Card</th>
                <th scope="col" class="num">Duration</th>
                <th scope="col">Bookable</th>
                <th scope="col" class="actions-cell"><span class="sr-only">Actions</span></th>
            </tr>
        </thead>
        {#each groups as g (g.c.id)}
            <tbody class:muted-group={g.removedCategory}>
                <tr class="group-row">
                    <th scope="colgroup" colspan="6">
                        <span class="group-head">
                            <span class="group-name">
                                {g.c.name}
                                {#if g.removedCategory}<span class="badge">Category removed</span>
                                {:else if !g.c.is_active}<span class="badge warn">Turned off: hidden from clients</span>{/if}
                            </span>
                            {#if !g.removedCategory}
                                <button type="button" class="secondary with-icon small" onclick={() => openAdd(g.c.id)}
                                    aria-label="Add a service to {g.c.name}">
                                    <i class="ph ph-plus" aria-hidden="true"></i> Add
                                </button>
                            {/if}
                        </span>
                    </th>
                </tr>
                {#each g.services as r (r.id)}
                    <tr class:off={!r.is_active}>
                        <td class="primary-cell">
                            <strong>{r.name}</strong>
                            <span class="badges">
                                {#if r.price_is_from}<span class="badge">"from" price</span>{/if}
                                {#if r.is_addon}<span class="badge"><i class="ph ph-plus-circle" aria-hidden="true"></i>Add-on</span>{/if}
                            </span>
                            {#if rowError[r.id]}<span class="error sub" role="alert">{rowError[r.id]}</span>{/if}
                        </td>
                        <td class="num" data-label="Price">{r.price_is_from ? 'from ' : ''}{dollars(r.price_cents)}</td>
                        <td class="num" data-label="Gold Card">{r.gold_card_price_cents == null ? '—' : dollars(r.gold_card_price_cents)}</td>
                        <td class="num" data-label="Duration">{formatDuration(r.duration_min)}{#if r.wait_min}<span class="sub">{formatDuration(r.wait_min)} waiting</span>{/if}</td>
                        <td data-label="Bookable">
                            <Switch bind:checked={r.is_active} label="{r.name} bookable" disabled={busyId === r.id}
                                onchange={(v) => toggleActive(r, v)} />
                        </td>
                        <td class="actions-cell">
                            <button type="button" class="icon-btn" aria-label="Edit {r.name}" onclick={() => openEdit(r)}>
                                <i class="ph ph-pencil-simple" aria-hidden="true"></i>
                            </button>
                            <button type="button" class="icon-btn danger-icon" aria-label="Remove {r.name}" onclick={() => askRemove(r)}>
                                <i class="ph ph-trash" aria-hidden="true"></i>
                            </button>
                        </td>
                    </tr>
                {:else}
                    <tr><td colspan="6" class="muted empty">No services yet.</td></tr>
                {/each}
            </tbody>
        {/each}
    </table>
{/if}

{#if removedServices.length}
    <section class="removed">
        <button type="button" class="toggle" aria-expanded={showRemoved} onclick={() => showRemoved = !showRemoved}>
            <i class="ph ph-caret-{showRemoved ? 'down' : 'right'}" aria-hidden="true"></i>
            Removed services ({removedServices.length})
        </button>
        {#if showRemoved}
            <table class="admin-table">
                <caption class="sr-only">Removed services</caption>
                <thead>
                    <tr>
                        <th scope="col">Service</th>
                        <th scope="col">Category</th>
                        <th scope="col" class="actions-cell"><span class="sr-only">Actions</span></th>
                    </tr>
                </thead>
                <tbody>
                    {#each removedServices as r (r.id)}
                        <tr>
                            <td class="primary-cell"><strong>{r.name}</strong><span class="sub">Kept for existing bookings</span></td>
                            <td data-label="Category">{categoryName(r.category_id)}</td>
                            <td class="actions-cell">
                                <button type="button" class="secondary with-icon" disabled={busyId === r.id} onclick={() => restore(r)}>
                                    <i class="ph ph-arrow-counter-clockwise" aria-hidden="true"></i> Restore
                                </button>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        {/if}
    </section>
{/if}

<!-- Add / Edit -->
<Modal bind:open={formOpen} title={form.id ? 'Edit service' : 'Add a service'}>
    <form id="service-form" class="modal-form" onsubmit={submitForm} novalidate>
        <label class="wide">
            Name
            <input bind:value={form.name} required placeholder="e.g. Fringe trim" autocomplete="off" />
        </label>
        <label class="wide">
            Category
            <select bind:value={form.category_id} required>
                {#each liveCategories as c (c.id)}<option value={c.id}>{c.name}</option>{/each}
            </select>
        </label>
        <label>
            Price ($)
            <input type="number" inputmode="decimal" min="0" step="0.5" bind:value={form.price} required />
        </label>
        <label>
            Gold Card ($)
            <input type="number" inputmode="decimal" min="0" step="0.5" bind:value={form.gold} placeholder="Optional" />
        </label>
        <label>
            Minutes
            <input type="number" inputmode="numeric" min="5" step="5" bind:value={form.duration_min} required />
        </label>
        <fieldset class="wide checks">
            <legend class="sr-only">Options</legend>
            <label class="check"><input type="checkbox" bind:checked={form.price_is_from} /> Price can vary (show "from")</label>
            <label class="check"><input type="checkbox" bind:checked={form.is_addon} /> Add-on (only booked with another service)</label>
        </fieldset>
        <div class="wide"><Switch bind:checked={form.has_wait} label="Has waiting time" showLabel /></div>
        {#if form.has_wait}
            <p class="wide muted">Another client can be booked while you wait, e.g. while a treatment sits.</p>
            <label>
                Hands-on first (min)
                <input type="number" inputmode="numeric" min="5" step="5" bind:value={form.wait_after_min} required />
            </label>
            <label>
                Waiting (min)
                <input type="number" inputmode="numeric" min="5" step="5" bind:value={form.wait_min} required />
            </label>
            {#if split}
                <p class="wide" role="status">{split.after} min hands-on · {split.wait} min waiting · {split.finish} min finishing</p>
                {#if !split.fits}
                    <p class="wide muted">No service fits this wait while start times are every {slotStep} minutes. Try a longer wait, or change “Start times every” in Settings.</p>
                {/if}
            {/if}
        {/if}
        <div class="wide"><Switch bind:checked={form.is_active} label="Bookable" showLabel /></div>
        {#if formError}<p class="error wide" role="alert">{formError}</p>{/if}
    </form>
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => formOpen = false}>Cancel</button>
        <button type="submit" form="service-form" class="primary" disabled={saving}>
            {saving ? 'Saving…' : form.id ? 'Save changes' : 'Add service'}
        </button>
    {/snippet}
</Modal>

<!-- Remove confirmation -->
<Modal bind:open={confirmOpen} title="Remove service?">
    {#if toRemove}
        <p><strong>{toRemove.name}</strong> will no longer be bookable. Any existing appointments for it stay in Bookings.</p>
    {/if}
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => confirmOpen = false}>Keep it</button>
        <button type="button" class="danger" disabled={busyId === toRemove?.id} onclick={() => remove(toRemove)}>Remove service</button>
    {/snippet}
</Modal>

<style>
    .toolbar {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        margin-bottom: 1rem;
    }
    .search {
        align-items: center;
        display: flex;
        flex: 1 1 16rem;
        max-width: 26rem;
        position: relative;
    }
    .search > i {
        color: var(--adm-text-muted);
        font-size: 1.125rem;
        left: 0.75rem;
        pointer-events: none;
        position: absolute;
    }
    /* Attribute selector out-ranks the shared admin input padding. */
    .search input[type="search"] {
        padding-left: 2.375rem;
        width: 100%;
    }
    .filter select {
        min-width: 12rem;
    }
    .count {
        font-size: 0.9375rem;
    }
    .group-head {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 1rem;
        justify-content: space-between;
    }
    .group-name {
        align-items: center;
        display: inline-flex;
        flex-wrap: wrap;
        gap: 0.5rem;
    }
    button.small {
        font-size: 0.875rem;
        min-height: 2.25rem;
        padding: 0 0.75rem;
    }
    .muted-group {
        opacity: 0.8;
    }
    .primary-cell strong {
        color: var(--adm-text);
        margin-right: 0.375rem;
    }
    .badges {
        display: inline-flex;
        flex-wrap: wrap;
        gap: 0.25rem;
        vertical-align: middle;
    }
    .empty {
        padding: 0.875rem 0.75rem;
    }
    .removed {
        margin-top: 2rem;
    }
    .toggle {
        align-items: center;
        color: var(--adm-text);
        cursor: pointer;
        display: inline-flex;
        font-weight: 600;
        gap: 0.375rem;
        margin-bottom: 0.75rem;
        min-height: 2.75rem;
    }
    .modal-form {
        display: grid;
        gap: 1rem;
        grid-template-columns: repeat(3, minmax(0, 1fr));
    }
    .modal-form .wide {
        grid-column: 1 / -1;
    }
    .modal-form label:not(.check) {
        color: var(--adm-text);
        display: flex;
        flex-direction: column;
        font-size: 0.9375rem;
        font-weight: 600;
        gap: 0.375rem;
    }
    .modal-form input:not([type="checkbox"]),
    .modal-form select {
        width: 100%;
    }
    .optional {
        color: var(--adm-text-muted);
        font-size: 0.8125rem;
        font-weight: 400;
    }
    .checks {
        border: 0;
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        margin: 0;
        padding: 0;
    }
    .check {
        align-items: center;
        display: flex;
        gap: 0.5rem;
        min-height: 2.75rem;
    }
    @media (max-width: 40rem) {
        .modal-form {
            grid-template-columns: 1fr 1fr;
        }
        .modal-form label:nth-of-type(5) {
            grid-column: 1 / -1;
        }
    }
</style>
