<script>
    /**
     * Day picker for the booking form: a button showing the chosen day that
     * opens a month calendar in a native <dialog>. Only bookable days (from
     * tomorrow, salon open, not blocked out) can be picked. Busy times are
     * loaded a month at a time as the client pages forward.
     */
    import { tick } from "svelte";
    import { getCartState } from "$lib/data/cart.svelte";
    import { formatLongDate, monthKey, salonToday, addDays, fromISODate } from "$lib/data/availability";

    let { value = '', onselect, loading = false } = $props();

    const cartState = getCartState();

    let dialog = $state();
    let grid = $state();
    let open = $state(false);
    let view = $state('');        // "YYYY-MM" being shown
    let focused = $state('');     // ISO day holding the roving tab stop
    let loadFailed = $state(false);

    const WEEKDAYS = [['Mon', 'Monday'], ['Tue', 'Tuesday'], ['Wed', 'Wednesday'], ['Thu', 'Thursday'],
                      ['Fri', 'Friday'], ['Sat', 'Saturday'], ['Sun', 'Sunday']];

    const today = $derived(salonToday(cartState.schedule));
    const firstMonth = $derived(cartState.firstMonth);
    const loaded = $derived(view ? cartState.isMonthLoaded(view) : false);
    const openDays = $derived(new Set(view ? cartState.openDaysIn(view) : []));

    const shiftMonth = (key, n) => {
        const [y, m] = key.split('-').map(Number);
        const d = new Date(y, m - 1 + n, 1);
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    };

    /** Six Monday-first weeks covering the month; days of other months are null. */
    const weeks = $derived.by(() => {
        if (!view) return [];
        const first = `${view}-01`;
        const lead = (fromISODate(first).getDay() + 6) % 7;
        const start = addDays(first, -lead);
        return Array.from({ length: 6 }, (_, w) =>
            Array.from({ length: 7 }, (_, d) => {
                const iso = addDays(start, w * 7 + d);
                return monthKey(iso) === view ? iso : null;
            })
        ).filter(week => week.some(Boolean));
    });

    const monthTitle = $derived(view
        ? fromISODate(`${view}-01`).toLocaleDateString('en-NZ', { month: 'long', year: 'numeric' })
        : '');

    const fullLabel = (iso) =>
        fromISODate(iso).toLocaleDateString('en-NZ', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

    const canPick = (iso) => loaded && openDays.has(iso);

    async function showMonth(key) {
        view = key < firstMonth ? firstMonth : key;
        loadFailed = false;
        const ok = await cartState.loadMonth(view);
        if (!ok) loadFailed = true;
    }

    /** First bookable day in the shown month, else its first day. */
    const anchorIn = () => [...openDays][0] || `${view}-01`;

    async function openPicker() {
        open = true;
        dialog.showModal();
        await showMonth(value ? monthKey(value) : firstMonth);
        focused = value && monthKey(value) === view ? value : anchorIn();
        await tick();
        focusDay(focused);
    }

    function close() {
        dialog?.close();
    }

    function onclose() {
        open = false;
    }

    function pick(iso) {
        if (!canPick(iso)) return;
        onselect?.(iso);
        close();
    }

    function focusDay(iso) {
        grid?.querySelector(`[data-iso="${iso}"]`)?.focus();
    }

    async function page(n) {
        await showMonth(shiftMonth(view, n));
        focused = anchorIn();
        await tick();
        // Keep focus inside the grid only when the keyboard is driving it.
        if (grid?.contains(document.activeElement)) focusDay(focused);
    }

    /** Arrow keys move by day/week, skipping days that can't be booked. */
    async function onkeydown(e) {
        const step = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }[e.key];
        let target = null;
        if (step) {
            let iso = focused;
            for (let i = 0; i < 62; i++) {
                iso = addDays(iso, step);
                if (monthKey(iso) < firstMonth) break;
                if (monthKey(iso) !== view) {
                    await showMonth(monthKey(iso));
                    if (!loaded) break;
                }
                if (canPick(iso)) { target = iso; break; }
            }
        } else if (e.key === 'Home' || e.key === 'End') {
            const week = weeks.find(w => w.includes(focused)) || [];
            const days = week.filter(d => d && canPick(d));
            target = e.key === 'Home' ? days[0] : days[days.length - 1];
        } else if (e.key === 'PageUp' || e.key === 'PageDown') {
            e.preventDefault();
            if (e.key === 'PageUp' && view <= firstMonth) return;
            await page(e.key === 'PageUp' ? -1 : 1);
            return;
        } else {
            return;
        }
        e.preventDefault();
        if (!target) return;
        focused = target;
        await tick();
        focusDay(target);
    }

    // Clicking the dimmed backdrop (the dialog element itself) closes it.
    function onclick(e) {
        if (e.target === dialog) close();
    }
</script>

<button type="button" class="trigger" onclick={openPicker} disabled={loading || !value}
    aria-haspopup="dialog">
    <i class="ph ph-calendar-blank" aria-hidden="true"></i>
    <span class="value">
        {#if loading}Loading days…{:else if value}{formatLongDate(value)}{:else}No days available{/if}
    </span>
    {#if value && !loading}<span class="change">Change<span class="visually-hidden"> day</span></span>{/if}
</button>

<dialog bind:this={dialog} aria-labelledby="date-picker-title" {onclose} {onclick}>
    {#if open}
        <div class="sheet">
            <header>
                <h2 id="date-picker-title">Choose a day</h2>
                <button type="button" class="icon" aria-label="Close" onclick={close}>
                    <i class="ph ph-x" aria-hidden="true"></i>
                </button>
            </header>

            <div class="month-bar">
                <button type="button" class="icon" aria-label="Previous month"
                    disabled={!view || view <= firstMonth} onclick={() => page(-1)}>
                    <i class="ph ph-caret-left" aria-hidden="true"></i>
                </button>
                <p class="month" aria-live="polite">{monthTitle}</p>
                <button type="button" class="icon" aria-label="Next month" disabled={!view} onclick={() => page(1)}>
                    <i class="ph ph-caret-right" aria-hidden="true"></i>
                </button>
            </div>

            <table role="grid" aria-labelledby="date-picker-title" bind:this={grid} {onkeydown}
                class:pending={!loaded}>
                <thead>
                    <tr>
                        {#each WEEKDAYS as [short, long]}
                            <th scope="col" abbr={long}>{short}</th>
                        {/each}
                    </tr>
                </thead>
                <tbody>
                    {#each weeks as week}
                        <tr>
                            {#each week as iso}
                                <td>
                                    {#if iso}
                                        {@const bookable = canPick(iso)}
                                        <button type="button" class="day" data-iso={iso}
                                            class:today={iso === today}
                                            aria-label="{fullLabel(iso)}{iso === today ? ', today' : ''}{bookable ? '' : ', unavailable'}"
                                            aria-pressed={iso === value}
                                            aria-disabled={!bookable}
                                            tabindex={iso === focused ? 0 : -1}
                                            onfocus={() => focused = iso}
                                            onclick={() => pick(iso)}>
                                            {fromISODate(iso).getDate()}
                                        </button>
                                    {/if}
                                </td>
                            {/each}
                        </tr>
                    {/each}
                </tbody>
            </table>

            <p class="foot" role="status">
                {#if loadFailed}
                    Couldn't load this month. Check your connection and try again.
                {:else if !loaded}
                    Loading free days…
                {:else if openDays.size === 0}
                    No free days this month. Try the next month.
                {:else}
                    Same-day bookings: call <a href="tel:+64221885240">022 188 5240</a>.
                {/if}
            </p>
        </div>
    {/if}
</dialog>

<style>
    .trigger {
        align-items: center;
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        color: var(--darkest);
        cursor: pointer;
        display: flex;
        gap: 0.75rem;
        min-height: 3.25rem;
        padding: 0.5rem 1rem;
        text-align: left;
        transition: border-color 150ms ease;
        width: 100%;
    }
    .trigger:hover:not(:disabled) {
        border-color: var(--dark);
    }
    .trigger:disabled {
        color: var(--dark);
        cursor: default;
    }
    .trigger > i {
        font-size: 1.375rem;
        flex: none;
    }
    .value {
        flex: 1;
        font: 600 1rem / 1.3 var(--font-default);
    }
    .change {
        color: var(--dark);
        font-size: 0.875rem;
        font-weight: 500;
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
        text-underline-offset: 3px;
    }

    dialog {
        background: transparent;
        border: 0;
        margin: auto;
        max-height: calc(100dvh - 2rem);
        max-width: none;
        padding: 0;
        width: min(24rem, 100vw - 2rem);
    }
    dialog::backdrop {
        background-color: rgba(27, 27, 27, 0.45);
    }
    dialog[open] {
        animation: rise 220ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes rise {
        from { opacity: 0; transform: translateY(12px); }
    }
    .sheet {
        background-color: var(--white);
        border-radius: 0.5rem;
        box-shadow: 0 12px 32px rgba(27, 27, 27, 0.22);
        color: var(--darkest);
        display: flex;
        flex-direction: column;
        max-height: calc(100dvh - 2rem);
        overflow-y: auto;
        padding: 0 1rem 1rem;
    }
    header {
        align-items: center;
        display: flex;
        justify-content: space-between;
        padding: 0.5rem 0 0.25rem 0.25rem;
    }
    h2 {
        font: 600 1.125rem / 1.3 var(--font-default);
    }
    .icon {
        border-radius: 50%;
        color: var(--dark);
        cursor: pointer;
        display: grid;
        font-size: 1.25rem;
        height: 2.75rem;
        place-items: center;
        width: 2.75rem;
    }
    .icon:hover:not(:disabled) {
        background-color: var(--lighter);
        color: var(--darkest);
    }
    .icon:disabled {
        color: var(--light);
        cursor: default;
    }
    .month-bar {
        align-items: center;
        border-top: 1px solid var(--light);
        display: flex;
        justify-content: space-between;
        padding-top: 0.5rem;
    }
    .month {
        font: 600 1rem var(--font-default);
    }

    table {
        border-collapse: collapse;
        table-layout: fixed;
        width: 100%;
    }
    table.pending {
        opacity: 0.55;
    }
    th {
        color: var(--dark);
        font-size: 0.75rem;
        font-weight: 500;
        letter-spacing: 0.04em;
        padding: 0.5rem 0 0.25rem;
        text-transform: uppercase;
    }
    td {
        padding: 0.125rem;
        text-align: center;
    }
    .day {
        aspect-ratio: 1;
        border: 1px solid transparent;
        border-radius: 0.25rem;
        color: var(--darkest);
        cursor: pointer;
        font: 600 1rem var(--font-default);
        font-variant-numeric: tabular-nums;
        min-height: 2.75rem;
        position: relative;
        transition: background-color 150ms ease, border-color 150ms ease;
        width: 100%;
    }
    .day:not([aria-disabled="true"]) {
        background-color: var(--white);
        border-color: var(--input-border);
    }
    .day:not([aria-disabled="true"]):hover {
        border-color: var(--dark);
    }
    .day[aria-disabled="true"] {
        color: var(--semi-dark);
        cursor: default;
        font-weight: 400;
    }
    .day.today::after {
        background-color: var(--color-accent-600);
        border-radius: 50%;
        bottom: 0.3125rem;
        content: "";
        height: 0.25rem;
        left: calc(50% - 0.125rem);
        position: absolute;
        width: 0.25rem;
    }
    .day[aria-pressed="true"] {
        background-color: var(--darkest);
        border-color: var(--darkest);
        color: var(--white);
    }

    .foot {
        color: var(--dark);
        font-size: 0.875rem;
        line-height: 1.5;
        margin-top: 0.75rem;
        min-height: 1.3125rem;
        text-align: center;
    }
    .foot a {
        color: var(--darkest);
        font-weight: 600;
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
        text-underline-offset: 3px;
        white-space: nowrap;
    }
    .visually-hidden {
        clip: rect(0 0 0 0);
        clip-path: inset(50%);
        height: 1px;
        overflow: hidden;
        position: absolute;
        white-space: nowrap;
        width: 1px;
    }

    /* Phones: bottom sheet. */
    @media (max-width: 40rem) {
        dialog {
            margin: auto 0 0;
            max-height: 92dvh;
            width: 100vw;
        }
        .sheet {
            border-radius: 0.75rem 0.75rem 0 0;
            max-height: 92dvh;
            padding-bottom: calc(1rem + env(safe-area-inset-bottom));
        }
    }
    @media (prefers-reduced-motion: reduce) {
        dialog[open] { animation: none; }
        .trigger, .day { transition: none; }
    }
</style>
