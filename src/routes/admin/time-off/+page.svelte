<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { salonInstant } from '$lib/data/availability';
    import { SALON_TZ, salonDay, salonTime, showShortDay, showTime, adminError } from '$lib/admin';

    const sb = getSupabase();
    let items = $state([]);
    let loading = $state(true);
    let message = $state('');
    let error = $state('');
    let saving = $state(false);

    // New entry
    let fromDate = $state(salonDay(Date.now()));
    let toDate = $state(salonDay(Date.now()));
    let allDay = $state(true);
    let fromTime = $state('12:00');
    let toTime = $state('13:00');
    let reason = $state('');

    async function load() {
        loading = true;
        const { data, error: e } = await sb.from('s4_time_off')
            .select('id, starts_at, ends_at, reason')
            .gte('ends_at', new Date().toISOString())
            .order('starts_at');
        loading = false;
        if (e) { error = adminError(e); return; }
        items = data;
    }
    onMount(load);

    const nextDay = (iso) => {
        const [y, m, d] = iso.split('-').map(Number);
        const t = new Date(Date.UTC(y, m - 1, d + 1));
        return t.toISOString().slice(0, 10);
    };

    async function add(e) {
        e.preventDefault();
        error = '';
        message = '';
        const start = allDay ? salonInstant(fromDate, '00:00', SALON_TZ) : salonInstant(fromDate, fromTime, SALON_TZ);
        const end = allDay ? salonInstant(nextDay(toDate || fromDate), '00:00', SALON_TZ) : salonInstant(fromDate, toTime, SALON_TZ);
        if (end <= start) { error = 'The end must be after the start.'; return; }
        saving = true;
        const { data: { user } } = await sb.auth.getUser();
        const { error: e2 } = await sb.from('s4_time_off').insert({
            starts_at: start.toISOString(),
            ends_at: end.toISOString(),
            reason: reason.trim() || null,
            created_by: user?.id
        });
        saving = false;
        if (e2) { error = adminError(e2); return; }
        message = 'Saved. Those times are no longer bookable online.';
        reason = '';
        load();
    }

    async function remove(item) {
        error = '';
        const { error: e } = await sb.from('s4_time_off').delete().eq('id', item.id);
        if (e) { error = adminError(e); return; }
        load();
    }

    const describe = (t) => {
        const sameDay = salonDay(t.starts_at) === salonDay(new Date(new Date(t.ends_at).getTime() - 1));
        const startsMidnight = salonTime(t.starts_at) === '00:00';
        const endsMidnight = salonTime(t.ends_at) === '00:00';
        if (startsMidnight && endsMidnight) {
            const last = new Date(new Date(t.ends_at).getTime() - 1);
            return sameDay ? `${showShortDay(t.starts_at)}, all day` : `${showShortDay(t.starts_at)} – ${showShortDay(last)}, all day`;
        }
        return `${showShortDay(t.starts_at)}, ${showTime(t.starts_at)} – ${showTime(t.ends_at)}`;
    };
</script>

<h1>Time off</h1>
<p class="muted intro">Days off, holidays and breaks. Online booking won't offer these times. Existing bookings aren't changed.</p>

<form class="panel add" onsubmit={add}>
    <h2>Add time off</h2>
    <label class="check"><input type="checkbox" bind:checked={allDay} /> Whole day(s)</label>
    <div class="pair">
        <label>{allDay ? 'From' : 'Date'} <input type="date" required bind:value={fromDate} /></label>
        {#if allDay}
            <label>To <input type="date" required bind:value={toDate} min={fromDate} /></label>
        {:else}
            <label>From <input type="time" step="900" required bind:value={fromTime} /></label>
            <label>To <input type="time" step="900" required bind:value={toTime} /></label>
        {/if}
    </div>
    <label>Reason (only you see this) <input bind:value={reason} placeholder="e.g. Christmas, dentist" /></label>
    <div><button type="submit" class="primary" disabled={saving}>{saving ? 'Saving…' : 'Add time off'}</button></div>
    {#if message}<p class="ok" role="status">{message}</p>{/if}
    {#if error}<p class="error" role="alert">{error}</p>{/if}
</form>

<h2 class="list-head">Coming up</h2>
{#if loading}
    <p class="muted" role="status">Loading…</p>
{:else if items.length === 0}
    <p class="muted">No time off booked.</p>
{:else}
    <ul class="list">
        {#each items as t (t.id)}
            <li class="panel">
                <span><strong>{describe(t)}</strong>{#if t.reason}<span class="muted"> · {t.reason}</span>{/if}</span>
                <button type="button" class="secondary" onclick={() => remove(t)}>Remove</button>
            </li>
        {/each}
    </ul>
{/if}

<style>
    .intro {
        margin: 0.5rem 0 1.5rem;
    }
    .add {
        display: flex;
        flex-direction: column;
        gap: 0.875rem;
        max-width: 40rem;
    }
    label {
        display: flex;
        flex-direction: column;
        font-weight: 600;
        gap: 0.25rem;
    }
    .check {
        align-items: center;
        flex-direction: row;
        gap: 0.5rem;
    }
    .pair {
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
    }
    .list-head {
        margin: 2rem 0 0.75rem;
    }
    .list {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        max-width: 40rem;
    }
    .list li {
        align-items: center;
        display: flex;
        gap: 1rem;
        justify-content: space-between;
        padding: 0.75rem 1rem;
    }
</style>
