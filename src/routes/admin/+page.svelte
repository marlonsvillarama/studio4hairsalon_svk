<script>
    import { tick, onMount } from 'svelte';
    import { page } from '$app/state';
    import { goto } from '$app/navigation';
    import { getSupabase } from '$lib/supabase';
    import { salonInstant } from '$lib/data/availability';
    import {
        SALON_TZ, salonDay, adminError, addDays, addMonths, startOfWeek, monthGrid, rangeTitle, isInactive, blocksForDay, loadHours, everyMinute
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
    // Today in salon time; moves on at midnight without a reload.
    let today = $state(salonDay(Date.now()));
    onMount(() => everyMinute((t) => { const d = salonDay(t); if (d !== today) today = d; }));

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


    async function load(from = rangeStart, to = rangeEnd) {
        loading = true;
        loadError = '';
        const [b, t, h] = await Promise.all([
            sb.from('s4_bookings')
                .select(`id, reference, starts_at, ends_at, status, total_cents, has_variable_price, gold_card, notes, cancel_reason, source, gaps, gaps_open,
                         kind, booked_by:arranged_by_staff ( display_name ),
                         client:s4_clients ( id, first_name, last_name, phone_e164, email, email_verified,
                             arranged:arranged_by ( id, first_name, last_name, phone_e164, email ) ),
                         staff_notes:s4_booking_notes ( id, body, created_at, author:s4_staff ( display_name ) ),
                         items:s4_booking_items ( name, price_cents, gold_card_applied, sort_order,
                             service:s4_services ( is_active, deleted_at, category:s4_categories ( is_active, deleted_at ) ) )`)
                .gte('starts_at', from).lt('starts_at', to)
                .order('starts_at'),
            sb.from('s4_time_off').select('id, starts_at, ends_at, reason, kind').lt('starts_at', to).gt('ends_at', from),
            loadHours().then(data => ({ data }), error => ({ error }))
        ]);
        loading = false;
        if (b.error || t.error || h.error) { loadError = adminError(b.error || t.error || h.error); return; }
        bookings = b.data;
        timeOff = t.data;
        hours = h.data;
        // ?open=<id> (from New booking or a client's history) opens that booking once.
        const openId = page.url.searchParams.get('open');
        if (openId) {
            const params = new URLSearchParams(page.url.searchParams);
            params.delete('open');
            goto(`?${params}`, { replaceState: true, keepFocus: true, noScroll: true });
            const found = bookings.find(x => x.id === openId);
            if (found) select(found);
        }
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
    // Date title: opens the browser's date picker.
    let pickerEl = $state();
    function openPicker() {
        try { pickerEl.showPicker(); } catch { pickerEl.focus(); pickerEl.click(); }
    }

    // Filter menu: Esc, a click outside or tabbing away closes it.
    let filterOpen = $state(false);
    let filterEl = $state();
    let filterBtn = $state();
    let filterFirst = $state();
    $effect(() => { if (filterOpen) tick().then(() => filterFirst?.focus()); });
    const filterBlur = (e) => { if (!filterEl.contains(e.relatedTarget)) filterOpen = false; };
    const outside = (e) => { if (filterOpen && !filterEl.contains(e.target)) filterOpen = false; };

    const onkeydown = (e) => {
        if (e.key !== 'Escape') return;
        if (filterOpen) { filterOpen = false; filterBtn.focus(); return; }
        if (selectedId) closeDetail();
    };
</script>

<svelte:window {onkeydown} onpointerdown={outside} />

<header class="toolbar">
    <div class="heading">
        <h1>Bookings</h1>
        {#if !loading && view !== 'month'}<span class="count muted">{dayCount} {dayCount === 1 ? 'booking' : 'bookings'}</span>{/if}
        <button type="button" class="primary with-icon new-btn" title="New booking" onclick={() => createOpen = true}>
            <i class="ph ph-plus" aria-hidden="true"></i><span class="new-label">New booking</span>
        </button>
    </div>

    <div class="controls">
        <div class="nav" role="group" aria-label="Change {view}">
            <button type="button" class="icon-btn" aria-label="Previous {view}" title="Previous {view}" onclick={() => step(-1)}>
                <i class="ph ph-caret-left" aria-hidden="true"></i>
            </button>
            <span class="picker">
                <button type="button" class="range-btn" onclick={openPicker} aria-haspopup="dialog"
                    aria-label="{rangeTitle(view, date)}. Choose a date">
                    <span class="range-text long">{rangeTitle(view, date)}</span>
                    <span class="range-text short" aria-hidden="true">{rangeTitle(view, date, true)}</span>
                    <i class="ph ph-caret-down" aria-hidden="true"></i>
                </button>
                <input type="date" class="picker-input" tabindex="-1" aria-hidden="true" bind:this={pickerEl}
                    value={date} onchange={(e) => e.currentTarget.value && go(view, e.currentTarget.value)} />
            </span>
            <button type="button" class="icon-btn" aria-label="Next {view}" title="Next {view}" onclick={() => step(1)}>
                <i class="ph ph-caret-right" aria-hidden="true"></i>
            </button>
        </div>

        <div class="options">
            {#if !showsToday}
                <button type="button" class="today-btn" onclick={() => go(view, today)}>Today</button>
            {/if}

            <div class="views" role="tablist" aria-label="Calendar view">
                {#each VIEWS as v}
                    <button type="button" role="tab" aria-selected={view === v.id} onclick={() => go(v.id, date)}>{v.label}</button>
                {/each}
            </div>

            <div class="filter" bind:this={filterEl} onfocusout={filterBlur}>
                <button type="button" class="filter-btn" aria-expanded={filterOpen} aria-controls="booking-filter"
                    bind:this={filterBtn} onclick={() => filterOpen = !filterOpen}
                    aria-label={showCancelled ? 'Filter' : 'Filter (cancelled bookings hidden)'}>
                    <i class="ph ph-funnel-simple" aria-hidden="true"></i>
                    <span class="filter-label">Filter</span>
                    {#if !showCancelled}<span class="dot" aria-hidden="true"></span>{/if}
                </button>
                {#if filterOpen}
                    <div class="filter-panel" id="booking-filter" role="group" aria-label="Filter bookings">
                        <label class="toggle"><input type="checkbox" bind:checked={showCancelled} bind:this={filterFirst} /> Show cancelled</label>
                    </div>
                {/if}
            </div>
        </div>
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
        display: flex;
        flex-direction: column;
        gap: 1rem;
        margin-bottom: 1.25rem;
    }
    .heading {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 1rem;
    }
    .count {
        font-weight: 500;
    }
    .new-btn {
        margin-left: auto;
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
        min-width: 0;
    }
    .options {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 0.75rem;
        margin-left: auto;
    }
    .nav .icon-btn,
    .today-btn,
    .views button,
    .filter-btn {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border-strong);
        border-radius: 0.25rem;
        color: var(--adm-text);
        cursor: pointer;
        font-weight: 600;
        min-height: 2.75rem;
    }
    .nav .icon-btn {
        display: grid;
        font-size: 1.125rem;
        margin: 0;
        place-items: center;
        width: 2.75rem;
    }
    .today-btn {
        padding: 0 0.875rem;
    }
    .nav .icon-btn:hover,
    .today-btn:hover,
    .views button:hover,
    .filter-btn:hover {
        border-color: var(--adm-text-muted);
    }

    /* The range title doubles as the date picker. */
    .picker {
        min-width: 0;
        position: relative;
    }
    .range-btn {
        align-items: center;
        border-radius: 0.25rem;
        color: var(--adm-text);
        cursor: pointer;
        display: flex;
        font-size: 1.0625rem;
        font-weight: 600;
        gap: 0.375rem;
        max-width: 100%;
        min-height: 2.75rem;
        padding: 0 0.625rem;
        transition: background-color 150ms ease;
    }
    .range-btn:hover {
        background-color: var(--adm-accent-soft);
    }
    .range-text {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    .range-text.short {
        display: none;
    }
    .range-btn > i {
        color: var(--adm-text-muted);
        flex: none;
        font-size: 0.875rem;
    }
    /* Invisible, under the title, so the browser's picker opens beside it. */
    .picker-input {
        border: 0 !important;
        bottom: 0;
        height: 1px;
        left: 0;
        min-height: 0 !important;
        opacity: 0;
        padding: 0 !important;
        pointer-events: none;
        position: absolute;
        width: 100%;
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

    .filter {
        position: relative;
    }
    .filter-btn {
        align-items: center;
        display: inline-flex;
        gap: 0.5rem;
        padding: 0 0.875rem;
        position: relative;
    }
    .filter-btn > i {
        font-size: 1.125rem;
    }
    .filter-btn[aria-expanded="true"] {
        border-color: var(--adm-text-muted);
    }
    .dot {
        background-color: var(--adm-accent-line);
        border: 2px solid var(--adm-surface);
        border-radius: 50%;
        height: 0.75rem;
        position: absolute;
        right: -0.3125rem;
        top: -0.3125rem;
        width: 0.75rem;
    }
    .filter-panel {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border);
        border-radius: 0.5rem;
        box-shadow: var(--adm-shadow-overlay);
        padding: 0.25rem 1rem;
        position: absolute;
        right: 0;
        top: calc(100% + 0.375rem);
        white-space: nowrap;
        z-index: 15;
    }
    .toggle {
        align-items: center;
        cursor: pointer;
        display: flex;
        font-size: 0.9375rem;
        gap: 0.625rem;
        min-height: 2.75rem;
    }

    /* Phones: the date line on its own row, the options under it. */
    @media (max-width: 40rem) {
        .nav {
            flex: 1 1 100%;
        }
        .picker {
            flex: 1;
            display: flex;
            justify-content: center;
        }
        .options {
            margin-left: 0;
        }
        .views button {
            padding: 0 0.75rem;
        }
        .range-text.long {
            display: none;
        }
        .range-text.short {
            display: inline;
        }
        /* Icon only, so Today, the view switch and Filter share one row. */
        .filter-btn {
            justify-content: center;
            padding: 0;
            width: 2.75rem;
        }
        /* New booking: just the plus; the text stays for screen readers. */
        .new-btn {
            justify-content: center;
            padding: 0;
            width: 2.75rem;
        }
        .new-btn i {
            font-size: 1.25rem;
        }
        .filter-label,
        .new-label {
            clip-path: inset(50%);
            height: 1px;
            overflow: hidden;
            position: absolute;
            white-space: nowrap;
            width: 1px;
        }
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
