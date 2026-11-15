<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import { formatDuration } from "$lib/data/services";
    import { fromISODate, formatTime } from "$lib/data/availability";
    import { onMount } from "svelte";

    const cartState = getCartState();

    let days = $derived(cartState.openDays);
    let slots = $derived(cartState.date ? cartState.slotsFor(cartState.date) : []);

    // Someone else may have booked since the calendar was loaded.
    onMount(() => { cartState.refreshAvailability(); });
    let morning = $derived(slots.filter(t => t < '12:00'));
    let afternoon = $derived(slots.filter(t => t >= '12:00'));

    const dayParts = (iso) => {
        const d = fromISODate(iso);
        return {
            weekday: d.toLocaleDateString('en-NZ', { weekday: 'short' }),
            day: d.getDate(),
            month: d.toLocaleDateString('en-NZ', { month: 'short' }),
            full: d.toLocaleDateString('en-NZ', { weekday: 'long', day: 'numeric', month: 'long' })
        };
    };
</script>

<p class="hint">
    Your visit takes about <strong>{formatDuration(cartState.totalDuration)}</strong>.
    Only times that fit the whole visit before closing are shown.
</p>

<fieldset>
    <legend>Day</legend>
    <div class="days">
        {#each days as iso (iso)}
            {@const p = dayParts(iso)}
            <button type="button" class="day" aria-pressed={cartState.date === iso}
                aria-label={p.full} onclick={() => cartState.selectDate(iso)}>
                <span class="weekday">{p.weekday}</span>
                <span class="num">{p.day}</span>
                <span class="month">{p.month}</span>
            </button>
        {/each}
    </div>
</fieldset>

{#if cartState.timeNotice}
    <p class="notice" role="status">
        <i class="ph ph-info" aria-hidden="true"></i>{cartState.timeNotice}
    </p>
{/if}

{#if cartState.date}
    <fieldset>
        <legend>Time on {dayParts(cartState.date).full}</legend>
        {#if slots.length === 0}
            <p class="empty">
                No free times left that day for a visit this long. Try another day, or call me on
                <a href="tel:+64221885240">022 188 5240</a>.
            </p>
        {:else}
            {#each [['Morning', morning], ['Afternoon', afternoon]] as [label, group]}
                {#if group.length}
                    <div class="time-group" role="group" aria-labelledby="times-{label}">
                        <span class="group-label" id="times-{label}">{label}</span>
                        <div class="times">
                            {#each group as t (t)}
                                <button type="button" class="time" aria-pressed={cartState.time === t}
                                    onclick={() => cartState.selectTime(t)}>{formatTime(t)}</button>
                            {/each}
                        </div>
                    </div>
                {/if}
            {/each}
        {/if}
    </fieldset>
{/if}

{#if cartState.services.length > 1}
    <p class="aside">
        Would you rather split these services over separate visits?
        Call me on <a href="tel:+64221885240">022 188 5240</a> and we'll work out the best times.
    </p>
{/if}

<style>
    .hint {
        color: var(--dark);
        font-size: 0.9375rem;
        line-height: 1.5;
    }
    .hint strong {
        color: var(--darkest);
    }
    fieldset {
        border: 0;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        min-width: 0;
    }
    legend {
        color: var(--darkest);
        font: 600 1rem var(--font-default);
        margin-bottom: 0.75rem;
    }

    .days {
        display: grid;
        grid-auto-flow: column;
        grid-auto-columns: 4.25rem;
        gap: 0.5rem;
        overflow-x: auto;
        overscroll-behavior-x: contain;
        padding: 0.25rem 0.25rem 0.75rem;
        margin: -0.25rem -0.25rem 0;
        scroll-snap-type: x proximity;
        /* Fade the right edge so it's clear the strip scrolls. */
        mask-image: linear-gradient(to right, #000 calc(100% - 2.5rem), transparent);
    }
    .day {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        cursor: pointer;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.125rem;
        padding: 0.625rem 0.25rem;
        scroll-snap-align: start;
        transition: background-color 150ms ease, border-color 150ms ease;
    }
    .day:hover,
    .time:hover {
        border-color: var(--dark);
    }
    .day .weekday,
    .day .month {
        color: var(--dark);
        font-size: 0.75rem;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.04em;
    }
    .day .num {
        color: var(--darkest);
        font: 600 1.375rem / 1.2 var(--font-default);
        font-variant-numeric: tabular-nums;
    }
    .day[aria-pressed="true"],
    .time[aria-pressed="true"] {
        background-color: var(--darkest);
        border-color: var(--darkest);
    }
    .day[aria-pressed="true"] span,
    .time[aria-pressed="true"] {
        color: var(--white);
    }

    .notice {
        background-color: var(--color-accent-50);
        border: 1px solid var(--color-accent-600);
        border-radius: 0.25rem;
        color: var(--darkest);
        display: flex;
        gap: 0.5rem;
        line-height: 1.5;
        padding: 0.75rem 1rem;
    }
    .notice > i {
        color: var(--color-accent-800);
        flex: none;
        font-size: 1.25rem;
        margin-top: 0.0625rem;
    }
    .time-group {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .group-label {
        color: var(--dark);
        font-size: 0.875rem;
        font-weight: 500;
    }
    .times {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(6rem, 1fr));
        gap: 0.5rem;
        margin-bottom: 0.5rem;
    }
    .time {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        color: var(--darkest);
        cursor: pointer;
        font: 500 0.9375rem var(--font-default);
        font-variant-numeric: tabular-nums;
        min-height: 2.75rem;
        transition: background-color 150ms ease, border-color 150ms ease;
    }

    .empty,
    .aside {
        color: var(--dark);
        font-size: 0.9375rem;
        line-height: 1.5;
    }
    .aside {
        border-top: 1px solid var(--light);
        padding-top: 1rem;
    }
    a {
        color: var(--darkest);
        font-weight: 600;
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
        text-underline-offset: 3px;
        white-space: nowrap;
    }
</style>
