<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { salonInstant } from '$lib/data/availability';
    import { SALON_TZ, salonDay, salonTime, showTime, showDay, dollars, showPhone, adminError } from '$lib/admin';

    const sb = getSupabase();
    let tab = $state('upcoming');      // upcoming | past
    let bookings = $state([]);
    let loading = $state(true);
    let loadError = $state('');
    let openId = $state(null);
    let busyId = $state(null);
    let actionError = $state('');
    let cancelReason = $state('');
    let mode = $state('');             // '' | cancel | reschedule
    let newDate = $state('');
    let newTime = $state('');

    // True when the booked service has since been turned off or removed
    // (directly, or through its category). The booking itself is unaffected.
    const retired = (item) => {
        const s = item.service;
        return !s || !s.is_active || !!s.deleted_at || !s.category?.is_active || !!s.category?.deleted_at;
    };

    const statusLabel = { confirmed: 'Confirmed', cancelled: 'Cancelled', completed: 'Completed', no_show: 'No-show' };

    async function load() {
        loading = true;
        loadError = '';
        const startOfToday = salonInstant(salonDay(Date.now()), '00:00', SALON_TZ).toISOString();
        let q = sb.from('s4_bookings')
            .select(`id, reference, starts_at, ends_at, status, total_cents, has_variable_price, gold_card, notes, cancel_reason, source,
                     client:s4_clients ( first_name, last_name, phone_e164, email, email_verified ),
                     items:s4_booking_items ( name, price_cents, gold_card_applied, sort_order,
                         service:s4_services ( is_active, deleted_at, category:s4_categories ( is_active, deleted_at ) ) )`);
        q = tab === 'upcoming'
            ? q.gte('starts_at', startOfToday).order('starts_at', { ascending: true }).limit(200)
            : q.lt('starts_at', startOfToday).order('starts_at', { ascending: false }).limit(100);
        const { data, error } = await q;
        loading = false;
        if (error) {
            loadError = adminError(error);
            return;
        }
        bookings = data;
    }

    onMount(load);

    let groups = $derived.by(() => {
        const map = new Map();
        for (const b of bookings) {
            const key = salonDay(b.starts_at);
            if (!map.has(key)) map.set(key, []);
            map.get(key).push(b);
        }
        return [...map.entries()];
    });

    function toggle(b) {
        openId = openId === b.id ? null : b.id;
        mode = '';
        actionError = '';
        cancelReason = '';
        newDate = salonDay(b.starts_at);
        newTime = salonTime(b.starts_at);
    }

    async function update(b, patch) {
        busyId = b.id;
        actionError = '';
        const { error } = await sb.from('s4_bookings').update(patch).eq('id', b.id);
        busyId = null;
        if (error) {
            actionError = adminError(error);
            return false;
        }
        mode = '';
        await load();
        return true;
    }

    const setStatus = (b, status) => update(b, { status });
    const cancel = (b) => update(b, {
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
        cancel_reason: cancelReason.trim() || null
    });
    function reschedule(b) {
        const length = new Date(b.ends_at) - new Date(b.starts_at);
        const start = salonInstant(newDate, newTime, SALON_TZ);
        return update(b, { starts_at: start.toISOString(), ends_at: new Date(start.getTime() + length).toISOString() });
    }

    const switchTab = (t) => { tab = t; openId = null; load(); };
</script>

<div class="head">
    <h1>Bookings</h1>
    <div class="tabs" role="tablist" aria-label="Which bookings">
        <button type="button" role="tab" aria-selected={tab === 'upcoming'} onclick={() => switchTab('upcoming')}>Today & upcoming</button>
        <button type="button" role="tab" aria-selected={tab === 'past'} onclick={() => switchTab('past')}>Past</button>
    </div>
</div>

{#if loading}
    <p class="muted" role="status">Loading bookings…</p>
{:else if loadError}
    <div class="panel"><p class="error">{loadError}</p><button type="button" class="secondary" onclick={load}>Try again</button></div>
{:else if groups.length === 0}
    <div class="panel"><p class="muted">{tab === 'upcoming' ? 'No bookings from today onwards yet.' : 'No past bookings.'}</p></div>
{:else}
    {#each groups as [day, list] (day)}
        <section class="day">
            <h2>{showDay(list[0].starts_at)} <span class="count">{list.length} {list.length === 1 ? 'booking' : 'bookings'}</span></h2>
            <ul>
                {#each list as b (b.id)}
                    <li class="booking" class:inactive={b.status === 'cancelled' || b.status === 'no_show'}>
                        <button type="button" class="row" aria-expanded={openId === b.id} onclick={() => toggle(b)}>
                            <span class="time">{showTime(b.starts_at)}–{showTime(b.ends_at)}</span>
                            <span class="who">
                                <strong>{b.client?.first_name} {b.client?.last_name ?? ''}</strong>
                                <span class="services">{b.items.toSorted((a, z) => a.sort_order - z.sort_order).map(i => i.name).join(', ')}</span>
                            </span>
                            <span class="status s-{b.status}">{statusLabel[b.status]}</span>
                        </button>

                        {#if openId === b.id}
                            <div class="detail">
                                <dl>
                                    <div><dt>Phone</dt><dd>{#if b.client?.phone_e164}<a href="tel:{b.client.phone_e164}">{showPhone(b.client.phone_e164)}</a>{:else}<span class="muted">No phone</span>{/if}</dd></div>
                                    {#if b.client?.email}
                                        <div><dt>Email</dt><dd><a href="mailto:{b.client.email}">{b.client.email}</a>{#if b.client.email_verified} <span class="tag">Google</span>{/if}</dd></div>
                                    {/if}
                                    <div><dt>Services</dt><dd>
                                        <ul class="items">
                                            {#each b.items.toSorted((a, z) => a.sort_order - z.sort_order) as i}
                                                <li><span>{i.name}{#if i.gold_card_applied} <span class="tag">Gold Card</span>{/if}{#if retired(i)} <span class="tag retired">No longer offered</span>{/if}</span><span>{dollars(i.price_cents)}</span></li>
                                            {/each}
                                        </ul>
                                    </dd></div>
                                    <div><dt>Total</dt><dd><strong>{b.has_variable_price ? 'from ' : ''}{dollars(b.total_cents)}</strong></dd></div>
                                    {#if b.notes}<div><dt>Notes</dt><dd class="notes">"{b.notes}"</dd></div>{/if}
                                    {#if b.cancel_reason}<div><dt>Cancelled</dt><dd>{b.cancel_reason}</dd></div>{/if}
                                    <div><dt>Reference</dt><dd class="ref">{b.reference}</dd></div>
                                </dl>

                                {#if b.status === 'confirmed'}
                                    {#if mode === 'cancel'}
                                        <form class="inline" onsubmit={(e) => { e.preventDefault(); cancel(b); }}>
                                            <label for="reason-{b.id}">Reason (optional)</label>
                                            <input id="reason-{b.id}" bind:value={cancelReason} placeholder="e.g. client called to cancel" />
                                            <div class="actions">
                                                <button type="submit" class="danger" disabled={busyId === b.id}>Cancel booking</button>
                                                <button type="button" class="secondary" onclick={() => mode = ''}>Keep it</button>
                                            </div>
                                        </form>
                                    {:else if mode === 'reschedule'}
                                        <form class="inline" onsubmit={(e) => { e.preventDefault(); reschedule(b); }}>
                                            <div class="pair">
                                                <label>New date <input type="date" required bind:value={newDate} /></label>
                                                <label>New start time <input type="time" step="900" required bind:value={newTime} /></label>
                                            </div>
                                            <p class="muted">Keeps the same length. Overlapping another booking isn't allowed.</p>
                                            <div class="actions">
                                                <button type="submit" class="primary" disabled={busyId === b.id}>Move booking</button>
                                                <button type="button" class="secondary" onclick={() => mode = ''}>Back</button>
                                            </div>
                                        </form>
                                    {:else}
                                        <div class="actions">
                                            <button type="button" class="primary" disabled={busyId === b.id} onclick={() => setStatus(b, 'completed')}>Mark completed</button>
                                            <button type="button" class="secondary" onclick={() => mode = 'reschedule'}>Reschedule</button>
                                            <button type="button" class="secondary" disabled={busyId === b.id} onclick={() => setStatus(b, 'no_show')}>No-show</button>
                                            <button type="button" class="danger" onclick={() => mode = 'cancel'}>Cancel…</button>
                                        </div>
                                    {/if}
                                {:else}
                                    <div class="actions">
                                        <button type="button" class="secondary" disabled={busyId === b.id} onclick={() => setStatus(b, 'confirmed')}>Set back to confirmed</button>
                                    </div>
                                {/if}
                                {#if actionError}<p class="error" role="alert">{actionError}</p>{/if}
                            </div>
                        {/if}
                    </li>
                {/each}
            </ul>
        </section>
    {/each}
{/if}

<style>
    .head {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 1rem;
        justify-content: space-between;
        margin-bottom: 1.5rem;
    }
    .tabs {
        display: flex;
        gap: 0.25rem;
    }
    .tabs button {
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        cursor: pointer;
        font-weight: 500;
        min-height: 2.75rem;
        padding: 0 0.875rem;
        background-color: var(--white);
    }
    .tabs button[aria-selected="true"] {
        background-color: var(--darkest);
        border-color: var(--darkest);
        color: var(--white);
    }
    .day {
        margin-bottom: 2rem;
    }
    .day h2 {
        margin-bottom: 0.625rem;
    }
    .count {
        color: var(--dark);
        font-size: 0.875rem;
        font-weight: 400;
        margin-left: 0.5rem;
    }
    .day > ul {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .booking {
        background-color: var(--white);
        border: 1px solid var(--light);
        border-radius: 0.375rem;
    }
    .booking.inactive .row {
        opacity: 0.6;
    }
    .row {
        align-items: center;
        cursor: pointer;
        display: grid;
        gap: 0.25rem 1rem;
        grid-template-columns: 8.5rem 1fr auto;
        padding: 0.875rem 1rem;
        text-align: left;
        width: 100%;
    }
    @media (max-width: 40rem) {
        .row {
            grid-template-columns: 1fr auto;
        }
        .row .who {
            grid-column: 1 / -1;
            grid-row: 2;
        }
    }
    .time {
        color: var(--darkest);
        font-variant-numeric: tabular-nums;
        font-weight: 600;
    }
    .who {
        display: flex;
        flex-direction: column;
        min-width: 0;
    }
    .services {
        color: var(--dark);
        font-size: 0.875rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    .status {
        border-radius: 999px;
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.25rem 0.625rem;
        white-space: nowrap;
    }
    .s-confirmed { background-color: var(--color-accent-100); color: var(--color-accent-800); }
    .s-completed { background-color: #e3f4e8; color: #1d6b38; }
    .s-cancelled, .s-no_show { background-color: var(--light); color: var(--dark); }
    .detail {
        border-top: 1px solid var(--light);
        display: flex;
        flex-direction: column;
        gap: 1rem;
        padding: 1rem;
    }
    dl {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    dl > div {
        display: grid;
        gap: 1rem;
        grid-template-columns: 6rem 1fr;
    }
    dt {
        color: var(--dark);
        font-size: 0.875rem;
    }
    dd a {
        color: var(--darkest);
        font-weight: 600;
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
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
        background-color: var(--color-accent-100);
        border-radius: 0.25rem;
        color: var(--color-accent-800);
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.0625rem 0.375rem;
    }
    .tag.retired {
        background-color: var(--light);
        color: var(--dark);
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
        max-width: 32rem;
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
