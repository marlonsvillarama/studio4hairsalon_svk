<script>
    import { tick } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { salonInstant } from '$lib/data/availability';
    import { SALON_TZ, salonDay, salonTime, showTime, showDay, showShortDay, dollars, showPhone, adminError, STATUS_LABEL, bookingGaps, overlapsWith } from '$lib/admin';
    import { invoiceForBooking, invoiceNumber } from '$lib/invoices';
    import Switch from './switch.svelte';
    import InvoiceEditor from './invoice-editor.svelte';
    import Modal from './modal.svelte';

    /** booking: a row from s4_bookings with client + items embedded. bookings: everything loaded, to find neighbours. */
    let { booking: b, bookings = [], onchanged, onclose, ondeleted } = $props();

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
        noteOpen = false;
        noteText = '';
        noteError = '';
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
    // Other clients in at the same time (inside or interleaved with this visit).
    let shared = $derived(bookings.filter(x => overlapsWith(x, b)).toSorted((x, z) => x.starts_at.localeCompare(z.starts_at)));
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
            if (error.code === '23P01' && shared.length) {
                actionError += ` ${shared.map(nameOf).join(' and ')} ${shared.length === 1 ? 'shares' : 'share'} this time: move that booking first.`;
            }
            return false;
        }
        mode = '';
        await onchanged?.();
        return true;
    }

    const setStatus = (status) => update({ status });

    // Staff notes (s4_booking_notes): staff only, never shown to clients.
    const NOTE_MAX = 1000;
    let noteOpen = $state(false);
    let noteText = $state('');
    let noteError = $state('');
    let noteSaving = $state(false);
    let noteEl = $state();
    let staffNotes = $derived((b.staff_notes ?? []).toSorted((a, z) => z.created_at.localeCompare(a.created_at)));
    const noteWhen = (t) => `${showShortDay(t)}, ${showTime(t)}`;
    async function openNote() {
        noteOpen = true;
        noteError = '';
        await tick();
        noteEl?.focus();
    }
    function closeNote() {
        noteOpen = false;
        noteText = '';
        noteError = '';
    }
    async function saveNote(e) {
        e?.preventDefault();
        const body = noteText.trim();
        if (!body) { noteError = 'Write a note first.'; noteEl?.focus(); return; }
        noteSaving = true;
        noteError = '';
        const { error } = await sb.from('s4_booking_notes').insert({ booking_id: b.id, body });
        noteSaving = false;
        if (error) { noteError = adminError(error); return; }
        closeNote();
        await onchanged?.();
    }
    const noteKeydown = (e) => { if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) saveNote(e); };
    let deletingNote = $state(null);
    async function deleteNote(n) {
        deletingNote = n.id;
        actionError = '';
        const { error } = await sb.from('s4_booking_notes').delete().eq('id', n.id);
        deletingNote = null;
        if (error) { actionError = adminError(error); return; }
        await onchanged?.();
    }

    // Delete for good (e.g. a test or a mistake). A booking with a tax invoice
    // can't be deleted: the database refuses (23503) to protect tax records.
    let deleteOpen = $state(false);
    let deleting = $state(false);
    let deleteError = $state('');
    function askDelete() {
        deleteError = '';
        deleteOpen = true;
    }
    async function deleteBooking() {
        deleting = true;
        deleteError = '';
        const { data, error } = await sb.from('s4_bookings').delete().eq('id', b.id).select('id');
        deleting = false;
        if (error) {
            deleteError = error.code === '23503'
                ? "This booking has a tax invoice, so it can't be deleted. Cancel it instead."
                : adminError(error);
            return;
        }
        deleteOpen = false;
        await onchanged?.();
        if (!data?.length) { actionError = 'That booking no longer exists.'; return; }
        ondeleted?.();
        onclose?.();
    }
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
            <h2 id="detail-title-{b.id}" class="ref">{b.reference}</h2>
            <p class="when">{showDay(b.starts_at)}</p>
            <p class="when">{showTime(b.starts_at)}–{showTime(b.ends_at)}</p>
        </div>
        {#if onclose}
            <button type="button" class="close" aria-label="Close booking details" onclick={onclose}>
                <i class="ph ph-x" aria-hidden="true"></i>
            </button>
        {/if}
    </header>

    <section class="box client-card" aria-label="Client">
        {#if b.client?.id}
            <a class="client-name" href="/admin/clients/{b.client.id}">
                <span>{b.client.first_name} {b.client.last_name ?? ''}</span><i class="ph ph-caret-right" aria-hidden="true"></i>
            </a>
        {:else}
            <p class="client-name">{b.client?.first_name ?? 'Client'} {b.client?.last_name ?? ''}</p>
        {/if}
        <ul class="contact">
            {#if b.client?.email}
                <li class="email">
                    <i class="ph ph-envelope-simple" aria-hidden="true"></i>
                    <span><a href="mailto:{b.client.email}">{b.client.email}</a>{#if b.client.email_verified}<span class="tag google"><i class="ph ph-google-logo" aria-hidden="true"></i> Signed in with Google</span>{/if}</span>
                </li>
            {/if}
            {#if b.client?.phone_e164 || !b.client?.arranged}
                <li>
                    <i class="ph ph-phone" aria-hidden="true"></i>
                    {#if b.client?.phone_e164}<a href="tel:{b.client.phone_e164}">{showPhone(b.client.phone_e164)}</a>{:else}<span class="muted">No phone</span>{/if}
                </li>
            {/if}
            {#if b.client?.arranged}
                {@const a = b.client.arranged}
                <li>
                    <i class="ph ph-users" aria-hidden="true"></i>
                    <span>Arranged by <a href="/admin/clients/{a.id}">{a.first_name} {a.last_name ?? ''}</a>
                        {#if !b.client.phone_e164 && !b.client.email}
                            <span class="via">Contact via {a.first_name}{#if a.phone_e164}: <a href="tel:{a.phone_e164}">{showPhone(a.phone_e164)}</a>{:else if a.email}: <a href="mailto:{a.email}">{a.email}</a>{/if}</span>
                        {/if}
                    </span>
                </li>
            {/if}
        </ul>
    </section>

    <section class="box summary" aria-label="Booking">
        <span class="status s-{b.status}">{STATUS_LABEL[b.status]}</span>
        <div>
            <h3 class="label">Services</h3>
            <ul class="items">
                {#each items as i}
                    <li><span>{i.name}{#if i.gold_card_applied} <span class="tag">Gold Card</span>{/if}{#if retired(i)} <span class="tag retired">No longer offered</span>{/if}</span></li>
                {/each}
            </ul>
        </div>
        <div class="total-row">
            <span>Total</span>
            <strong>{b.has_variable_price ? 'from ' : ''}{dollars(b.total_cents)}</strong>
        </div>
        {#if b.source === 'admin' || b.kind === 'staff' || gaps.length || b.cancel_reason}
            <dl class="meta">
                {#if b.source === 'admin' || b.kind === 'staff'}
                    <div><dt>Booked</dt><dd>
                        {#if b.kind === 'staff'}<span class="tag">Friends &amp; family</span>{' '}{/if}By {b.booked_by?.display_name ?? 'staff'}
                        {#if b.kind === 'staff' && !b.client?.phone_e164 && !b.client?.email}<span class="via">No contact details: reach them through {b.booked_by?.display_name ?? 'staff'}.</span>{/if}
                    </dd></div>
                {/if}
                {#if gaps.length}
                    <div><dt>Waiting</dt><dd>
                        {#each gaps as g}<span class="gap">{showTime(g.start)}–{showTime(g.end)}</span>{/each}
                        {#if b.status === 'confirmed'}
                            <Switch bind:checked={gapsOpen} label="Offer online" showLabel disabled={busy} onchange={offerGaps} />
                        {/if}
                    </dd></div>
                {/if}
                {#if b.cancel_reason}<div><dt>Cancelled</dt><dd>{b.cancel_reason}</dd></div>{/if}
            </dl>
        {/if}

        <section class="staff-notes" aria-labelledby="notes-title-{b.id}">
            <div class="notes-head">
                <h3 id="notes-title-{b.id}">Notes</h3>
                {#if !noteOpen}
                    <button type="button" class="secondary with-icon small" onclick={openNote}>
                        <i class="ph ph-note-pencil" aria-hidden="true"></i> Add note
                    </button>
                {/if}
            </div>
            {#if b.notes}<p class="client-note"><span class="muted">Client’s note:</span> "{b.notes}"</p>{/if}
            {#if noteOpen}
                <form class="inline" onsubmit={saveNote}>
                    <label for="note-{b.id}" class="sr-only">New note</label>
                    <textarea id="note-{b.id}" bind:this={noteEl} bind:value={noteText} rows="3" maxlength={NOTE_MAX}
                        onkeydown={noteKeydown} oninput={() => noteError = ''} placeholder="e.g. Used colour 6.1, 30 min"
                        aria-invalid={!!noteError} aria-describedby="note-help-{b.id}"></textarea>
                    <p id="note-help-{b.id}" class="note-help" class:error={!!noteError} role={noteError ? 'alert' : undefined}>
                        {#if noteError}{noteError}
                        {:else if noteText.length > NOTE_MAX - 100}{NOTE_MAX - noteText.length} characters left
                        {:else}Only staff can see notes.{/if}
                    </p>
                    <div class="actions">
                        <button type="submit" class="primary" disabled={noteSaving}>{noteSaving ? 'Saving…' : 'Save note'}</button>
                        <button type="button" class="secondary" onclick={closeNote}>Cancel</button>
                    </div>
                </form>
            {/if}
            {#if staffNotes.length}
                <ul class="note-list">
                    {#each staffNotes as n (n.id)}
                        <li>
                            <p class="note-body">{n.body}</p>
                            <div class="note-meta">
                                <span>{n.author?.display_name ?? 'Staff'} · {noteWhen(n.created_at)}</span>
                                <button type="button" class="note-delete" aria-label="Delete note from {noteWhen(n.created_at)}"
                                    title="Delete note" disabled={deletingNote === n.id} onclick={() => deleteNote(n)}>
                                    <i class="ph ph-trash" aria-hidden="true"></i>
                                </button>
                            </div>
                        </li>
                    {/each}
                </ul>
            {:else if !noteOpen && !b.notes}
                <p class="muted none">No notes yet.</p>
            {/if}
        </section>
    </section>

    {#if b.status === 'confirmed'}
        {#if mode === 'reschedule'}
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
        {:else if mode !== 'cancel'}
            <div class="action-row">
                <button type="button" class="primary" disabled={busy} onclick={() => setStatus('completed')}>Complete</button>
                <button type="button" class="secondary" disabled={busy} onclick={() => setStatus('no_show')}>No-show</button>
                <button type="button" class="secondary" onclick={() => mode = 'reschedule'}>Move</button>
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
        {#if !(b.status === 'completed' && invoice?.status === 'issued')}
            <div class="actions">
                <button type="button" class="secondary" disabled={busy} onclick={() => setStatus('confirmed')}>Set back to confirmed</button>
            </div>
        {/if}
    {/if}

    {#if b.status === 'confirmed' && mode === 'cancel'}
        <form class="inline" onsubmit={(e) => { e.preventDefault(); cancel(); }}>
            <label for="reason-{b.id}">Reason (optional)</label>
            <input id="reason-{b.id}" bind:value={cancelReason} placeholder="e.g. client called to cancel" />
            <div class="actions">
                <button type="submit" class="danger" disabled={busy}>Cancel booking</button>
                <button type="button" class="secondary" onclick={() => mode = ''}>Keep it</button>
            </div>
        </form>
    {/if}
    {#if actionError}<p class="error" role="alert">{actionError}</p>{/if}

    {#if (b.status === 'confirmed' && !mode) || !invoice}
        <div class="foot">
            {#if b.status === 'confirmed' && !mode}
                <button type="button" class="danger cancel-btn" onclick={() => mode = 'cancel'}>
                    <i class="ph ph-x-circle" aria-hidden="true"></i> Cancel booking
                </button>
            {/if}
            {#if !invoice}
                <button type="button" class="icon-btn danger-icon" onclick={askDelete}
                    aria-label="Delete booking {b.reference ?? ''}" title="Delete booking">
                    <i class="ph ph-trash" aria-hidden="true"></i>
                </button>
            {/if}
        </div>
    {/if}
</article>

<Modal bind:open={deleteOpen} title="Delete booking?">
    <p>This permanently removes <strong>{b.client?.first_name} {b.client?.last_name ?? ''}</strong>’s booking on
        <strong>{showDay(b.starts_at)}, {showTime(b.starts_at)}</strong> ({b.reference}). It can’t be undone.</p>
    {#if b.status !== 'cancelled'}<p class="muted confirm-hint">To keep a record, cancel it instead.</p>{/if}
    {#if deleteError}<p class="error" role="alert">{deleteError}</p>{/if}
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => deleteOpen = false}>Keep booking</button>
        <button type="button" class="danger" disabled={deleting} onclick={deleteBooking}>{deleting ? 'Deleting…' : 'Delete booking'}</button>
    {/snippet}
</Modal>

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
        font-variant-numeric: tabular-nums;
        font-weight: 700;
        letter-spacing: 0.06em;
        overflow-wrap: anywhere;
        text-transform: uppercase;
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
        align-self: flex-start;
        border-radius: 999px;
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.25rem 0.625rem;
        white-space: nowrap;
    }
    .s-confirmed { background-color: var(--adm-accent-soft); color: var(--adm-accent-text); }
    .s-completed { background-color: var(--adm-success-bg); color: var(--adm-success-text); }
    .s-cancelled, .s-no_show { background-color: var(--adm-border); color: var(--adm-text-muted); }
    .box {
        border: 1px solid var(--adm-border);
        border-radius: 0.5rem;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        padding: 0.875rem;
    }
    .client-card {
        gap: 0.5rem;
    }
    .client-name {
        align-items: center;
        align-self: flex-start;
        color: var(--adm-text);
        display: inline-flex;
        font-size: 1.0625rem;
        font-weight: 700;
        gap: 0.25rem;
        overflow-wrap: anywhere;
    }
    a.client-name {
        text-decoration: none;
    }
    a.client-name span {
        text-decoration: underline;
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    a.client-name i {
        color: var(--adm-text-muted);
        font-size: 0.875rem;
    }
    a.client-name:hover i {
        color: var(--adm-text);
    }
    .contact {
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
        list-style: none;
    }
    .contact li {
        align-items: flex-start;
        display: flex;
        gap: 0.5rem;
        min-width: 0;
        overflow-wrap: anywhere;
    }
    .contact li > i {
        color: var(--adm-text-muted);
        flex: none;
        margin-top: 0.25rem;
    }
    .contact li > span {
        min-width: 0;
    }
    .label {
        color: var(--adm-text-muted);
        font: 400 0.875rem / 1.3 var(--font-default);
        margin-bottom: 0.25rem;
    }
    .total-row {
        align-items: baseline;
        border-top: 1px solid var(--adm-border);
        display: flex;
        justify-content: space-between;
        padding-top: 0.625rem;
    }
    .total-row span {
        color: var(--adm-text-muted);
    }
    .total-row strong {
        font-size: 1.0625rem;
        font-variant-numeric: tabular-nums;
    }
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
    .client-card a:not(.client-name),
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
    .items li + li {
        margin-top: 0.125rem;
    }
    .email {
        overflow-wrap: anywhere;
    }
    .via {
        color: var(--adm-text-muted);
        display: block;
        font-size: 0.875rem;
        margin-top: 0.125rem;
    }
    .email .google {
        align-items: center;
        display: flex;
        gap: 0.25rem;
        margin-top: 0.25rem;
        width: fit-content;
    }
    .client-note {
        font-style: italic;
        overflow-wrap: anywhere;
    }
    .client-note .muted {
        font-style: normal;
    }
    .tag {
        background-color: var(--adm-accent-soft);
        border-radius: 0.25rem;
        color: var(--adm-accent-text);
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.0625rem 0.375rem;
        white-space: nowrap;
    }
    .items .tag {
        margin-left: 0.375rem;
        white-space: nowrap;
    }
    .tag.retired {
        background-color: var(--adm-border);
        color: var(--adm-text-muted);
    }
    .action-row {
        display: grid;
        gap: 0.5rem;
        grid-template-columns: repeat(3, minmax(0, 1fr));
    }
    .action-row button {
        padding: 0 0.25rem;
        white-space: nowrap;
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
    .staff-notes {
        border-top: 1px solid var(--adm-border);
        display: flex;
        flex-direction: column;
        gap: 0.625rem;
        padding-top: 0.875rem;
    }
    .notes-head {
        align-items: center;
        display: flex;
        gap: 0.5rem;
        justify-content: space-between;
    }
    .notes-head h3 {
        color: var(--adm-text);
        font: 600 0.9375rem / 1.3 var(--font-default);
    }
    .small {
        min-height: 2.75rem;
        padding: 0 0.875rem;
    }
    .staff-notes textarea {
        resize: vertical;
        width: 100%;
    }
    .note-help {
        color: var(--adm-text-muted);
        font-size: 0.8125rem;
    }
    .note-help.error {
        color: var(--adm-danger);
        font-weight: 600;
    }
    .note-list {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        list-style: none;
        margin: 0;
        padding: 0;
    }
    .note-list li {
        background-color: var(--adm-sunken);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        padding: 0.5rem 0.25rem 0.25rem 0.75rem;
    }
    .note-body {
        color: var(--adm-text);
        overflow-wrap: anywhere;
        padding-right: 0.5rem;
        white-space: pre-line;
    }
    .note-meta {
        align-items: center;
        color: var(--adm-text-muted);
        display: flex;
        font-size: 0.8125rem;
        justify-content: space-between;
    }
    .note-delete {
        border-radius: 50%;
        color: var(--adm-text-muted);
        cursor: pointer;
        display: grid;
        font-size: 1rem;
        height: 2.75rem;
        place-items: center;
        width: 2.75rem;
    }
    .note-delete:hover {
        background-color: var(--adm-danger-bg);
        color: var(--adm-danger);
    }
    .none {
        font-size: 0.875rem;
    }
    .foot {
        align-items: center;
        border-top: 1px solid var(--adm-border);
        display: flex;
        gap: 0.5rem;
        padding-top: 0.75rem;
    }
    .foot .icon-btn {
        margin-left: auto;
    }
    .cancel-btn {
        align-items: center;
        display: inline-flex;
        gap: 0.5rem;
    }
    .confirm-hint {
        margin-top: 0.5rem;
    }
    .pair {
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
    }
</style>
