<script>
    import { getSupabase } from '$lib/supabase';
    import { salonInstant } from '$lib/data/availability';
    import { SALON_TZ, salonDay, salonTime, showTime, showDay, dollars, showPhone, adminError, STATUS_LABEL, bookingGaps, sitsInside } from '$lib/admin';
    import { invoiceForBooking, invoiceNumber } from '$lib/invoices';
    import Switch from './switch.svelte';
    import InvoiceEditor from './invoice-editor.svelte';

    /** booking: a row from s4_bookings with client + items embedded. bookings: everything loaded, to find neighbours. */
    let { booking: b, bookings = [], onchanged, onclose } = $props();

    const sb = getSupabase();
    let busy = $state(false);
    let actionError = $state('');
    let cancelReason = $state('');
    let mode = $state('');             // '' | cancel | reschedule
    let newDate = $state('');
    let newTime = $state('');

    // Tax invoice for a completed booking (the live one, not voided).
    let invoice = $state(null);        // { id, number, status } | null
    let invoiceOpen = $state(false);
    let invoiceId = $state(null);
    async function loadInvoiceRow() {
        if (b.status !== 'completed') { invoice = null; return; }
        const id = b.id;
        const { data } = await sb.from('s4_invoices').select('id, number, status')
            .eq('booking_id', id).neq('status', 'void').maybeSingle();
        if (id === b.id) invoice = data;
    }
    async function openInvoice() {
        busy = true;
        actionError = '';
        try {
            invoiceId = await invoiceForBooking(b.id);
            invoiceOpen = true;
            loadInvoiceRow();
        } catch (e) {
            actionError = e.message;
        }
        busy = false;
    }

    // Reset the panel whenever a different booking is opened.
    $effect(() => {
        b.id;
        b.status;
        loadInvoiceRow();
        mode = '';
        actionError = '';
        cancelReason = '';
        newDate = salonDay(b.starts_at);
        newTime = salonTime(b.starts_at);
    });

    // True when the booked service has since been turned off or removed
    // (directly, or through its category). The booking itself is unaffected.
    const retired = (item) => {
        const s = item.service;
        return !s || !s.is_active || !!s.deleted_at || !s.category?.is_active || !!s.category?.deleted_at;
    };

    let items = $derived(b.items.toSorted((a, z) => a.sort_order - z.sort_order));

    // Waiting time, and who shares it.
    let gaps = $derived(bookingGaps(b));
    let guests = $derived(bookings.filter(x => sitsInside(x, b)));
    let host = $derived(bookings.find(x => sitsInside(b, x)));
    const nameOf = (x) => `${x.client?.first_name ?? ''} ${x.client?.last_name ?? ''}`.trim() || 'Another client';
    let gapsOpen = $state(true);
    $effect(() => { gapsOpen = b.gaps_open; });
    async function offerGaps(v) {
        if (!(await update({ gaps_open: v }))) gapsOpen = !v;
    }

    async function update(patch) {
        busy = true;
        actionError = '';
        const { error } = await sb.from('s4_bookings').update(patch).eq('id', b.id);
        busy = false;
        if (error) {
            actionError = adminError(error);
            if (error.code === '23P01' && guests.length) {
                actionError += ` ${guests.map(nameOf).join(' and ')} ${guests.length === 1 ? 'is' : 'are'} booked in the waiting time: move that booking first.`;
            }
            return false;
        }
        mode = '';
        await onchanged?.();
        return true;
    }

    const setStatus = (status) => update({ status });
    const cancel = () => update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
        cancel_reason: cancelReason.trim() || null
    });
    function reschedule() {
        const length = new Date(b.ends_at) - new Date(b.starts_at);
        const start = salonInstant(newDate, newTime, SALON_TZ);
        return update({ starts_at: start.toISOString(), ends_at: new Date(start.getTime() + length).toISOString() });
    }
</script>

<article class="detail panel" aria-labelledby="detail-title-{b.id}">
    <header>
        <div>
            <h2 id="detail-title-{b.id}">{b.client?.first_name} {b.client?.last_name ?? ''}</h2>
            <p class="when">{showDay(b.starts_at)}, {showTime(b.starts_at)}–{showTime(b.ends_at)}</p>
        </div>
        <span class="status s-{b.status}">{STATUS_LABEL[b.status]}</span>
        {#if onclose}
            <button type="button" class="close" aria-label="Close booking details" onclick={onclose}>
                <i class="ph ph-x" aria-hidden="true"></i>
            </button>
        {/if}
    </header>

    <dl>
        <div><dt>Phone</dt><dd>{#if b.client?.phone_e164}<a href="tel:{b.client.phone_e164}">{showPhone(b.client.phone_e164)}</a>{:else}<span class="muted">No phone</span>{/if}</dd></div>
        {#if b.client?.email}
            <div><dt>Email</dt><dd><a href="mailto:{b.client.email}">{b.client.email}</a>{#if b.client.email_verified} <span class="tag">Google</span>{/if}</dd></div>
        {/if}
        <div><dt>Services</dt><dd>
            <ul class="items">
                {#each items as i}
                    <li><span>{i.name}{#if i.gold_card_applied} <span class="tag">Gold Card</span>{/if}{#if retired(i)} <span class="tag retired">No longer offered</span>{/if}</span><span>{dollars(i.price_cents)}</span></li>
                {/each}
            </ul>
        </dd></div>
        {#if b.source === 'admin'}<div><dt>Booked</dt><dd>By staff</dd></div>{/if}
        <div><dt>Total</dt><dd><strong>{b.has_variable_price ? 'from ' : ''}{dollars(b.total_cents)}</strong></dd></div>
        {#if gaps.length}
            <div><dt>Waiting</dt><dd>
                {#each gaps as g}<span class="gap">{showTime(g.start)}–{showTime(g.end)}</span>{/each}
                {#each guests as x (x.id)}<span class="gap">{nameOf(x)} at {showTime(x.starts_at)}</span>{/each}
                {#if b.status === 'confirmed'}
                    <Switch bind:checked={gapsOpen} label="Offer online" showLabel disabled={busy} onchange={offerGaps} />
                {/if}
            </dd></div>
        {/if}
        {#if host}<div><dt>During</dt><dd>{nameOf(host)}'s waiting time</dd></div>{/if}
        {#if b.notes}<div><dt>Notes</dt><dd class="notes">"{b.notes}"</dd></div>{/if}
        {#if b.cancel_reason}<div><dt>Cancelled</dt><dd>{b.cancel_reason}</dd></div>{/if}
        <div><dt>Reference</dt><dd class="ref">{b.reference}</dd></div>
    </dl>

    {#if b.status === 'confirmed'}
        {#if mode === 'cancel'}
            <form class="inline" onsubmit={(e) => { e.preventDefault(); cancel(); }}>
                <label for="reason-{b.id}">Reason (optional)</label>
                <input id="reason-{b.id}" bind:value={cancelReason} placeholder="e.g. client called to cancel" />
                <div class="actions">
                    <button type="submit" class="danger" disabled={busy}>Cancel booking</button>
                    <button type="button" class="secondary" onclick={() => mode = ''}>Keep it</button>
                </div>
            </form>
        {:else if mode === 'reschedule'}
            <form class="inline" onsubmit={(e) => { e.preventDefault(); reschedule(); }}>
                <div class="pair">
                    <label>New date <input type="date" required bind:value={newDate} /></label>
                    <label>New start time <input type="time" step="900" required bind:value={newTime} /></label>
                </div>
                <p class="muted">Keeps the same length. Overlapping another booking isn't allowed.</p>
                <div class="actions">
                    <button type="submit" class="primary" disabled={busy}>Move booking</button>
                    <button type="button" class="secondary" onclick={() => mode = ''}>Back</button>
                </div>
            </form>
        {:else}
            <div class="actions">
                <button type="button" class="primary" disabled={busy} onclick={() => setStatus('completed')}>Mark completed</button>
                <button type="button" class="secondary" onclick={() => mode = 'reschedule'}>Reschedule</button>
                <button type="button" class="secondary" disabled={busy} onclick={() => setStatus('no_show')}>No-show</button>
                <button type="button" class="danger" onclick={() => mode = 'cancel'}>Cancel…</button>
            </div>
        {/if}
    {:else}
        {#if b.status === 'completed'}
            <div class="invoice">
                <i class="ph ph-receipt" aria-hidden="true"></i>
                <p>
                    {#if !invoice}Completed. Ready for a tax invoice.
                    {:else if invoice.status === 'draft'}A draft tax invoice is started.
                    {:else}Tax invoice <strong>{invoiceNumber(invoice.number)}</strong> issued.{/if}
                </p>
                <button type="button" class={invoice?.status === 'issued' ? 'secondary' : 'primary'} disabled={busy} onclick={openInvoice}>
                    {#if !invoice}Create tax invoice{:else if invoice.status === 'draft'}Continue invoice{:else}View invoice{/if}
                </button>
            </div>
        {/if}
        <div class="actions">
            {#if !(b.status === 'completed' && invoice?.status === 'issued')}
                <button type="button" class="secondary" disabled={busy} onclick={() => setStatus('confirmed')}>Set back to confirmed</button>
            {/if}
        </div>
    {/if}
    {#if actionError}<p class="error" role="alert">{actionError}</p>{/if}
</article>

<InvoiceEditor bind:open={invoiceOpen} {invoiceId} onchanged={loadInvoiceRow} />

<style>
    .invoice {
        align-items: center;
        background-color: var(--adm-success-bg);
        border: 1px solid var(--adm-success-border);
        border-radius: 0.375rem;
        color: var(--adm-success-text);
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 0.75rem;
        padding: 0.625rem 0.75rem;
    }
    .gap {
        display: block;
    }
    .invoice > i {
        font-size: 1.25rem;
    }
    .invoice p {
        flex: 1 1 10rem;
    }
    .detail {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    header {
        align-items: flex-start;
        display: flex;
        gap: 0.75rem;
    }
    header > div {
        flex: 1;
        min-width: 0;
    }
    h2 {
        font-size: 1.25rem;
        overflow-wrap: anywhere;
    }
    .when {
        color: var(--adm-text-muted);
        font-size: 0.9375rem;
        margin-top: 0.125rem;
    }
    .close {
        border-radius: 50%;
        color: var(--adm-text-muted);
        cursor: pointer;
        display: grid;
        flex: none;
        font-size: 1.25rem;
        height: 2.75rem;
        margin: -0.5rem -0.5rem 0 0;
        place-items: center;
        width: 2.75rem;
    }
    .close:hover {
        background-color: var(--adm-sunken);
        color: var(--adm-text);
    }
    .status {
        border-radius: 999px;
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.25rem 0.625rem;
        white-space: nowrap;
    }
    .s-confirmed { background-color: var(--adm-accent-soft); color: var(--adm-accent-text); }
    .s-completed { background-color: var(--adm-success-bg); color: var(--adm-success-text); }
    .s-cancelled, .s-no_show { background-color: var(--adm-border); color: var(--adm-text-muted); }
    dl {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    dl > div {
        display: grid;
        gap: 1rem;
        grid-template-columns: 5.5rem 1fr;
    }
    dt {
        color: var(--adm-text-muted);
        font-size: 0.875rem;
    }
    dd {
        min-width: 0;
        overflow-wrap: anywhere;
    }
    dd a {
        color: var(--adm-text);
        font-weight: 600;
        text-decoration: underline;
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    .items {
        list-style: none;
    }
    .items li {
        display: flex;
        gap: 1rem;
        justify-content: space-between;
    }
    .notes {
        font-style: italic;
    }
    .ref {
        font-variant-numeric: tabular-nums;
        letter-spacing: 0.04em;
    }
    .tag {
        background-color: var(--adm-accent-soft);
        border-radius: 0.25rem;
        color: var(--adm-accent-text);
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.0625rem 0.375rem;
    }
    .items .tag {
        margin-left: 0.375rem;
        white-space: nowrap;
    }
    .tag.retired {
        background-color: var(--adm-border);
        color: var(--adm-text-muted);
    }
    .actions {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
    }
    .inline {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .inline label {
        display: flex;
        flex-direction: column;
        font-weight: 600;
        gap: 0.25rem;
    }
    .pair {
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
    }
</style>
