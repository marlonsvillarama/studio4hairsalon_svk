<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import { formatDuration } from "$lib/data/services";
    import { fromISODate, formatTime } from "$lib/data/availability";
    import { onMount } from "svelte";
    import DatePicker from "./date-picker.svelte";

    const cartState = getCartState();

    let slots = $derived(cartState.date ? cartState.slotsFor(cartState.date) : []);

    // Someone else may have booked since the calendar was loaded. With no day
    // chosen yet, default to tomorrow, or the first open day after it.
    let finding = $state(!cartState.date);
    onMount(async () => {
        await cartState.refreshAvailability();
        if (!cartState.date) {
            const first = await cartState.firstOpenDay();
            if (first && !cartState.date) cartState.selectDate(first);
        }
        finding = false;
    });
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
    <DatePicker value={cartState.date} loading={finding} onselect={cartState.selectDate} />
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

    .time:hover {
        border-color: var(--dark);
    }
    .time[aria-pressed="true"] {
        background-color: var(--darkest);
        border-color: var(--darkest);
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
