<script>
    import { onMount, untrack } from 'svelte';
    import { page } from '$app/state';
    import { goto } from '$app/navigation';
    import { getSupabase } from '$lib/supabase';
    import { adminError, showShortDay, pageRange, urlPage, urlSize, savePageSize, likeText } from '$lib/admin';
    import { money, showIssueDate, loadBusiness, businessReady, INVOICE_STATUS } from '$lib/invoices';
    import InvoiceEditor from '$lib/components/admin/invoice-editor.svelte';
    import Pager from '$lib/components/admin/pager.svelte';
    import Skeleton from '$lib/components/admin/skeleton.svelte';

    const sb = getSupabase();
    const TABLE = 'invoices';
    let invoices = $state([]);          // this page only
    let total = $state(0);
    let business = $state(null);
    let loading = $state(true);
    let busy = $state(false);
    let loadError = $state('');

    let editorOpen = $state(false);
    let editingId = $state(null);

    const FILTERS = [['all', 'All'], ['draft', 'Drafts'], ['issued', 'Issued'], ['void', 'Void']];

    // ─── page, size, tab and search live in the URL ─────────────────────
    let pageNo = $derived(urlPage(page.url));
    let size = $derived(urlSize(page.url, TABLE));
    let filter = $derived(FILTERS.some(([id]) => id === page.url.searchParams.get('show')) ? page.url.searchParams.get('show') : 'all');
    let q = $derived((page.url.searchParams.get('q') ?? '').trim());

    function setParams(changes) {
        const params = new URLSearchParams(page.url.searchParams);
        for (const [k, v] of Object.entries(changes)) {
            if (v == null || v === '' || (k === 'page' && v === 1) || (k === 'show' && v === 'all')) params.delete(k);
            else params.set(k, String(v));
        }
        const qs = params.toString();
        goto(qs ? `?${qs}` : page.url.pathname, { replaceState: true, keepFocus: true, noScroll: true });
    }
    const goPage = (n) => setParams({ page: n });
    function setSize(n) {
        savePageSize(TABLE, n);
        setParams({ size: n, page: Math.floor(((pageNo - 1) * size) / n) + 1 });
    }
    let search = $state(untrack(() => q));
    let searchTimer;
    function onSearch() {
        clearTimeout(searchTimer);
        searchTimer = setTimeout(() => setParams({ q: search.trim(), page: 1 }), 250);
    }

    // Search: number ("INV-0012" or "12"), client name or booking reference.
    function searched(query) {
        if (!q) return query;
        const t = likeText(q);
        const parts = [`number_text.ilike.%${t}%`, `display_name.ilike.%${t}%`, `booking_reference.ilike.%${t}%`];
        return query.or(parts.join(','));
    }

    // ─── load just this page, and the count for each tab ────────────────
    let counts = $state({ all: 0, draft: 0, issued: 0, void: 0 });
    let seq = 0;
    async function load() {
        const mine = ++seq;
        busy = true;
        const [from, to] = pageRange(pageNo, size);
        let query = searched(sb.from('s4_invoice_list')
            .select('id, number, status, issue_date, total_cents, gst_cents, created_at, number_text, display_name, booking_reference, visit_at', { count: 'exact' }));
        if (filter !== 'all') query = query.eq('status', filter);
        const countOf = (status) => {
            let c = searched(sb.from('s4_invoice_list').select('id', { count: 'exact', head: true }));
            return status === 'all' ? c : c.eq('status', status);
        };
        const [list, ...tabCounts] = await Promise.all([
            query.order('created_at', { ascending: false }).order('id').range(from, to),
            ...FILTERS.map(([id]) => countOf(id))
        ]);
        if (mine !== seq) return;
        loading = busy = false;
        if (list.error) {
            if (list.error.code === 'PGRST103' && pageNo > 1) { goPage(1); return; }
            loadError = adminError(list.error);
            return;
        }
        loadError = '';
        invoices = list.data;
        total = list.count ?? 0;
        counts = Object.fromEntries(FILTERS.map(([id], i) => [id, tabCounts[i].count ?? 0]));
        if (pageNo > Math.max(1, Math.ceil(total / size))) goPage(Math.max(1, Math.ceil(total / size)));
    }
    $effect(() => {
        pageNo; size; filter; q;
        untrack(load);
    });
    onMount(async () => {
        try { business = await loadBusiness(); } catch { /* the banner just won't show */ }
    });

    function openInvoice(id) {
        editingId = id;
        editorOpen = true;
    }
</script>

<div class="page-head">
    <div>
        <h1>Tax invoices</h1>
    </div>
</div>

{#if business && !businessReady(business)}
    <p class="status-line error"><i class="ph ph-warning-circle" aria-hidden="true"></i>
        <span>Add your GST number in <a href="/admin/settings">Settings</a> before issuing invoices.</span></p>
{/if}

<div class="toolbar">
    <div class="views" role="radiogroup" aria-label="Show">
        {#each FILTERS as [id, label]}
            <button type="button" role="radio" aria-checked={filter === id} onclick={() => setParams({ show: id, page: 1 })}>
                {label} <span class="n">{counts[id]}</span>
            </button>
        {/each}
    </div>
    <label class="search">
        <i class="ph ph-magnifying-glass" aria-hidden="true"></i>
        <span class="sr-only">Search invoices</span>
        <input type="search" placeholder="Client, invoice or booking number" bind:value={search} oninput={onSearch} />
    </label>
</div>

{#if loading}
    <Skeleton rows={8} columns={6} label="Loading invoices…" />
{:else if loadError}
    <p class="error">{loadError}</p>
{:else}
    <table class="admin-table" class:busy aria-busy={busy}>
        <caption class="sr-only">Tax invoices, newest first</caption>
        <thead>
            <tr>
                <th scope="col">Number</th>
                <th scope="col">Date</th>
                <th scope="col">Client</th>
                <th scope="col" class="num">Total</th>
                <th scope="col" class="num">GST</th>
                <th scope="col">Status</th>
            </tr>
        </thead>
        <tbody>
            {#each invoices as i (i.id)}
                <tr class:off={i.status === 'void'}>
                    <td class="primary-cell">
                        <button type="button" class="row-link" onclick={() => openInvoice(i.id)}
                            aria-label="Open {i.number_text} for {i.display_name}">
                            <strong>{i.number_text}</strong>
                        </button>
                    </td>
                    <td data-label="Date">{i.issue_date ? showIssueDate(i.issue_date) : (i.visit_at ? `Visit ${showShortDay(i.visit_at)}` : '—')}</td>
                    <td data-label="Client">{i.display_name}</td>
                    <td class="num" data-label="Total">{money(i.total_cents)}</td>
                    <td class="num" data-label="GST">{money(i.gst_cents)}</td>
                    <td data-label="Status"><span class="badge s-{i.status}">{INVOICE_STATUS[i.status]}</span></td>
                </tr>
            {:else}
                <tr><td colspan="6" class="muted empty">
                    {q || filter !== 'all' ? 'No invoices match.' : 'No invoices yet. Mark a booking completed, then create its tax invoice.'}
                </td></tr>
            {/each}
        </tbody>
    </table>
    <Pager page={pageNo} {size} {total} label="invoices" onpage={goPage} onsize={setSize} />
{/if}

<InvoiceEditor bind:open={editorOpen} invoiceId={editingId} onchanged={load} />

<style>
    table.busy {
        opacity: 0.6;
        transition: opacity 150ms ease;
    }
    .toolbar {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        margin-bottom: 1rem;
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
    .row-link {
        color: var(--adm-text);
        cursor: pointer;
        font-variant-numeric: tabular-nums;
        min-height: 2.75rem;
        text-align: left;
        text-decoration: underline;
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    .badge.s-issued {
        background-color: var(--adm-success-bg);
        border-color: var(--adm-success-border);
        color: var(--adm-success-text);
    }
    .badge.s-void {
        background-color: var(--adm-danger-bg);
        border-color: transparent;
        color: var(--adm-danger);
    }
    .empty {
        padding: 0.875rem 0.75rem;
    }
    .status-line a {
        color: inherit;
        font-weight: 600;
        text-decoration: underline;
    }
</style>
