<script>
    import { salonDay, salonTime, monthGrid, weekdayOf, isInactive, blocksForDay, minutesToHHMM } from '$lib/admin';

    /** month: any "YYYY-MM-DD" inside the month to show. */
    let { month, bookings = [], timeOff = [], hours = {}, today, ondayclick } = $props();

    const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    let cells = $derived(monthGrid(month));
    let byDay = $derived.by(() => {
        const map = new Map();
        for (const b of bookings) {
            const key = salonDay(b.starts_at);
            if (!map.has(key)) map.set(key, []);
            map.get(key).push(b);
        }
        for (const list of map.values()) list.sort((a, z) => a.starts_at.localeCompare(z.starts_at));
        return map;
    });

    // Time off per cell (see blocksForDay in $lib/admin.js).
    let off = $derived(Object.fromEntries(cells.map(iso => [iso, blocksForDay(iso, timeOff, hours)])));
    const span = (b) => `${minutesToHHMM(b.start)}–${minutesToHHMM(b.end)}`;
    const offLabel = (o) => o.fullDay
        ? `, day off${o.reason ? `: ${o.reason}` : ''}`
        : o.blocks.length ? `, blocked ${o.blocks.map(b => span(b).replace('–', ' to ')).join(' and ')}` : '';

    const inMonth = (iso) => iso.slice(0, 7) === month.slice(0, 7);
    const dayNum = (iso) => Number(iso.slice(8));
    const label = (iso) => new Intl.DateTimeFormat('en-NZ', { timeZone: 'UTC', weekday: 'long', day: 'numeric', month: 'long' })
        .format(new Date(`${iso}T00:00:00Z`));
</script>

<div class="month">
    {#each WEEKDAYS as w}<div class="wd" aria-hidden="true">{w}</div>{/each}
    {#each cells as iso (iso)}
        {@const list = byDay.get(iso) ?? []}
        {@const active = list.filter(b => !isInactive(b))}
        {@const o = off[iso]}
        {@const closed = !hours[weekdayOf(iso)] && !o.fullDay}
        <button type="button" class="cell" class:other={!inMonth(iso)} class:today={iso === today} class:closed
            class:dayoff={o.fullDay}
            aria-label="{label(iso)}: {active.length} {active.length === 1 ? 'booking' : 'bookings'}{closed ? ', closed' : ''}{offLabel(o)}. Open in day view."
            onclick={() => ondayclick?.(iso)}>
            <span class="top">
                <span class="num">{dayNum(iso)}</span>
                {#if o.fullDay || o.blocks.length}<i class="ph ph-prohibit off-icon" aria-hidden="true"></i>{/if}
                {#if active.length}<span class="count">{active.length}</span>{/if}
            </span>
            <span class="list" aria-hidden="true">
                {#if o.fullDay}
                    <span class="off-line"><strong>Day off</strong>{#if o.reason}{' · '}{o.reason}{/if}</span>
                {:else}
                    {#each o.blocks as b}
                        <span class="off-line"><strong>{span(b)}</strong>{' '}Blocked{#if b.reason}{' · '}{b.reason}{/if}</span>
                    {/each}
                {/if}
                {#each list.slice(0, 3) as b (b.id)}
                    <span class="item" class:inactive={isInactive(b)}>
                        <span class="t">{salonTime(b.starts_at)}</span> {b.client?.first_name ?? 'Client'}
                    </span>
                {/each}
                {#if list.length > 3}<span class="more">+{list.length - 3} more</span>{/if}
            </span>
        </button>
    {/each}
</div>

<style>
    .month {
        background-color: var(--adm-border);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        display: grid;
        gap: 1px;
        grid-template-columns: repeat(7, minmax(0, 1fr));
        overflow: hidden;
    }
    .wd {
        background-color: var(--adm-surface);
        color: var(--adm-text-muted);
        font-size: 0.75rem;
        font-weight: 600;
        letter-spacing: 0.04em;
        padding: 0.5rem;
        text-align: center;
        text-transform: uppercase;
    }
    .cell {
        align-items: stretch;
        background-color: var(--adm-surface);
        cursor: pointer;
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        min-height: 7.5rem;
        padding: 0.375rem 0.5rem 0.5rem;
        text-align: left;
        transition: background-color 150ms ease;
    }
    .cell:hover {
        background-color: var(--adm-selected-bg);
    }
    .cell.closed {
        background-color: var(--adm-sunken);
    }
    .cell.other {
        background-color: var(--adm-sunken);
        color: var(--adm-text-subtle);
    }
    .cell.other .item {
        opacity: 0.6;
    }
    /* A whole day off: hatched, like blocked time in the day and week views. */
    .cell.dayoff {
        background: repeating-linear-gradient(135deg, var(--adm-hatch-a) 0 6px, var(--adm-hatch-b) 6px 12px);
    }
    .cell.dayoff:hover {
        background: repeating-linear-gradient(135deg, var(--adm-accent-soft) 0 6px, var(--adm-selected-bg) 6px 12px);
    }
    .off-icon {
        color: var(--adm-text-muted);
        font-size: 0.9375rem;
        margin-left: auto;
        margin-right: 0.25rem;
    }
    .off-line {
        color: var(--adm-text-body);
        font-size: 0.75rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    .dayoff .off-line {
        background-color: var(--adm-surface);
        border-radius: 0.25rem;
        padding: 0 0.25rem;
    }
    .off-line strong {
        font-variant-numeric: tabular-nums;
        font-weight: 600;
    }
    .top {
        align-items: center;
        display: flex;
        justify-content: space-between;
    }
    .num {
        font-variant-numeric: tabular-nums;
        font-weight: 600;
        line-height: 1;
        padding: 0.25rem 0.375rem;
    }
    .today .num {
        background-color: var(--adm-inverse-bg);
        border-radius: 999px;
        color: var(--adm-inverse-text);
    }
    .count {
        background-color: var(--adm-primary-bg);
        border-radius: 999px;
        color: var(--adm-primary-text);
        font-size: 0.75rem;
        font-variant-numeric: tabular-nums;
        font-weight: 700;
        min-width: 1.5rem;
        padding: 0.125rem 0.4375rem;
        text-align: center;
    }
    .list {
        display: flex;
        flex-direction: column;
        gap: 0.125rem;
        min-width: 0;
    }
    .item {
        color: var(--adm-text);
        font-size: 0.8125rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    .item.inactive {
        color: var(--adm-text-muted);
        text-decoration: line-through;
    }
    .t {
        font-variant-numeric: tabular-nums;
        font-weight: 600;
    }
    .more {
        color: var(--adm-text-muted);
        font-size: 0.75rem;
        font-weight: 600;
    }
    @media (max-width: 40rem) {
        .cell {
            min-height: 4rem;
            padding: 0.25rem;
        }
        .list {
            display: none;
        }
        /* A whole day off: hatched, like blocked time in the day and week views. */
    .cell.dayoff {
        background: repeating-linear-gradient(135deg, var(--adm-hatch-a) 0 6px, var(--adm-hatch-b) 6px 12px);
    }
    .cell.dayoff:hover {
        background: repeating-linear-gradient(135deg, var(--adm-accent-soft) 0 6px, var(--adm-selected-bg) 6px 12px);
    }
    .off-icon {
        color: var(--adm-text-muted);
        font-size: 0.9375rem;
        margin-left: auto;
        margin-right: 0.25rem;
    }
    .off-line {
        color: var(--adm-text-body);
        font-size: 0.75rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    .dayoff .off-line {
        background-color: var(--adm-surface);
        border-radius: 0.25rem;
        padding: 0 0.25rem;
    }
    .off-line strong {
        font-variant-numeric: tabular-nums;
        font-weight: 600;
    }
    .top {
            align-items: flex-start;
            flex-direction: column;
            gap: 0.25rem;
        }
    }
</style>
