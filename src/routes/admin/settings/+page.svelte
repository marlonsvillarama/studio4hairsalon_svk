<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { adminError } from '$lib/admin';

    const sb = getSupabase();
    const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    let settings = $state(null);
    let hours = $state([]);
    let loading = $state(true);
    let error = $state('');
    let message = $state('');
    let saving = $state(false);

    async function load() {
        loading = true;
        const [s, h] = await Promise.all([
            sb.from('s4_settings').select('*').single(),
            sb.from('s4_business_hours').select('*').order('weekday')
        ]);
        loading = false;
        if (s.error || h.error) { error = adminError(s.error || h.error); return; }
        settings = s.data;
        hours = h.data.map(d => ({
            ...d,
            opens_at: d.opens_at?.slice(0, 5) ?? '09:30',
            closes_at: d.closes_at?.slice(0, 5) ?? '17:00'
        }));
    }
    onMount(load);

    async function save(e) {
        e.preventDefault();
        error = '';
        message = '';
        for (const d of hours) {
            if (d.is_open && d.closes_at <= d.opens_at) {
                error = `${DAYS[d.weekday]}: closing time must be after opening time.`;
                return;
            }
        }
        saving = true;
        const s = await sb.from('s4_settings').update({
            online_booking_enabled: settings.online_booking_enabled,
            min_notice_min: Number(settings.min_notice_min),
            horizon_days: Number(settings.horizon_days),
            slot_step_min: Number(settings.slot_step_min),
            max_open_bookings_per_phone: Number(settings.max_open_bookings_per_phone)
        }).eq('id', true);
        const h = await sb.from('s4_business_hours').upsert(hours.map(d => ({
            weekday: d.weekday,
            is_open: d.is_open,
            opens_at: d.is_open ? d.opens_at : null,
            closes_at: d.is_open ? d.closes_at : null
        })));
        saving = false;
        if (s.error || h.error) { error = adminError(s.error || h.error); return; }
        message = 'Saved.';
    }
</script>

<h1>Settings</h1>

{#if loading}
    <p class="muted" role="status">Loading…</p>
{:else if !settings}
    <p class="error">{error}</p>
{:else}
    <form class="layout" onsubmit={save}>
        <section class="panel">
            <h2>Online booking</h2>
            <label class="check big">
                <input type="checkbox" bind:checked={settings.online_booking_enabled} />
                Take bookings online
            </label>
            <p class="muted">When off, the booking page asks clients to call or text instead.</p>

            <div class="grid">
                <label>Minimum notice (minutes)
                    <input type="number" min="0" step="15" bind:value={settings.min_notice_min} />
                </label>
                <label>Book up to (days ahead)
                    <input type="number" min="1" max="60" bind:value={settings.horizon_days} />
                </label>
                <label>Start times every (minutes)
                    <select bind:value={settings.slot_step_min}>
                        <option value={15}>15</option>
                        <option value={30}>30</option>
                        <option value={60}>60</option>
                    </select>
                </label>
                <label>Upcoming bookings allowed per client
                    <input type="number" min="1" max="20" bind:value={settings.max_open_bookings_per_phone} />
                </label>
            </div>
        </section>

        <section class="panel">
            <h2>Opening hours</h2>
            <ul class="hours">
                {#each hours as d (d.weekday)}
                    <li>
                        <label class="check day"><input type="checkbox" bind:checked={d.is_open} /> {DAYS[d.weekday]}</label>
                        {#if d.is_open}
                            <label class="sr-label"><span class="sr-only">{DAYS[d.weekday]} opens</span>
                                <input type="time" step="900" bind:value={d.opens_at} /></label>
                            <span aria-hidden="true">to</span>
                            <label class="sr-label"><span class="sr-only">{DAYS[d.weekday]} closes</span>
                                <input type="time" step="900" bind:value={d.closes_at} /></label>
                        {:else}
                            <span class="muted">Closed</span>
                        {/if}
                    </li>
                {/each}
            </ul>
        </section>

        <div class="bar">
            <button type="submit" class="primary" disabled={saving}>{saving ? 'Saving…' : 'Save settings'}</button>
            {#if message}<span class="ok" role="status">{message}</span>{/if}
            {#if error}<span class="error" role="alert">{error}</span>{/if}
        </div>
    </form>
{/if}

<style>
    h1 {
        margin-bottom: 1.5rem;
    }
    .layout {
        display: flex;
        flex-direction: column;
        gap: 1.25rem;
        max-width: 44rem;
    }
    .panel h2 {
        margin-bottom: 0.75rem;
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
    .big {
        font-size: 1.0625rem;
    }
    .grid {
        display: grid;
        gap: 1rem;
        grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr));
        margin-top: 1.25rem;
    }
    .hours {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .hours li {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        min-height: 2.75rem;
    }
    .day {
        width: 9rem;
    }
    .sr-label {
        flex-direction: row;
    }
    .bar {
        align-items: center;
        display: flex;
        gap: 1rem;
    }
</style>
