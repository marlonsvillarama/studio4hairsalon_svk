<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { adminError, showShortDay } from '$lib/admin';
    import { invoiceNumber, money, showIssueDate, loadBusiness, businessReady, INVOICE_STATUS } from '$lib/invoices';
    import InvoiceEditor from '$lib/components/admin/invoice-editor.svelte';

    const sb = getSupabase();
    let invoices = $state([]);
    let business = $state(null);
    let loading = $state(true);
    let loadError = $state('');
    let filter = $state('all');
    let search = $state('');

    let editorOpen = $state(false);
    let editingId = $state(null);

    const FILTERS = [['all', 'All'], ['draft', 'Drafts'], ['issued', 'Issued'], ['void', 'Void']];

    async function load() {
        const { data, error } = await sb.from('s4_invoices')
            .select('id, number, status, issue_date, client_name, total_cents, gst_cents, created_at, booking:s4_bookings(reference, starts_at, client:s4_clients(first_name, last_name))')
            .order('created_at', { ascending: false })
            .limit(500);
        loading = false;
        if (error) { loadError = adminError(error); return; }
        invoices = data;
    }
    onMount(async () => {
        load();
        try { business = await loadBusiness(); } catch { /* the banner just won't show */ }
    });

    const nameOf = (i) => i.client_name
        || `${i.booking?.client?.first_name ?? ''} ${i.booking?.client?.last_name ?? ''}`.trim()
        || 'Client';

    let shown = $derived.by(() => {
        const q = search.trim().toLowerCase();
        return invoices.filter(i =>
            (filter === 'all' || i.status === filter) &&
            (!q || nameOf(i).toLowerCase().includes(q)
                || invoiceNumber(i.number).toLowerCase().includes(q)
                || (i.booking?.reference ?? '').toLowerCase().includes(q)));
    });
    const counts = $derived(Object.fromEntries(FILTERS.map(([id]) =>
        [id, id === 'all' ? invoices.length : invoices.filter(i => i.status === id).length])));

    function openInvoice(id) {
        editingId = id;
        editorOpen = true;
    }
</script>

<div class="page-head">
    <div>
        <h1>Tax invoices</h1>
        <p>Make an invoice from a completed booking: open it in Bookings and choose “Create tax invoice”.</p>
    </div>
</div>

{#if business && !businessReady(business)}
    <p class="status-line error"><i class="ph ph-warning-circle" aria-hidden="true"></i>
        <span>Add your GST number in <a href="/admin/settings">Settings</a> before issuing invoices.</span></p>
{/if}

<div class="toolbar">
    <div class="views" role="radiogroup" aria-label="Show">
        {#each FILTERS as [id, label]}
            <button type="button" role="radio" aria-checked={filter === id} onclick={() => filter = id}>
                {label} <span class="n">{counts[id]}</span>
            </button>
        {/each}
    </div>
    <label class="search">
        <i class="ph ph-magnifying-glass" aria-hidden="true"></i>
        <span class="sr-only">Search invoices</span>
        <input type="search" placeholder="Client, invoice or booking number" bind:value={search} />
    </label>
</div>

{#if loading}
    <p class="muted" role="status">Loading…</p>
{:else if loadError}
    <p class="error">{loadError}</p>
{:else}
    <table class="admin-table">
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
            {#each shown as i (i.id)}
                <tr class:off={i.status === 'void'}>
                    <td class="primary-cell">
                        <button type="button" class="row-link" onclick={() => openInvoice(i.id)}
                            aria-label="Open {invoiceNumber(i.number)} for {nameOf(i)}">
                            <strong>{invoiceNumber(i.number)}</strong>
                        </button>
                    </td>
                    <td data-label="Date">{i.issue_date ? showIssueDate(i.issue_date) : `Visit ${showShortDay(i.booking?.starts_at)}`}</td>
                    <td data-label="Client">{nameOf(i)}</td>
                    <td class="num" data-label="Total">{money(i.total_cents)}</td>
                    <td class="num" data-label="GST">{money(i.gst_cents)}</td>
                    <td data-label="Status"><span class="badge s-{i.status}">{INVOICE_STATUS[i.status]}</span></td>
                </tr>
            {:else}
                <tr><td colspan="6" class="muted empty">
                    {invoices.length ? 'No invoices match.' : 'No invoices yet. Mark a booking completed, then create its tax invoice.'}
                </td></tr>
            {/each}
        </tbody>
    </table>
{/if}

<InvoiceEditor bind:open={editorOpen} invoiceId={editingId} onchanged={load} />

<style>
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
        min-height: 2.375rem;
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
