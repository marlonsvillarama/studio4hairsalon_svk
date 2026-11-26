<script>
    import { tick } from 'svelte';
    import { page } from '$app/state';
    import { goto } from '$app/navigation';
    import { getSupabase } from '$lib/supabase';
    import { salonInstant } from '$lib/data/availability';
    import {
        SALON_TZ, salonDay, adminError, addDays, addMonths, startOfWeek, monthGrid, rangeTitle, isInactive, blocksForDay
    } from '$lib/admin';
    import DayTimeline from '$lib/components/admin/day-timeline.svelte';
    import MonthGrid from '$lib/components/admin/month-grid.svelte';
    import BookingDetail from '$lib/components/admin/booking-detail.svelte';
    import BookingCreate from '$lib/components/admin/booking-create.svelte';

    const sb = getSupabase();
    const VIEWS = [
        { id: 'day', label: 'Day' },
        { id: 'week', label: 'Week' },
        { id: 'month', label: 'Month' }
    ];
    const today = salonDay(Date.now());

    // ─── view + date live in the URL (?view=week&date=2026-11-19) ─────────
    let view = $derived(VIEWS.some(v => v.id === page.url.searchParams.get('view')) ? page.url.searchParams.get('view') : 'day');
    let date = $derived(/^\d{4}-\d{2}-\d{2}$/.test(page.url.searchParams.get('date') ?? '') ? page.url.searchParams.get('date') : today);

    function go(nextView, nextDate) {
        const params = new URLSearchParams(page.url.searchParams);
        params.set('view', nextView);
        params.set('date', nextDate);
        return goto(`?${params}`, { replaceState: true, keepFocus: true, noScroll: true });
    }
    const step = (dir) => go(view, view === 'day' ? addDays(date, dir) : view === 'week' ? addDays(date, 7 * dir) : addMonths(date, dir));
    const openDay = (iso) => go('day', iso);
    // "Today" is redundant when today is already on screen.
    let showsToday = $derived(
        view === 'day' ? date === today
        : view === 'week' ? startOfWeek(date) === startOfWeek(today)
        : date.slice(0, 7) === today.slice(0, 7)
    );

    // ─── visible range ──────────────────────────────────────────────────
    let days = $derived(view === 'day' ? [date] : view === 'week' ? Array.from({ length: 7 }, (_, i) => addDays(startOfWeek(date), i)) : monthGrid(date));
    let rangeStart = $derived(salonInstant(days[0], '00:00', SALON_TZ).toISOString());
    let rangeEnd = $derived(salonInstant(addDays(days.at(-1), 1), '00:00', SALON_TZ).toISOString());

    // ─── data ───────────────────────────────────────────────────────────
    let bookings = $state([]);
    let timeOff = $state([]);
    let hours = $state({});
    let loading = $state(true);
    let loadError = $state('');
    let showCancelled = $state(true);
    let selectedId = $state(null);

    const toMinutes = (t) => { const [h, m] = t.split(':').map(Number); return h * 60 + m; };

    async function load(from = rangeStart, to = rangeEnd) {
        loading = true;
        loadError = '';
        const [b, t, h] = await Promise.all([
            sb.from('s4_bookings')
                .select(`id, reference, starts_at, ends_at, status, total_cents, has_variable_price, gold_card, notes, cancel_reason, source, gaps, gaps_open,
                         client:s4_clients ( first_name, last_name, phone_e164, email, email_verified ),
                         staff_notes:s4_booking_notes ( id, body, created_at, author:s4_staff ( display_name ) ),
                         items:s4_booking_items ( name, price_cents, gold_card_applied, sort_order,
                             service:s4_services ( is_active, deleted_at, category:s4_categories ( is_active, deleted_at ) ) )`)
                .gte('starts_at', from).lt('starts_at', to)
                .order('starts_at'),
            sb.from('s4_time_off').select('id, starts_at, ends_at, reason').lt('starts_at', to).gt('ends_at', from),
            sb.from('s4_business_hours').select('weekday, is_open, opens_at, closes_at')
        ]);
        loading = false;
        if (b.error || t.error || h.error) { loadError = adminError(b.error || t.error || h.error); return; }
        bookings = b.data;
        timeOff = t.data;
        hours = Object.fromEntries(h.data.map(d => [d.weekday, d.is_open ? { open: toMinutes(d.opens_at), close: toMinutes(d.closes_at) } : null]));
    }

    // Reload whenever the visible range changes.
    $effect(() => { load(rangeStart, rangeEnd); });

    let visible = $derived(showCancelled ? bookings : bookings.filter(b => !isInactive(b)));
    let selected = $derived(bookings.find(b => b.id === selectedId) ?? null);
    let dayCount = $derived(visible.filter(b => !isInactive(b)).length);

    let detailEl = $state();
    async function select(b) {
        selectedId = b.id;
        await tick();
        // On narrow screens the panel sits below the calendar: bring it into view.
        if (window.matchMedia('(max-width: 63.99rem)').matches) detailEl?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    const closeDetail = () => selectedId = null;

    // New booking (phone or walk-in): show its day and open it.
    let createOpen = $state(false);

    // A short confirmation after deleting (the details panel has closed by then).
    let notice = $state('');
    function deleted() {
        notice = 'Booking deleted.';
        setTimeout(() => { if (notice === 'Booking deleted.') notice = ''; }, 4000);
    }
    async function created(id, day) {
        if (view !== 'day' || date !== day) await go('day', day);
        await load();
        const b = bookings.find(x => x.id === id);
        if (b) select(b);
    }
    const onkeydown = (e) => { if (e.key === 'Escape' && selectedId) closeDetail(); };
</script>

<svelte:window {onkeydown} />

<header class="toolbar">
    <div class="title">
        <div class="heading">
            <h1>Bookings</h1>
            <button type="button" class="primary with-icon" onclick={() => createOpen = true}>
                <i class="ph ph-plus" aria-hidden="true"></i> New booking
            </button>
        </div>
        <p class="range">
            {rangeTitle(view, date)}
            {#if !loading && view !== 'month'}<span class="muted">· {dayCount} {dayCount === 1 ? 'booking' : 'bookings'}</span>{/if}
        </p>
    </div>

    <div class="controls">
        <div class="nav" role="group" aria-label="Change {view}">
            <button type="button" class="icon-btn" aria-label="Previous {view}" onclick={() => step(-1)}>
                <i class="ph ph-caret-left" aria-hidden="true"></i>
            </button>
            <button type="button" class="today-btn" disabled={showsToday}
                onclick={() => go(view, today)}>Today</button>
            <button type="button" class="icon-btn" aria-label="Next {view}" onclick={() => step(1)}>
                <i class="ph ph-caret-right" aria-hidden="true"></i>
            </button>
            <label class="jump">
                <span class="sr-only">Go to date</span>
                <input type="date" value={date} onchange={(e) => e.currentTarget.value && go(view, e.currentTarget.value)} />
            </label>
        </div>

        <div class="views" role="tablist" aria-label="Calendar view">
            {#each VIEWS as v}
                <button type="button" role="tab" aria-selected={view === v.id} onclick={() => go(v.id, date)}>{v.label}</button>
            {/each}
        </div>

        <label class="toggle"><input type="checkbox" bind:checked={showCancelled} /> Show cancelled</label>
    </div>
</header>

<p class="notice" role="status">{#if notice}<i class="ph ph-check-circle" aria-hidden="true"></i> {notice}{/if}</p>

<div class="layout" class:has-detail={!!selected}>
    <section class="calendar" aria-label="{rangeTitle(view, date)} calendar" aria-busy={loading}>
        {#if loadError}
            <div class="panel"><p class="error">{loadError}</p><button type="button" class="secondary" onclick={() => load()}>Try again</button></div>
        {:else if view === 'month'}
            <MonthGrid month={date} bookings={visible} {timeOff} {hours} {today} ondayclick={openDay} />
        {:else}
            <DayTimeline {days} bookings={visible} {timeOff} {hours} {today}
                compact={view === 'week'} {selectedId}
                onselect={select}
                ondayclick={view === 'week' ? openDay : undefined} />
            {#if view === 'day' && !loading && visible.length === 0}
                {@const dayOff = blocksForDay(date, timeOff, hours)}
                <p class="empty muted">
                    {#if dayOff.fullDay}Day off{dayOff.reason ? `: ${dayOff.reason}` : ''}. No bookings.
                    {:else}No bookings{hours[new Date(`${date}T00:00:00Z`).getUTCDay()] ? '' : '. The salon is closed this day'}.{/if}
                </p>
            {/if}
        {/if}
    </section>

    {#if selected}
        <aside class="side" bind:this={detailEl} aria-label="Booking details">
            <BookingDetail booking={selected} {bookings} onchanged={() => load()} onclose={closeDetail} ondeleted={deleted} />
        </aside>
    {/if}
</div>

<BookingCreate bind:open={createOpen} day={date} {hours} oncreated={created} />

<style>
    .toolbar {
        align-items: flex-end;
        display: flex;
        flex-wrap: wrap;
        gap: 1rem 1.5rem;
        justify-content: space-between;
        margin-bottom: 1.25rem;
    }
    .heading {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem 1rem;
    }
    .range {
        color: var(--adm-text);
        font-weight: 600;
        margin-top: 0.25rem;
    }
    .range .muted {
        font-weight: 400;
    }
    .controls {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem 1rem;
    }
    .nav {
        align-items: center;
        display: flex;
        gap: 0.25rem;
    }
    .icon-btn,
    .today-btn,
    .views button {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border-strong);
        border-radius: 0.25rem;
        color: var(--adm-text);
        cursor: pointer;
        font-weight: 600;
        min-height: 2.75rem;
    }
    .icon-btn {
        display: grid;
        font-size: 1.125rem;
        place-items: center;
        width: 2.75rem;
    }
    .today-btn {
        padding: 0 0.875rem;
    }
    .today-btn:disabled {
        color: var(--adm-text-muted);
        cursor: default;
    }
    .icon-btn:hover,
    .today-btn:not(:disabled):hover,
    .views button:hover {
        border-color: var(--adm-text-muted);
    }
    .jump {
        margin-left: 0.25rem;
    }
    .views {
        display: flex;
    }
    .views button {
        border-radius: 0;
        margin-left: -1px;
        padding: 0 1rem;
    }
    .views button:first-child {
        border-radius: 0.25rem 0 0 0.25rem;
        margin-left: 0;
    }
    .views button:last-child {
        border-radius: 0 0.25rem 0.25rem 0;
    }
    .views button[aria-selected="true"] {
        background-color: var(--adm-inverse-bg);
        border-color: var(--adm-inverse-bg);
        color: var(--adm-inverse-text);
        position: relative;
    }
    .toggle {
        align-items: center;
        display: flex;
        font-size: 0.9375rem;
        gap: 0.5rem;
        min-height: 2.75rem;
    }

    .notice {
        align-items: center;
        color: var(--adm-success-text);
        display: flex;
        font-weight: 600;
        gap: 0.375rem;
        margin: -0.5rem 0 0.75rem;
        min-height: 1.5rem;
    }
    .notice:empty {
        margin: 0;
        min-height: 0;
    }
    .layout {
        display: grid;
        gap: 1.25rem;
        grid-template-columns: minmax(0, 1fr);
    }
    @media (min-width: 64rem) {
        .layout.has-detail {
            grid-template-columns: minmax(0, 1fr) 24rem;
        }
        .side {
            align-self: start;
            max-height: calc(100vh - 3rem);
            overflow-y: auto;
            position: sticky;
            top: 1.5rem;
        }
    }
    .calendar {
        min-width: 0;
    }
    .calendar[aria-busy="true"] {
        opacity: 0.6;
        transition: opacity 150ms ease;
    }
    .empty {
        margin-top: 0.75rem;
    }
</style>
