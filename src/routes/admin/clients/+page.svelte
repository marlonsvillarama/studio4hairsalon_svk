<script>
    import { onMount, untrack } from 'svelte';
    import { page } from '$app/state';
    import { goto } from '$app/navigation';
    import { getSupabase } from '$lib/supabase';
    import { adminError, showPhone, salonDay, loadHours, pageRange, urlPage, urlSize, savePageSize, likeText } from '$lib/admin';
    import BookingCreate from '$lib/components/admin/booking-create.svelte';
    import ClientMerge from '$lib/components/admin/client-merge.svelte';
    import Pager from '$lib/components/admin/pager.svelte';
    import Skeleton from '$lib/components/admin/skeleton.svelte';

    const sb = getSupabase();
    const TABLE = 'clients';
    const SORTS = ['name-asc', 'name-desc', 'phone-asc', 'phone-desc', 'email-asc', 'email-desc'];
    let clients = $state([]);           // this page only
    let total = $state(0);
    let loading = $state(true);         // first load
    let busy = $state(false);           // later loads: keep the table, dim it
    let loadError = $state('');
    let status = $state(null);          // { kind: 'ok' | 'error', text }
    let hours = $state({});

    // ─── page, size, search and sort live in the URL (?page=2&size=50&q=ngata&sort=phone-asc) ──
    let pageNo = $derived(urlPage(page.url));
    let size = $derived(urlSize(page.url, TABLE));
    let q = $derived((page.url.searchParams.get('q') ?? '').trim());
    let sortChoice = $derived(SORTS.includes(page.url.searchParams.get('sort')) ? page.url.searchParams.get('sort') : 'name-asc');
    let sortKey = $derived(sortChoice.split('-')[0]);
    let sortDir = $derived(sortChoice.split('-')[1]);
    // Clients or Friends & family (people staff book without contact details).
    let tab = $derived(page.url.searchParams.get('show') === 'family' ? 'family' : 'clients');
    let counts = $state({ clients: 0, family: 0 });

    function setParams(changes) {
        const params = new URLSearchParams(page.url.searchParams);
        for (const [k, v] of Object.entries(changes)) {
            if (v == null || v === '' || (k === 'page' && v === 1) || (k === 'sort' && v === 'name-asc') || (k === 'show' && v === 'clients')) params.delete(k);
            else params.set(k, String(v));
        }
        const qs = params.toString();
        goto(qs ? `?${qs}` : page.url.pathname, { replaceState: true, keepFocus: true, noScroll: true });
    }
    const goPage = (n) => setParams({ page: n });
    function setSize(n) {
        savePageSize(TABLE, n);
        // Keep the first row on screen in view where possible.
        const first = (pageNo - 1) * size;
        setParams({ size: n, page: Math.floor(first / n) + 1 });
    }

    // Search: typed text goes to the URL after a short pause, back to page 1.
    let search = $state(untrack(() => q));
    let searchTimer;
    function onSearch() {
        clearTimeout(searchTimer);
        searchTimer = setTimeout(() => setParams({ q: search.trim(), page: 1 }), 250);
    }

    // ─── load just this page; the database searches, sorts and counts ────
    let seq = 0;
    async function load() {
        const mine = ++seq;
        busy = true;
        const [from, to] = pageRange(pageNo, size);
        const asc = sortDir === 'asc';
        // Every word must match a name, the email or the phone ("aroha ngata", "0221").
        const searched = (query) => {
            for (const word of q.split(/\s+/).filter(Boolean)) {
                const t = likeText(word);
                const parts = t ? [`first_name.ilike.%${t}%`, `last_name.ilike.%${t}%`, `email.ilike.%${t}%`] : [];
                const digits = word.replace(/\D/g, '');
                if (digits.length >= 3) parts.push(`phone_e164.ilike.%${digits.startsWith('0') ? digits.slice(1) : digits}%`);
                if (parts.length) query = query.or(parts.join(','));
            }
            return query;
        };
        let query = searched(sb.from('s4_clients')
            .select('id, first_name, last_name, phone_e164, email, email_verified, auth_user_id, has_gold_card, is_family, created_at, bookings:s4_bookings(count)', { count: 'exact' }))
            .eq('is_family', tab === 'family');
        const tabCount = (family) => searched(sb.from('s4_clients').select('id', { count: 'exact', head: true })).eq('is_family', family);
        const countsReq = Promise.all([tabCount(false), tabCount(true)]);
        if (sortKey === 'phone') query = query.order('phone_e164', { ascending: asc, nullsFirst: false });
        else if (sortKey === 'email') query = query.order('email', { ascending: asc, nullsFirst: false });
        else query = query.order('last_name', { ascending: asc, nullsFirst: false }).order('first_name', { ascending: asc });
        const [{ data, error, count }, [cc, fc]] = await Promise.all([query.order('id').range(from, to), countsReq]);
        if (mine !== seq) return;
        counts = { clients: cc.count ?? 0, family: fc.count ?? 0 };
        loading = busy = false;
        if (error) {
            // Past the last page (e.g. after a merge): go to the last one instead.
            if (error.code === 'PGRST103' && pageNo > 1) { goPage(1); return; }
            loadError = adminError(error);
            return;
        }
        loadError = '';
        total = count ?? 0;
        clients = data.map(c => ({ ...c, bookingCount: c.bookings?.[0]?.count ?? 0 }));
        const pages = Math.max(1, Math.ceil(total / size));
        if (pageNo > pages) goPage(pages);
    }
    $effect(() => {
        pageNo; size; q; sortKey; sortDir; tab;
        untrack(load);
    });
    onMount(() => { loadHours().then(h => hours = h).catch(() => {}); });

    const nameOf = (c) => `${c.first_name ?? ''} ${c.last_name ?? ''}`.trim() || 'Unnamed client';
    const listName = (c) => c.last_name ? `${c.last_name}, ${c.first_name}` : (c.first_name || 'Unnamed client');

    // ─── sorting (header buttons; a select on phones) ─────────────────────
    function sortBy(key) {
        setParams({ sort: sortKey === key ? `${key}-${sortDir === 'asc' ? 'desc' : 'asc'}` : `${key}-asc`, page: 1 });
    }
    const ariaSort = (key) => sortKey === key ? (sortDir === 'asc' ? 'ascending' : 'descending') : 'none';
    const sortIcon = (key) => sortKey !== key ? 'ph-caret-up-down faint' : sortDir === 'asc' ? 'ph-caret-up' : 'ph-caret-down';
    const chooseSort = (v) => setParams({ sort: v, page: 1 });

    // ─── merging (the selection survives paging and searching) ──────────
    let selected = $state([]);          // client rows
    let mergeOpen = $state(false);
    let pair = $derived(selected.length === 2 ? selected : []);
    const isPicked = (c) => selected.some(x => x.id === c.id);
    const togglePick = (c) => { selected = isPicked(c) ? selected.filter(x => x.id !== c.id) : [...selected, c]; };
    function merged({ kept, moved }) {
        selected = [];
        announce('ok', `Merged into ${nameOf(kept)} · ${moved} ${moved === 1 ? 'booking' : 'bookings'} moved.`);
        load();
    }
    function announce(kind, text) {
        status = { kind, text };
        if (kind === 'ok') setTimeout(() => { if (status?.text === text) status = null; }, 5000);
    }

    // ─── booking for a client ───────────────────────────────────────────
    let bookOpen = $state(false);
    let bookFor = $state(null);
    function book(c) {
        bookFor = c;
        bookOpen = true;
    }
    const created = (id, day) => goto(`/admin?view=day&date=${day}&open=${id}`);
    const n = new Intl.NumberFormat('en-NZ');
</script>

<svelte:head><title>Clients · Studio 4 admin</title></svelte:head>

<div class="page-head">
    <div>
        <h1>Clients</h1>
    </div>
</div>

{#if status}
    <p class="status-line {status.kind}" role={status.kind === 'error' ? 'alert' : 'status'}>
        <i class="ph ph-{status.kind === 'ok' ? 'check-circle' : 'warning-circle'}" aria-hidden="true"></i>{status.text}
    </p>
{/if}

<div class="toolbar">
    <div class="views" role="radiogroup" aria-label="Show">
        {#each [['clients', 'Clients'], ['family', 'Friends & family']] as [id, label]}
            <button type="button" role="radio" aria-checked={tab === id} onclick={() => setParams({ show: id, page: 1 })}>
                {label} <span class="n">{n.format(counts[id])}</span>
            </button>
        {/each}
    </div>
    <label class="search">
        <i class="ph ph-magnifying-glass" aria-hidden="true"></i>
        <span class="sr-only">Search clients</span>
        <input type="search" placeholder="Name, phone or email" bind:value={search} oninput={onSearch} />
    </label>
    <label class="sort-select">
        <span>Sort by</span>
        <select value={sortChoice} onchange={(e) => chooseSort(e.currentTarget.value)}>
            <option value="name-asc">Name A–Z</option>
            <option value="name-desc">Name Z–A</option>
            <option value="phone-asc">Phone</option>
            <option value="email-asc">Email</option>
            {#if !['name-asc', 'name-desc', 'phone-asc', 'email-asc'].includes(sortChoice)}<option value={sortChoice}>{sortKey === 'phone' ? 'Phone' : 'Email'} (reversed)</option>{/if}
        </select>
    </label>
    {#if selected.length}
        <div class="merge-bar" role="group" aria-label="Selected clients">
            <span><strong>{selected.length}</strong> selected<span class="picked-names">: {selected.map(nameOf).join(', ')}</span></span>
            <button type="button" class="primary with-icon" disabled={selected.length !== 2} onclick={() => mergeOpen = true}>
                <i class="ph ph-git-merge" aria-hidden="true"></i> Merge…
            </button>
            <button type="button" class="secondary" onclick={() => selected = []}>Clear</button>
            {#if selected.length > 2}<span class="muted">Select two clients to merge.</span>{/if}
        </div>
    {/if}
</div>

{#if loading}
    <Skeleton rows={8} columns={5} label="Loading clients…" />
{:else if loadError}
    <p class="error">{loadError}</p>
    <button type="button" class="secondary" onclick={load}>Try again</button>
{:else}
    <table class="admin-table clients" class:busy aria-busy={busy}>
        <caption class="sr-only">Clients, by last name</caption>
        <thead>
            <tr>
                <th scope="col" class="pick"><span class="sr-only">Select</span></th>
                {#each [['name', 'Name'], ['phone', 'Phone'], ['email', 'Email']] as [key, label]}
                    <th scope="col" aria-sort={ariaSort(key)}>
                        <button type="button" class="sort" onclick={() => sortBy(key)}>
                            {label}<i class="ph {sortIcon(key)}" aria-hidden="true"></i>
                        </button>
                    </th>
                {/each}
                <th scope="col"><span class="sr-only">Details</span></th>
                <th scope="col" class="actions-cell"><span class="sr-only">Book</span></th>
            </tr>
        </thead>
        <tbody>
            {#each clients as c (c.id)}
                <tr class:picked={isPicked(c)}>
                    <td class="pick lead-cell">
                        <label class="pick-hit"><input type="checkbox" checked={isPicked(c)} onchange={() => togglePick(c)} aria-label="Select {nameOf(c)}" /></label>
                    </td>
                    <td class="primary-cell">
                        <strong>{listName(c)}</strong>
                        {#if c.has_gold_card}<span class="badge warn">Gold Card</span>{/if}
                        {#if c.is_family && tab !== 'family'}<span class="badge">Family</span>{/if}
                        {#if c.auth_user_id}<span class="badge" title="Signs in with Google"><i class="ph ph-google-logo" aria-hidden="true"></i> Google</span>{/if}
                    </td>
                    <td data-label="Phone">{#if c.phone_e164}<a href="tel:{c.phone_e164}">{showPhone(c.phone_e164)}</a>{:else}<span class="muted">—</span>{/if}</td>
                    <td data-label="Email" class="email">{#if c.email}<a href="mailto:{c.email}">{c.email}</a>{:else}<span class="muted">—</span>{/if}</td>
                    <td class="details-cell">
                        <a href="/admin/clients/{c.id}" class="details">
                            Details<span class="sr-only"> for {nameOf(c)}</span><i class="ph ph-arrow-right" aria-hidden="true"></i>
                        </a>
                    </td>
                    <td class="actions-cell">
                        <button type="button" class="secondary with-icon book" onclick={() => book(c)} aria-label="Book an appointment for {nameOf(c)}">
                            <i class="ph ph-calendar-plus" aria-hidden="true"></i> Book
                        </button>
                    </td>
                </tr>
            {:else}
                <tr><td colspan="6" class="muted empty">{q ? 'No one matches.' : tab === 'family' ? 'No friends or family yet. Book them with New booking → Friends & family.' : 'No clients yet.'}</td></tr>
            {/each}
        </tbody>
    </table>
    <Pager page={pageNo} {size} {total} label="clients" onpage={goPage} onsize={setSize} />
{/if}

<BookingCreate bind:open={bookOpen} client={bookFor} day={salonDay(Date.now())} {hours} oncreated={created} />
<ClientMerge bind:open={mergeOpen} clients={pair} onmerged={merged} />

<style>
    table.busy {
        opacity: 0.6;
        transition: opacity 150ms ease;
    }
    .picked-names {
        color: var(--adm-text-muted);
    }
    .views {
        background-color: var(--adm-sunken);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        display: inline-flex;
        padding: 0.1875rem;
    }
    .views button {
        border-radius: 0.25rem;
        color: var(--adm-text-muted);
        cursor: pointer;
        font-weight: 600;
        min-height: 2.75rem;
        padding: 0 0.875rem;
    }
    .views button[aria-checked="true"] {
        background-color: var(--adm-inverse-bg);
        color: var(--adm-inverse-text);
    }
    .n {
        font-variant-numeric: tabular-nums;
        font-weight: 500;
        opacity: 0.75;
    }
    .toolbar {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem 1rem;
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
    .search input[type="search"] {
        padding-left: 2.375rem;
        width: 100%;
    }
    .merge-bar {
        align-items: center;
        background-color: var(--adm-selected-bg);
        border: 1px solid var(--adm-accent-border);
        border-radius: 0.375rem;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 0.75rem;
        padding: 0.25rem 0.25rem 0.25rem 0.875rem;
    }
    .pick {
        width: 2.75rem;
    }
    .pick-hit {
        align-items: center;
        cursor: pointer;
        display: inline-flex;
        height: 2.75rem;
        justify-content: center;
        margin-left: -0.75rem;
        width: 2.75rem;
    }
    .pick input {
        cursor: pointer;
        height: 1.125rem;
        width: 1.125rem;
    }
    .primary-cell strong {
        color: var(--adm-text);
        margin-right: 0.375rem;
    }
    .primary-cell .badge {
        margin-right: 0.25rem;
        vertical-align: 0.0625rem;
    }
    tr.picked > td {
        background-color: var(--adm-selected-bg);
    }
    td a {
        color: var(--adm-text);
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    .email {
        max-width: 18rem;
        overflow-wrap: anywhere;
    }
    .details {
        align-items: center;
        display: inline-flex;
        font-weight: 600;
        gap: 0.375rem;
        min-height: 2.75rem;
        white-space: nowrap;
    }
    .sort {
        align-items: center;
        color: inherit;
        cursor: pointer;
        display: inline-flex;
        font: inherit;
        gap: 0.25rem;
        letter-spacing: inherit;
        min-height: 2.75rem;
        text-transform: inherit;
    }
    /* The sort button fills the header's height instead of its padding. */
    thead th:has(.sort) {
        padding-block: 0;
    }
    .sort:hover {
        color: var(--adm-text);
    }
    .sort i {
        font-size: 0.875rem;
    }
    .sort i.faint {
        opacity: 0.45;
    }
    th[aria-sort="ascending"] .sort,
    th[aria-sort="descending"] .sort {
        color: var(--adm-text);
    }
    .sort-select {
        align-items: center;
        display: none;
        font-size: 0.9375rem;
        gap: 0.5rem;
    }
    @media (max-width: 55.99rem) {
        .sort-select {
            display: flex;
        }
        .details-cell {
            grid-column: 1 / -1;
        }
    }
    .book {
        min-height: 2.75rem;
    }
    .empty {
        padding: 0.875rem 0.75rem;
    }
</style>
