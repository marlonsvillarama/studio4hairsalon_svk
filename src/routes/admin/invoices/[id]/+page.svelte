<script>
    import { onMount, tick } from 'svelte';
    import { page } from '$app/state';
    import { showPhone } from '$lib/admin';
    import { invoiceNumber, money, showGst, showIssueDate, loadInvoice, loadBusiness } from '$lib/invoices';

    let inv = $state(null);
    let business = $state(null);
    let error = $state('');

    onMount(async () => {
        try {
            [inv, business] = await Promise.all([loadInvoice(page.params.id), loadBusiness()]);
        } catch (e) {
            error = e.message;
            return;
        }
        if (page.url.searchParams.get('print') === '1' && inv.status !== 'draft') {
            await tick();
            window.print();
        }
    });

    // Issued and void invoices print their snapshot; a draft previews today's details.
    const issued = $derived(inv && inv.status !== 'draft');
    const supplier = $derived(!inv ? null : issued
        ? { name: inv.supplier_name, legal: inv.supplier_legal, gst: inv.supplier_gst, address: inv.supplier_address,
            phone: inv.supplier_phone, email: inv.supplier_email, note: inv.note }
        : { name: business?.trading_name, legal: business?.legal_name, gst: business?.gst_number, address: business?.address,
            phone: business?.phone, email: business?.email, note: business?.invoice_note });
    const client = $derived(!inv ? null : issued
        ? { name: inv.client_name, email: inv.client_email, phone: inv.client_phone }
        : { name: `${inv.booking?.client?.first_name ?? ''} ${inv.booking?.client?.last_name ?? ''}`.trim(),
            email: inv.booking?.client?.email, phone: inv.booking?.client?.phone_e164 });
    const visitDay = $derived(inv?.booking?.starts_at
        ? new Date(inv.booking.starts_at).toLocaleDateString('en-NZ', { timeZone: 'Pacific/Auckland', day: 'numeric', month: 'long', year: 'numeric' })
        : '');
</script>

<svelte:head>
    <title>{inv ? `${invoiceNumber(inv.number)} · Tax invoice` : 'Tax invoice'} · Studio 4 admin</title>
</svelte:head>

<div class="bar no-print">
    <a href="/admin/invoices" class="secondary with-icon"><i class="ph ph-arrow-left" aria-hidden="true"></i> Tax invoices</a>
    {#if inv && inv.status !== 'draft'}
        <button type="button" class="primary with-icon" onclick={() => window.print()}>
            <i class="ph ph-printer" aria-hidden="true"></i> Print / Save PDF
        </button>
    {/if}
</div>

{#if error}
    <p class="error" role="alert">{error}</p>
{:else if !inv}
    <p class="muted" role="status">Loading…</p>
{:else}
    {#if inv.status === 'draft'}
        <p class="status-line error no-print"><i class="ph ph-info" aria-hidden="true"></i>
            This is a draft preview. Issue it from Tax invoices to get a numbered tax invoice.</p>
    {/if}

    <article class="paper" class:void={inv.status === 'void'} aria-label="Tax invoice {invoiceNumber(inv.number)}">
        {#if inv.status === 'void'}<p class="stamp" aria-label="This invoice is void">Void</p>{/if}
        {#if inv.status === 'draft'}<p class="stamp draft">Draft</p>{/if}

        <header>
            <div class="from">
                <p class="supplier">{supplier.name}</p>
                {#if supplier.legal && supplier.legal !== supplier.name}<p>{supplier.legal}</p>{/if}
                {#if supplier.address}<p class="pre">{supplier.address}</p>{/if}
                {#if supplier.phone}<p>{supplier.phone}</p>{/if}
                {#if supplier.email}<p>{supplier.email}</p>{/if}
            </div>
            <div class="doc">
                <h1>Tax Invoice</h1>
                <dl>
                    <div><dt>Invoice</dt><dd>{invoiceNumber(inv.number)}</dd></div>
                    <div><dt>Date</dt><dd>{issued ? showIssueDate(inv.issue_date) : '—'}</dd></div>
                    <div><dt>GST no.</dt><dd>{supplier.gst ? showGst(supplier.gst) : '—'}</dd></div>
                </dl>
            </div>
        </header>

        <section class="to" aria-label="Bill to">
            <p class="label">Bill to</p>
            <p class="client">{client.name || 'Client'}</p>
            {#if client.phone}<p>{showPhone(client.phone)}</p>{/if}
            {#if client.email}<p>{client.email}</p>{/if}
            {#if visitDay}<p class="muted-print">Visit on {visitDay} · Booking {inv.booking.reference}</p>{/if}
        </section>

        <table>
            <thead>
                <tr>
                    <th scope="col">Description</th>
                    <th scope="col" class="num">Qty</th>
                    <th scope="col" class="num">Unit price</th>
                    <th scope="col" class="num">Amount</th>
                </tr>
            </thead>
            <tbody>
                {#each inv.lines as l}
                    <tr>
                        <td>{l.description}</td>
                        <td class="num">{l.quantity}</td>
                        <td class="num">{money(l.unit_cents)}</td>
                        <td class="num">{money(l.line_cents)}</td>
                    </tr>
                {/each}
            </tbody>
        </table>

        <dl class="totals">
            <div class="grand"><dt>Total (incl. GST)</dt><dd>{money(inv.total_cents)}</dd></div>
            <div><dt>Includes GST at 15%</dt><dd>{money(inv.gst_cents)}</dd></div>
        </dl>

        <footer>
            <p>All amounts are in New Zealand dollars and include GST.</p>
            {#if supplier.note}<p class="pre">{supplier.note}</p>{/if}
            {#if inv.status === 'void'}<p><strong>Voided:</strong> {inv.void_reason}</p>{/if}
        </footer>
    </article>
{/if}

<style>
    .bar {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        justify-content: space-between;
        margin: 0 auto 1rem;
        max-width: 50rem;
    }
    .bar a {
        align-items: center;
        display: inline-flex;
        text-decoration: none;
    }
    .status-line {
        margin: 0 auto 1rem;
        max-width: 50rem;
    }

    /* The invoice itself: fixed ink-on-paper colours in every theme. */
    .paper {
        background-color: #fff;
        box-shadow: var(--adm-shadow-raised);
        color: #1b1b1b;
        font: 400 0.9375rem / 1.5 var(--font-default);
        margin: 0 auto;
        max-width: 50rem;
        padding: clamp(1.5rem, 5vw, 3.5rem);
        position: relative;
    }
    .stamp {
        border: 3px solid #b42318;
        border-radius: 0.25rem;
        color: #b42318;
        font: 800 1.5rem / 1 var(--font-default);
        letter-spacing: 0.2em;
        padding: 0.375rem 0.75rem;
        position: absolute;
        right: clamp(1.5rem, 5vw, 3.5rem);
        text-transform: uppercase;
        top: 0.75rem;
        transform: rotate(-6deg);
    }
    .stamp.draft {
        border-color: #6b6b6b;
        color: #6b6b6b;
    }
    header {
        display: flex;
        flex-wrap: wrap;
        gap: 1.5rem 3rem;
        justify-content: space-between;
        margin-bottom: 2rem;
    }
    .supplier {
        font-size: 1.25rem;
        font-weight: 700;
    }
    .pre {
        white-space: pre-line;
    }
    .paper h1 {
        color: #1b1b1b;
        font: 700 1.75rem / 1.2 var(--font-default);
        letter-spacing: -0.01em;
        margin-bottom: 0.5rem;
    }
    .doc dl div {
        display: flex;
        gap: 1rem;
        justify-content: space-between;
    }
    .doc dt {
        color: #5c5c5c;
    }
    .doc dd {
        font-variant-numeric: tabular-nums;
        font-weight: 600;
    }
    .to {
        margin-bottom: 1.75rem;
    }
    .label {
        color: #5c5c5c;
        font-size: 0.75rem;
        font-weight: 600;
        letter-spacing: 0.06em;
        text-transform: uppercase;
    }
    .client {
        font-weight: 700;
    }
    .muted-print {
        color: #5c5c5c;
    }
    table {
        border-collapse: collapse;
        width: 100%;
    }
    th {
        border-bottom: 2px solid #1b1b1b;
        font-size: 0.8125rem;
        font-weight: 700;
        padding: 0.5rem 0.5rem 0.5rem 0;
        text-align: left;
    }
    td {
        border-bottom: 1px solid #dcdcdc;
        padding: 0.625rem 0.5rem 0.625rem 0;
        vertical-align: top;
    }
    .num {
        font-variant-numeric: tabular-nums;
        padding-right: 0;
        text-align: right;
        white-space: nowrap;
    }
    th.num, td.num {
        padding-left: 1rem;
    }
    .totals {
        margin: 1rem 0 0 auto;
        max-width: 20rem;
    }
    .totals div {
        display: flex;
        gap: 1rem;
        justify-content: space-between;
        padding: 0.25rem 0;
    }
    .totals dd {
        font-variant-numeric: tabular-nums;
    }
    .totals .grand {
        border-bottom: 2px solid #1b1b1b;
        font-size: 1.125rem;
        font-weight: 700;
    }
    footer {
        border-top: 1px solid #dcdcdc;
        color: #5c5c5c;
        display: flex;
        flex-direction: column;
        font-size: 0.875rem;
        gap: 0.375rem;
        margin-top: 2.5rem;
        padding-top: 1rem;
    }

    @media print {
        @page {
            margin: 18mm 16mm;
            size: A4;
        }
        .paper {
            box-shadow: none;
            max-width: none;
            padding: 0;
        }
        .stamp {
            right: 0;
            top: 0;
        }
    }
</style>
