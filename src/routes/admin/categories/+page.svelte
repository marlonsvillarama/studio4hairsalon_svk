<script>
    import { untrack } from 'svelte';
    import { page } from '$app/state';
    import { goto } from '$app/navigation';
    import { getSupabase } from '$lib/supabase';
    import { adminError, slugify, removedSlug, restoredSlug, pageRange, urlPage, urlSize, savePageSize } from '$lib/admin';
    import Pager from '$lib/components/admin/pager.svelte';
    import Skeleton from '$lib/components/admin/skeleton.svelte';
    import Modal from '$lib/components/admin/modal.svelte';
    import Switch from '$lib/components/admin/switch.svelte';

    const sb = getSupabase();
    const TABLE = 'categories';
    let current = $state([]);           // this page of categories in use
    let currentTotal = $state(0);
    let removed = $state([]);           // this page of removed ones
    let removedTotal = $state(0);
    let removedPage = $state(1);
    let busy = $state(false);
    let loading = $state(true);
    let loadError = $state('');
    let rowError = $state({});      // { [id]: message } for quick actions in the table
    let busyId = $state(null);
    let showRemoved = $state(false);
    let status = $state(null);      // { kind: 'ok' | 'error', text }

    // Add/Edit modal
    let formOpen = $state(false);
    let form = $state(blankForm());
    let formError = $state('');
    let saving = $state(false);

    // Remove confirmation modal
    let confirmOpen = $state(false);
    let toRemove = $state(null);

    function blankForm() {
        return { id: null, name: '', description: '', is_active: true };
    }

    // Page and size of the main table live in the URL (?page=2&size=10).
    let pageNo = $derived(urlPage(page.url));
    let size = $derived(urlSize(page.url, TABLE));
    function setParams(changes) {
        const params = new URLSearchParams(page.url.searchParams);
        for (const [k, v] of Object.entries(changes)) {
            if (v == null || (k === 'page' && v === 1)) params.delete(k); else params.set(k, String(v));
        }
        const qs = params.toString();
        goto(qs ? `?${qs}` : page.url.pathname, { replaceState: true, keepFocus: true, noScroll: true });
    }
    const goPage = (n) => setParams({ page: n });
    function setSize(n) {
        savePageSize(TABLE, n);
        removedPage = 1;
        setParams({ size: n, page: Math.floor(((pageNo - 1) * size) / n) + 1 });
    }

    const COLS = 'id, slug, name, description, sort_order, is_active, deleted_at, services:s4_services(id, deleted_at)';
    const shape = (c) => ({
        ...c,
        description: c.description ?? '',
        serviceCount: c.services.filter(s => !s.deleted_at).length,
        anyServices: c.services.length > 0
    });
    let seq = 0;
    async function load() {
        const mine = ++seq;
        busy = true;
        const [from, to] = pageRange(pageNo, size);
        const [rf, rt] = pageRange(removedPage, size);
        const [cur, rem] = await Promise.all([
            sb.from('s4_categories').select(COLS, { count: 'exact' }).is('deleted_at', null)
                .order('sort_order').order('id').range(from, to),
            sb.from('s4_categories').select(COLS, { count: 'exact' }).not('deleted_at', 'is', null)
                .order('name').order('id').range(rf, rt)
        ]);
        if (mine !== seq) return;
        loading = busy = false;
        const error = (cur.error?.code === 'PGRST103' ? null : cur.error) || (rem.error?.code === 'PGRST103' ? null : rem.error);
        if (error) { loadError = adminError(error); return; }
        if (cur.error && pageNo > 1) { goPage(1); return; }
        if (rem.error && removedPage > 1) { removedPage = 1; load(); return; }
        loadError = '';
        current = cur.data.map(shape);
        currentTotal = cur.count ?? 0;
        removed = rem.data.map(shape);
        removedTotal = rem.count ?? 0;
    }
    $effect(() => { pageNo; size; untrack(load); });
    const goRemovedPage = (n) => { removedPage = n; load(); };

    function announce(kind, text) {
        status = { kind, text };
        if (kind === 'ok') setTimeout(() => { if (status?.text === text) status = null; }, 3000);
    }

    // ─── Add / Edit ─────────────────────────────────────────────────────
    function openAdd() {
        form = blankForm();
        formError = '';
        formOpen = true;
    }
    function openEdit(c) {
        form = { id: c.id, name: c.name, description: c.description, is_active: c.is_active };
        formError = '';
        formOpen = true;
    }

    async function submitForm(e) {
        e.preventDefault();
        formError = '';
        const name = form.name.trim();
        if (!name) { formError = 'Give the category a name.'; return; }
        saving = true;
        const fields = { name, slug: slugify(name), description: form.description.trim() || null, is_active: form.is_active };
        let error;
        if (form.id) {
            ({ error } = await sb.from('s4_categories').update(fields).eq('id', form.id));
        } else {
            // Add at the end: after the highest position in the database, not just this page.
            const { data: top } = await sb.from('s4_categories').select('sort_order').order('sort_order', { ascending: false }).limit(1);
            const last = top?.[0]?.sort_order ?? 0;
            ({ error } = await sb.from('s4_categories').insert({ ...fields, sort_order: last + 1 }));
        }
        saving = false;
        if (error) { formError = adminError(error); return; }
        formOpen = false;
        announce('ok', form.id ? `Saved "${name}".` : `Added "${name}". Add its services on the Services page.`);
        load();
    }

    // ─── Quick actions in the table ─────────────────────────────────────
    async function toggleActive(c, value) {
        busyId = c.id;
        rowError = { ...rowError, [c.id]: '' };
        const { error } = await sb.from('s4_categories').update({ is_active: value }).eq('id', c.id);
        busyId = null;
        if (error) {
            c.is_active = !value;   // put the switch back
            rowError = { ...rowError, [c.id]: adminError(error) };
        }
    }

    // Swap display order with the neighbour above/below. The neighbour comes
    // from the database, so a move works across page boundaries too.
    async function move(c, dir) {
        busyId = c.id;
        const a = c.sort_order;
        const near = dir < 0
            ? `sort_order.lt.${a},and(sort_order.eq.${a},id.lt.${c.id})`
            : `sort_order.gt.${a},and(sort_order.eq.${a},id.gt.${c.id})`;
        const { data: found, error: e0 } = await sb.from('s4_categories').select('id, sort_order')
            .is('deleted_at', null).or(near)
            .order('sort_order', { ascending: dir > 0 }).order('id', { ascending: dir > 0 }).limit(1);
        const other = found?.[0];
        if (e0 || !other) { busyId = null; if (e0) rowError = { ...rowError, [c.id]: adminError(e0) }; return; }
        const b = other.sort_order === a ? a + dir : other.sort_order;
        const r1 = await sb.from('s4_categories').update({ sort_order: b }).eq('id', c.id);
        const r2 = await sb.from('s4_categories').update({ sort_order: a }).eq('id', other.id);
        busyId = null;
        if (r1.error || r2.error) { rowError = { ...rowError, [c.id]: adminError(r1.error || r2.error) }; return; }
        // Follow the category if it moved onto the next or previous page.
        const index = (pageNo - 1) * size + current.findIndex(x => x.id === c.id) + dir;
        const target = Math.floor(index / size) + 1;
        if (target !== pageNo) goPage(target); else await load();
    }

    function askRemove(c) {
        toRemove = c;
        confirmOpen = true;
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
        confirmOpen = false;
        if (error) { announce('error', adminError(error)); return; }
        announce('ok', c.anyServices ? `Removed "${c.name}". It can be restored below.` : `Deleted "${c.name}".`);
        load();
    }

    async function restore(c) {
        busyId = c.id;
        const { error } = await sb.from('s4_categories')
            .update({ deleted_at: null, slug: restoredSlug(c.slug) })
            .eq('id', c.id);
        busyId = null;
        if (error) { announce('error', adminError(error)); return; }
        announce('ok', `Restored "${c.name}".`);
        load();
    }
</script>

<div class="page-head capped">
    <div>
        <h1>Categories</h1>
    </div>
    <button type="button" class="primary with-icon" onclick={openAdd}>
        <i class="ph ph-plus" aria-hidden="true"></i> Add category
    </button>
</div>

{#if status}
    <p class="status-line {status.kind}" role={status.kind === 'error' ? 'alert' : 'status'}>
        <i class="ph ph-{status.kind === 'ok' ? 'check-circle' : 'warning-circle'}" aria-hidden="true"></i>{status.text}
    </p>
{/if}

{#if loading && !current.length}
    <div class="capped"><Skeleton rows={6} columns={3} label="Loading categories…" /></div>
{:else if loadError}
    <p class="error">{loadError}</p>
{:else}
    <div class="capped">
    <table class="admin-table" class:busy aria-busy={busy}>
        <caption class="sr-only">Categories, in the order clients see them</caption>
        <thead>
            <tr>
                <th scope="col" class="order-col">Order</th>
                <th scope="col">Category</th>
                <th scope="col">Bookable</th>
                <th scope="col" class="actions-cell"><span class="sr-only">Actions</span></th>
            </tr>
        </thead>
        <tbody>
            {#each current as c, i (c.id)}
                <tr class:off={!c.is_active}>
                    <td class="lead-cell order">
                        <button type="button" class="icon-btn" aria-label="Move {c.name} up" title="Move up"
                            disabled={(pageNo === 1 && i === 0) || busyId === c.id} onclick={() => move(c, -1)}>
                            <i class="ph ph-caret-up" aria-hidden="true"></i>
                        </button>
                        <button type="button" class="icon-btn" aria-label="Move {c.name} down" title="Move down"
                            disabled={(pageNo - 1) * size + i === currentTotal - 1 || busyId === c.id} onclick={() => move(c, 1)}>
                            <i class="ph ph-caret-down" aria-hidden="true"></i>
                        </button>
                    </td>
                    <td class="primary-cell">
                        <strong>{c.name}</strong>
                        <span class="dot-sep" aria-hidden="true">·</span>
                        <a class="count-link" href="/admin/services?category={c.id}">{c.serviceCount} {c.serviceCount === 1 ? 'service' : 'services'}<span class="sr-only"> in {c.name}</span></a>
                        {#if !c.is_active}<span class="badge warn">Off</span>{/if}
                        {#if c.description}<span class="sub">{c.description}</span>{/if}
                        {#if rowError[c.id]}<span class="error sub" role="alert">{rowError[c.id]}</span>{/if}
                    </td>
                    <td data-label="Bookable">
                        <Switch bind:checked={c.is_active} label="{c.name} bookable" disabled={busyId === c.id}
                            onchange={(v) => toggleActive(c, v)} />
                    </td>
                    <td class="actions-cell">
                        <button type="button" class="icon-btn" aria-label="Edit {c.name}" title="Edit" onclick={() => openEdit(c)}>
                            <i class="ph ph-pencil-simple" aria-hidden="true"></i>
                        </button>
                        <button type="button" class="icon-btn danger-icon" aria-label="Remove {c.name}" title="Remove" onclick={() => askRemove(c)}>
                            <i class="ph ph-trash" aria-hidden="true"></i>
                        </button>
                    </td>
                </tr>
            {:else}
                <tr><td colspan="4" class="muted">No categories yet. Add one to get started.</td></tr>
            {/each}
        </tbody>
    </table>
    <Pager page={pageNo} {size} total={currentTotal} label="categories" onpage={goPage} onsize={setSize} />
    </div>

    {#if removedTotal}
        <section class="removed">
            <button type="button" class="toggle" aria-expanded={showRemoved} onclick={() => showRemoved = !showRemoved}>
                <i class="ph ph-caret-{showRemoved ? 'down' : 'right'}" aria-hidden="true"></i>
                Removed categories ({removedTotal})
            </button>
            {#if showRemoved}
                <table class="admin-table">
                    <caption class="sr-only">Removed categories</caption>
                    <thead>
                        <tr>
                            <th scope="col">Category</th>
                            <th scope="col" class="actions-cell"><span class="sr-only">Actions</span></th>
                        </tr>
                    </thead>
                    <tbody>
                        {#each removed as c (c.id)}
                            <tr>
                                <td class="primary-cell"><strong>{c.name}</strong> <span class="muted">· {c.serviceCount} {c.serviceCount === 1 ? 'service' : 'services'}</span><span class="sub">Kept for existing bookings</span></td>
                                <td class="actions-cell">
                                    <button type="button" class="secondary with-icon" disabled={busyId === c.id} onclick={() => restore(c)}>
                                        <i class="ph ph-arrow-counter-clockwise" aria-hidden="true"></i> Restore
                                    </button>
                                </td>
                            </tr>
                        {/each}
                    </tbody>
                </table>
                {#if removedTotal > size}
                    <Pager page={removedPage} {size} total={removedTotal} label="removed categories" onpage={goRemovedPage} onsize={setSize} />
                {/if}
            {/if}
        </section>
    {/if}
{/if}

<!-- Add / Edit -->
<Modal bind:open={formOpen} title={form.id ? 'Edit category' : 'Add a category'}>
    <form id="category-form" class="modal-form" onsubmit={submitForm} novalidate>
        <label>
            Name
            <input bind:value={form.name} required placeholder="e.g. Waxing" autocomplete="off" />
        </label>
        <label>
            <span>Short description <span class="optional">(optional)</span></span>
            <input bind:value={form.description} placeholder="Shown on the home page card" autocomplete="off" />
        </label>
        <Switch bind:checked={form.is_active} label="Bookable" showLabel />
        {#if formError}<p class="error" role="alert">{formError}</p>{/if}
    </form>
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => formOpen = false}>Cancel</button>
        <button type="submit" form="category-form" class="primary" disabled={saving}>
            {saving ? 'Saving…' : form.id ? 'Save changes' : 'Add category'}
        </button>
    {/snippet}
</Modal>

<!-- Remove confirmation -->
<Modal bind:open={confirmOpen} title={toRemove?.anyServices ? 'Remove category?' : 'Delete category?'}>
    {#if toRemove}
        {#if toRemove.anyServices}
            <p><strong>{toRemove.name}</strong> and its {toRemove.serviceCount} {toRemove.serviceCount === 1 ? 'service' : 'services'} will stop being bookable. Past and upcoming appointments are kept, and you can restore it later.</p>
        {:else}
            <p><strong>{toRemove.name}</strong> has no services, so it will be deleted completely.</p>
        {/if}
    {/if}
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => confirmOpen = false}>Keep it</button>
        <button type="button" class="danger" disabled={busyId === toRemove?.id} onclick={() => remove(toRemove)}>
            {toRemove?.anyServices ? 'Remove category' : 'Delete category'}
        </button>
    {/snippet}
</Modal>

<style>
    table.busy {
        opacity: 0.6;
        transition: opacity 150ms ease;
    }
    .order-col {
        width: 1%;
    }
    .order {
        white-space: nowrap;
    }
    .order .icon-btn {
        font-size: 1rem;
    }
    .primary-cell strong {
        color: var(--adm-text);
        margin-right: 0.375rem;
    }
    .count-link {
        color: var(--adm-text-muted);
        display: inline-block;
        font-weight: 500;
        margin-right: 0.375rem;
        padding-block: 0.6875rem;
        text-decoration: underline;
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    .removed {
        margin-top: 2rem;
        max-width: 56rem;
    }
    .capped {
        max-width: 56rem;
    }
    .dot-sep {
        color: var(--adm-text-muted);
        margin-right: 0.25rem;
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
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    .modal-form label {
        color: var(--adm-text);
        display: flex;
        flex-direction: column;
        font-weight: 600;
        gap: 0.375rem;
    }
    .optional {
        color: var(--adm-text-muted);
        font-weight: 400;
    }
    @media (max-width: 55.99rem) {
        .order {
            display: flex;
            gap: 0.125rem;
        }
    }
</style>
