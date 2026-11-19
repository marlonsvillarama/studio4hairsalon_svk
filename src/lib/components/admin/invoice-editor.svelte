<script>
    /**
     * Tax invoice modal. A draft is editable (lines, quantities, prices) and
     * can be issued; an issued invoice is read-only and can be printed or
     * voided. Totals preview live; the database recalculates them on save.
     */
    import { getSupabase } from '$lib/supabase';
    import Modal from './modal.svelte';
    import { showDay } from '$lib/admin';
    import {
        invoiceNumber, money, gstOf, showGst, showIssueDate, invoiceError,
        loadInvoice, loadBusiness, businessReady, INVOICE_STATUS
    } from '$lib/invoices';

    let { open = $bindable(false), invoiceId = null, onchanged } = $props();

    const sb = getSupabase();
    let inv = $state(null);
    let business = $state(null);
    let lines = $state([]);          // [{ key, description, quantity, price (dollars text), needs_review }]
    let loadError = $state('');
    let error = $state('');
    let busy = $state(false);
    let mode = $state('');           // '' | confirm-issue | void
    let voidReason = $state('');
    let dirty = $state(false);
    let keySeq = 0;

    const toPrice = (cents) => (cents / 100).toFixed(2);
    const toCents = (text) => {
        const n = Number(String(text).replace(/[$,\s]/g, ''));
        return Number.isFinite(n) ? Math.round(n * 100) : NaN;
    };

    async function load(id) {
        inv = null;
        loadError = '';
        error = '';
        mode = '';
        voidReason = '';
        dirty = false;
        try {
            const [i, b] = await Promise.all([loadInvoice(id), loadBusiness()]);
            inv = i;
            business = b;
            lines = i.lines.map(l => ({
                key: ++keySeq, description: l.description, quantity: l.quantity,
                price: toPrice(l.unit_cents), needs_review: l.needs_review
            }));
        } catch (e) {
            loadError = e.message;
        }
    }

    $effect(() => {
        if (open && invoiceId) load(invoiceId);
    });

    const editable = $derived(inv?.status === 'draft');
    const lineCents = (l) => {
        const c = toCents(l.price);
        return Number.isNaN(c) ? 0 : c * (Number(l.quantity) || 0);
    };
    const total = $derived(editable ? lines.reduce((s, l) => s + lineCents(l), 0) : inv?.total_cents ?? 0);
    const gst = $derived(editable ? gstOf(total) : inv?.gst_cents ?? 0);
    const reviewCount = $derived(lines.filter(l => l.needs_review).length);
    const clientName = $derived(inv
        ? (inv.status === 'draft'
            ? `${inv.booking?.client?.first_name ?? ''} ${inv.booking?.client?.last_name ?? ''}`.trim()
            : inv.client_name)
        : '');
    const title = $derived(inv ? `Tax invoice · ${invoiceNumber(inv.number)}` : 'Tax invoice');

    function edit() { dirty = true; error = ''; }
    function addLine() {
        lines.push({ key: ++keySeq, description: '', quantity: 1, price: '0.00', needs_review: false });
        edit();
    }
    function removeLine(key) {
        lines = lines.filter(l => l.key !== key);
        edit();
    }

    function validate() {
        if (!lines.length) return 'Add at least one line.';
        for (const [i, l] of lines.entries()) {
            if (!l.description.trim()) return `Line ${i + 1}: add a description.`;
            const q = Number(l.quantity);
            if (!Number.isInteger(q) || q < 1 || q > 99) return `Line ${i + 1}: quantity must be a whole number from 1 to 99.`;
            if (Number.isNaN(toCents(l.price))) return `Line ${i + 1}: enter a price, e.g. 85.00.`;
        }
        if (total < 0) return "The total can't be below $0.";
        return '';
    }

    async function save() {
        const problem = validate();
        if (problem) { error = problem; return false; }
        busy = true;
        const { error: e } = await sb.rpc('s4_invoice_save', {
            p_invoice_id: inv.id,
            p_lines: lines.map(l => ({
                description: l.description.trim(),
                quantity: Number(l.quantity),
                unit_cents: toCents(l.price),
                // Once John has looked at a "from" price and saved, it's settled.
                needs_review: false
            }))
        });
        busy = false;
        if (e) { error = invoiceError(e); return false; }
        dirty = false;
        lines.forEach(l => l.needs_review = false);
        onchanged?.();
        return true;
    }

    async function issue() {
        if (!(await save())) { mode = ''; return; }
        busy = true;
        const { error: e } = await sb.rpc('s4_invoice_issue', { p_invoice_id: inv.id });
        busy = false;
        if (e) { error = invoiceError(e); mode = ''; return; }
        await load(inv.id);
        onchanged?.();
    }

    async function voidInvoice(e) {
        e?.preventDefault();
        if (!voidReason.trim()) { error = 'Give a reason for voiding this invoice.'; return; }
        busy = true;
        const { error: err } = await sb.rpc('s4_invoice_void', { p_invoice_id: inv.id, p_reason: voidReason.trim() });
        busy = false;
        if (err) { error = invoiceError(err); return; }
        await load(inv.id);
        onchanged?.();
    }

    async function discardDraft() {
        busy = true;
        const { error: e } = await sb.rpc('s4_invoice_void', { p_invoice_id: inv.id, p_reason: 'Draft discarded' });
        busy = false;
        if (e) { error = invoiceError(e); return; }
        open = false;
        onchanged?.();
    }

    const printInvoice = () => window.open(`/admin/invoices/${inv.id}?print=1`, '_blank', 'noopener');
</script>

<Modal bind:open {title}>
    {#if loadError}
        <p class="error" role="alert">{loadError}</p>
    {:else if !inv}
        <p class="muted" role="status">Loading…</p>
    {:else}
        <div class="meta">
            <span class="badge s-{inv.status}">{INVOICE_STATUS[inv.status]}</span>
            <span><strong>{clientName || 'Client'}</strong></span>
            {#if inv.booking}<span class="muted">Visit {showDay(inv.booking.starts_at)} · {inv.booking.reference}</span>{/if}
            {#if inv.issue_date}<span class="muted">Issued {showIssueDate(inv.issue_date)}</span>{/if}
        </div>

        {#if editable && !businessReady(business)}
            <p class="status-line error"><i class="ph ph-warning-circle" aria-hidden="true"></i>
                <span>Add your business name and GST number in <a href="/admin/settings">Settings</a> before issuing.</span></p>
        {/if}
        {#if editable && reviewCount}
            <p class="status-line note"><i class="ph ph-info" aria-hidden="true"></i>
                <span>{reviewCount === 1 ? 'One service was' : `${reviewCount} services were`} booked at a “from” price. Check the final amount.</span></p>
        {/if}
        {#if inv.status === 'void'}
            <p class="status-line error"><i class="ph ph-prohibit" aria-hidden="true"></i>
                <span>Voided: {inv.void_reason}</span></p>
        {/if}

        {#if editable}
            <div class="lines" role="group" aria-label="Invoice lines">
                <div class="line head" aria-hidden="true">
                    <span>Description</span><span>Qty</span><span>Price (incl. GST)</span><span></span>
                </div>
                {#each lines as l, i (l.key)}
                    <div class="line" class:review={l.needs_review}>
                        <label><span class="sr-only">Line {i + 1} description</span>
                            <input bind:value={l.description} oninput={edit} maxlength="200" /></label>
                        <label><span class="sr-only">Line {i + 1} quantity</span>
                            <input type="number" min="1" max="99" step="1" bind:value={l.quantity} oninput={edit} /></label>
                        <label class="price"><span class="sr-only">Line {i + 1} price including GST, in dollars</span>
                            <span class="prefix" aria-hidden="true">$</span>
                            <input inputmode="decimal" bind:value={l.price} oninput={edit} /></label>
                        <button type="button" class="icon-btn danger-icon" aria-label="Remove line {i + 1}"
                            onclick={() => removeLine(l.key)}>
                            <i class="ph ph-trash" aria-hidden="true"></i>
                        </button>
                    </div>
                {/each}
                <button type="button" class="secondary with-icon add" onclick={addLine}>
                    <i class="ph ph-plus" aria-hidden="true"></i> Add line
                </button>
            </div>
        {:else}
            <table class="admin-table read">
                <caption class="sr-only">Invoice lines</caption>
                <thead><tr><th scope="col">Description</th><th scope="col" class="num">Qty</th><th scope="col" class="num">Amount</th></tr></thead>
                <tbody>
                    {#each inv.lines as l}
                        <tr><td class="primary-cell">{l.description}</td><td class="num" data-label="Qty">{l.quantity}</td><td class="num" data-label="Amount">{money(l.line_cents)}</td></tr>
                    {/each}
                </tbody>
            </table>
        {/if}

        <dl class="totals">
            <div><dt>Total (incl. GST)</dt><dd>{money(total)}</dd></div>
            <div class="sub"><dt>Includes GST (15%)</dt><dd>{money(gst)}</dd></div>
            {#if !editable && inv.supplier_gst}<div class="sub"><dt>GST number</dt><dd>{showGst(inv.supplier_gst)}</dd></div>{/if}
        </dl>

        {#if mode === 'confirm-issue'}
            <div class="confirm" role="alert">
                <p><strong>Issue invoice for {money(total)}?</strong> It gets the next invoice number and can't be edited afterwards.</p>
            </div>
        {:else if mode === 'void'}
            <form class="confirm" id="void-form" onsubmit={voidInvoice}>
                <label>Reason for voiding
                    <input bind:value={voidReason} required maxlength="300" placeholder="e.g. wrong price, re-issued" /></label>
                <p class="muted">The invoice keeps its number and is marked void. You can then make a new invoice for this booking.</p>
            </form>
        {/if}

        {#if error}<p class="error" role="alert">{error}</p>{/if}
    {/if}

    {#snippet footer()}
        {#if inv && editable}
            {#if mode === 'confirm-issue'}
                <button type="button" class="secondary" onclick={() => mode = ''}>Back</button>
                <button type="button" class="primary" disabled={busy} onclick={issue}>{busy ? 'Issuing…' : 'Issue invoice'}</button>
            {:else}
                <button type="button" class="danger" disabled={busy} onclick={discardDraft}>Discard</button>
                <button type="button" class="secondary" disabled={busy || !dirty} onclick={save}>{busy ? 'Saving…' : dirty ? 'Save draft' : 'Saved'}</button>
                <button type="button" class="primary" disabled={busy || !businessReady(business)}
                    onclick={() => { const p = validate(); if (p) { error = p; return; } mode = 'confirm-issue'; }}>Issue invoice…</button>
            {/if}
        {:else if inv && inv.status === 'issued'}
            {#if mode === 'void'}
                <button type="button" class="secondary" onclick={() => { mode = ''; error = ''; }}>Back</button>
                <button type="submit" form="void-form" class="danger" disabled={busy}>{busy ? 'Voiding…' : 'Void invoice'}</button>
            {:else}
                <button type="button" class="danger" onclick={() => mode = 'void'}>Void…</button>
                <button type="button" class="primary with-icon" onclick={printInvoice}>
                    <i class="ph ph-printer" aria-hidden="true"></i> Print / Save PDF
                </button>
            {/if}
        {:else if inv}
            <button type="button" class="secondary with-icon" onclick={printInvoice}>
                <i class="ph ph-printer" aria-hidden="true"></i> Print
            </button>
            <button type="button" class="secondary" onclick={() => open = false}>Close</button>
        {/if}
    {/snippet}
</Modal>

<style>
    .meta {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.375rem 0.75rem;
        margin-bottom: 1rem;
    }
    .meta strong {
        color: var(--adm-text);
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
    .status-line.note {
        background-color: var(--adm-selected-bg);
        color: var(--adm-text);
    }
    .status-line a {
        color: inherit;
        font-weight: 600;
        text-decoration: underline;
    }

    .lines {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .line {
        align-items: center;
        display: grid;
        gap: 0.5rem;
        grid-template-columns: minmax(0, 1fr) 4rem 7.5rem 2.75rem;
    }
    .line.head {
        color: var(--adm-text-muted);
        font-size: 0.8125rem;
        font-weight: 600;
    }
    .line.review input {
        border-color: var(--adm-accent-border);
    }
    .line input {
        width: 100%;
    }
    .line label {
        display: flex;
        min-width: 0;
    }
    .price {
        align-items: center;
        position: relative;
    }
    .prefix {
        color: var(--adm-text-muted);
        left: 0.625rem;
        pointer-events: none;
        position: absolute;
    }
    .price input {
        font-variant-numeric: tabular-nums;
        padding-left: 1.375rem;
        text-align: right;
    }
    .add {
        align-self: flex-start;
    }

    .read {
        margin: 0;
    }

    .totals {
        border-top: 1px solid var(--adm-border);
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        margin-top: 1rem;
        padding-top: 0.75rem;
    }
    .totals div {
        display: flex;
        justify-content: space-between;
        gap: 1rem;
    }
    .totals dt {
        color: var(--adm-text);
        font-weight: 600;
    }
    .totals dd {
        color: var(--adm-text);
        font-size: 1.125rem;
        font-variant-numeric: tabular-nums;
        font-weight: 700;
    }
    .totals .sub dt,
    .totals .sub dd {
        color: var(--adm-text-muted);
        font-size: 0.9375rem;
        font-weight: 500;
    }

    .confirm {
        background-color: var(--adm-sunken);
        border-radius: 0.375rem;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        margin-top: 1rem;
        padding: 0.875rem 1rem;
    }
    .confirm label {
        color: var(--adm-text);
        display: flex;
        flex-direction: column;
        font-weight: 600;
        gap: 0.375rem;
    }
    .error {
        margin-top: 0.75rem;
    }

    @media (max-width: 40rem) {
        .line {
            grid-template-columns: 4rem minmax(0, 1fr) 2.75rem;
        }
        .line > label:first-child {
            grid-column: 1 / -1;
        }
        .line.head {
            display: none;
        }
    }
</style>
