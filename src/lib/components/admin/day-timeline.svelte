<script>
    import { onMount } from 'svelte';
    import { salonInstant, formatTime } from '$lib/data/availability';
    import { SALON_TZ, salonDay, showTime, dayLabel, weekdayOf, isInactive, STATUS_LABEL, blocksForDay, minutesToHHMM } from '$lib/admin';

    /**
     * days:       ["YYYY-MM-DD", …] — one column each (1 for Day view, 7 for Week view)
     * bookings:   s4_bookings rows (with client + items) inside those days
     * timeOff:    [{ starts_at, ends_at, reason }]
     * hours:      { [weekday]: { open, close } | null }   (minutes after midnight)
     * compact:    week view: shorter labels in blocks
     */
    let {
        days,
        bookings = [],
        timeOff = [],
        hours = {},
        compact = false,
        selectedId = null,
        today,
        onselect,
        ondayclick
    } = $props();

    const PX_PER_MIN = 1.6;          // 30 min ≈ 48px
    const MIN_BLOCK = 26;            // px: short bookings stay clickable

    const dayStart = (iso) => salonInstant(iso, '00:00', SALON_TZ).getTime();
    const minsOf = (iso, instant) => (new Date(instant).getTime() - dayStart(iso)) / 60_000;

    // Timeline spans opening hours across the visible days, widened to fit any
    // booking outside them, rounded out to whole hours.
    let range = $derived.by(() => {
        let start = Infinity, end = -Infinity;
        for (const iso of days) {
            const h = hours[weekdayOf(iso)];
            if (h) { start = Math.min(start, h.open); end = Math.max(end, h.close); }
        }
        if (!Number.isFinite(start)) { start = 9 * 60; end = 17 * 60; }
        for (const b of bookings) {
            const iso = salonDay(b.starts_at);
            if (!days.includes(iso)) continue;
            start = Math.min(start, minsOf(iso, b.starts_at));
            end = Math.max(end, minsOf(iso, b.ends_at));
        }
        start = Math.max(0, Math.floor(start / 60) * 60);
        end = Math.min(24 * 60, Math.ceil(end / 60) * 60);
        return { start, end };
    });
    let height = $derived((range.end - range.start) * PX_PER_MIN);
    let hourMarks = $derived(Array.from({ length: (range.end - range.start) / 60 + 1 }, (_, i) => range.start + i * 60));

    const y = (mins) => (mins - range.start) * PX_PER_MIN;

    // Lay out one day's bookings: overlapping bookings share the width in columns.
    function layout(iso) {
        const list = bookings
            .filter(b => salonDay(b.starts_at) === iso)
            .map(b => ({ b, s: minsOf(iso, b.starts_at), e: minsOf(iso, b.ends_at) }))
            .sort((a, z) => a.s - z.s || z.e - a.e);
        const placed = [];
        let cluster = [], clusterEnd = -Infinity;
        const flush = () => {
            const cols = [];
            for (const ev of cluster) {
                let c = cols.findIndex(end => end <= ev.s);
                if (c === -1) { c = cols.length; cols.push(ev.e); } else cols[c] = ev.e;
                ev.col = c;
            }
            for (const ev of cluster) { ev.cols = cols.length; placed.push(ev); }
            cluster = [];
        };
        for (const ev of list) {
            if (ev.s >= clusterEnd) { flush(); clusterEnd = -Infinity; }
            cluster.push(ev);
            clusterEnd = Math.max(clusterEnd, ev.e);
        }
        flush();
        return placed;
    }

    // Time off per visible day (see blocksForDay in $lib/admin.js).
    let off = $derived(Object.fromEntries(days.map(iso => [iso, blocksForDay(iso, timeOff, hours)])));
    // Partial blocks, clipped to the visible timeline.
    const bands = (iso) => off[iso].blocks
        .map(b => ({ ...b, s: Math.max(range.start, b.start), e: Math.min(range.end, b.end) }))
        .filter(b => b.e > b.s);
    const span = (b) => `${formatTime(minutesToHHMM(b.start))}–${formatTime(minutesToHHMM(b.end))}`;

    // "Now" line, refreshed every minute.
    let now = $state(Date.now());
    onMount(() => {
        const t = setInterval(() => now = Date.now(), 60_000);
        return () => clearInterval(t);
    });
    const nowMins = (iso) => (now - dayStart(iso)) / 60_000;

    const services = (b) => b.items.toSorted((a, z) => a.sort_order - z.sort_order).map(i => i.name).join(', ');
    const fullName = (b) => `${b.client?.first_name ?? ''} ${b.client?.last_name ?? ''}`.trim() || 'Client';
</script>

<div class="timeline" class:compact style="--cols: {days.length}">
    <!-- Column headers -->
    <div class="corner" aria-hidden="true"></div>
    {#each days as iso (iso)}
        {@const closed = !hours[weekdayOf(iso)]}
        {#if ondayclick}
            <button type="button" class="day-head" class:today={iso === today} onclick={() => ondayclick(iso)}
                aria-label="Open {dayLabel(iso)} in day view{off[iso].fullDay ? `, day off${off[iso].reason ? `: ${off[iso].reason}` : ''}` : ''}">
                <span>{dayLabel(iso)}</span>
                {#if off[iso].fullDay}
                    <span class="dayoff-tag" title={off[iso].reason || 'Day off'}><i class="ph ph-prohibit" aria-hidden="true"></i>Day off</span>
                {:else if closed}<span class="closed-tag">Closed</span>{/if}
            </button>
        {:else}
            <div class="day-head" class:today={iso === today}>
                <span>{dayLabel(iso)}</span>
                {#if off[iso].fullDay}
                    <span class="dayoff-tag" title={off[iso].reason || 'Day off'}><i class="ph ph-prohibit" aria-hidden="true"></i>Day off</span>
                {:else if closed}<span class="closed-tag">Closed</span>{/if}
            </div>
        {/if}
    {/each}

    <!-- Time gutter -->
    <div class="gutter" style="height: {height}px" aria-hidden="true">
        {#each hourMarks as m}
            <span class="hour" style="top: {y(m)}px">{showTime(salonInstant(days[0], `${String(Math.floor(m / 60)).padStart(2, '0')}:00`, SALON_TZ))}</span>
        {/each}
    </div>

    <!-- Day columns -->
    {#each days as iso (iso)}
        {@const h = hours[weekdayOf(iso)]}
        {@const placed = layout(iso)}
        <div class="col" class:closed={!h} style="height: {height}px">
            {#each hourMarks as m}
                <div class="line" style="top: {y(m)}px"></div>
                {#if m + 30 < range.end}<div class="line half" style="top: {y(m + 30)}px"></div>{/if}
            {/each}

            <!-- Outside opening hours -->
            {#if h}
                {#if h.open > range.start}<div class="shade" style="top: 0; height: {y(h.open)}px"></div>{/if}
                {#if h.close < range.end}<div class="shade" style="top: {y(h.close)}px; bottom: 0"></div>{/if}
            {/if}

            {#if off[iso].fullDay}
                <!-- A whole day off: hatch the column and say why, once. -->
                <div class="blocked dayoff" style="top: 0; bottom: 0" title={off[iso].reason ? `Day off: ${off[iso].reason}` : 'Day off'}>
                    <span class="dayoff-label">
                        <i class="ph ph-prohibit" aria-hidden="true"></i>
                        <span>Day off{#if off[iso].reason}<span class="why">{' · '}{off[iso].reason}</span>{/if}</span>
                    </span>
                </div>
            {:else}
                {#each bands(iso) as band}
                    <div class="blocked" style="top: {y(band.s)}px; height: {(band.e - band.s) * PX_PER_MIN}px"
                        title="Blocked {span(band)}{band.reason ? ` · ${band.reason}` : ''}">
                        <span class="blocked-label">
                            <strong>Blocked</strong>
                            <span class="when">{span(band)}</span>
                            {#if band.reason && !compact}<span class="why">{'· '}{band.reason}</span>{/if}
                        </span>
                    </div>
                {/each}
            {/if}

            {#each placed as ev (ev.b.id)}
                {@const b = ev.b}
                <button type="button" class="block s-{b.status}" class:inactive={isInactive(b)}
                    class:short={ev.e - ev.s < 45}
                    class:selected={selectedId === b.id}
                    style="top: {y(ev.s)}px; height: {Math.max((ev.e - ev.s) * PX_PER_MIN, MIN_BLOCK)}px;
                           left: calc({(ev.col / ev.cols) * 100}% + 2px); width: calc({100 / ev.cols}% - 4px)"
                    aria-label="{showTime(b.starts_at)} to {showTime(b.ends_at)}, {fullName(b)}, {services(b)}, {STATUS_LABEL[b.status]}"
                    aria-pressed={selectedId === b.id}
                    onclick={() => onselect?.(b)}>
                    <span class="t">{showTime(b.starts_at)}{#if !compact}–{showTime(b.ends_at)}{/if}</span>
                    <span class="n">{fullName(b)}</span>
                    {#if !compact}<span class="s">{services(b)}</span>{/if}
                </button>
            {/each}

            {#if iso === today && nowMins(iso) >= range.start && nowMins(iso) <= range.end}
                <div class="now" style="top: {y(nowMins(iso))}px" aria-hidden="true"></div>
            {/if}
        </div>
    {/each}
</div>

<style>
    .timeline {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        display: grid;
        grid-template-columns: 4.25rem repeat(var(--cols), minmax(var(--col-min, 0), 1fr));
        overflow-x: auto;
    }
    .timeline.compact {
        --col-min: 5.5rem;
    }
    .corner,
    .day-head {
        background-color: var(--adm-surface);
        border-bottom: 1px solid var(--adm-border);
        position: sticky;
        top: 0;
        z-index: 3;
    }
    .corner {
        left: 0;
        z-index: 4;
    }
    .day-head {
        align-items: center;
        border-left: 1px solid var(--adm-border);
        color: var(--adm-text);
        display: flex;
        flex-direction: column;
        font-weight: 600;
        gap: 0.125rem;
        justify-content: center;
        min-height: 3rem;
        padding: 0.375rem;
    }
    button.day-head {
        cursor: pointer;
    }
    button.day-head:hover {
        background-color: var(--adm-sunken);
    }
    .day-head.today span:first-child {
        background-color: var(--adm-inverse-bg);
        border-radius: 999px;
        color: var(--adm-inverse-text);
        padding: 0.125rem 0.625rem;
    }
    .dayoff-tag {
        align-items: center;
        background-color: var(--adm-border);
        border-radius: 999px;
        color: var(--adm-text-body);
        display: inline-flex;
        font-size: 0.75rem;
        font-weight: 600;
        gap: 0.25rem;
        padding: 0.0625rem 0.5rem;
    }
    .closed-tag {
        color: var(--adm-text-muted);
        font-size: 0.75rem;
        font-weight: 500;
    }
    .gutter {
        background-color: var(--adm-surface);
        left: 0;
        position: sticky;
        z-index: 2;
    }
    .hour {
        color: var(--adm-text-muted);
        font-size: 0.75rem;
        font-variant-numeric: tabular-nums;
        position: absolute;
        right: 0.5rem;
        transform: translateY(-50%);
        white-space: nowrap;
    }
    .hour:first-child {
        transform: none;
    }
    .col {
        border-left: 1px solid var(--adm-border);
        position: relative;
    }
    .col.closed {
        background-color: var(--adm-sunken);
    }
    .line {
        border-top: 1px solid var(--adm-border);
        left: 0;
        position: absolute;
        right: 0;
    }
    .line.half {
        border-top-style: dashed;
        opacity: 0.6;
    }
    .shade {
        background-color: var(--adm-sunken);
        left: 0;
        position: absolute;
        right: 0;
    }
    .blocked {
        background: repeating-linear-gradient(135deg, var(--adm-hatch-a) 0 6px, var(--adm-hatch-b) 6px 12px);
        border-left: 1px solid var(--adm-border-strong);
        border-right: 1px solid var(--adm-border-strong);
        color: var(--adm-text-muted);
        font-size: 0.75rem;
        font-weight: 600;
        left: 0;
        overflow: hidden;
        padding: 0.25rem 0.5rem;
        position: absolute;
        right: 0;
    }
    .blocked-label {
        display: flex;
        flex-wrap: wrap;
        gap: 0 0.375rem;
        line-height: 1.35;
    }
    .blocked-label strong {
        color: var(--adm-text-body);
    }
    .blocked-label .why {
        font-weight: 500;
    }
    .blocked.dayoff {
        align-items: flex-start;
        display: flex;
        justify-content: center;
        padding-top: 1.25rem;
    }
    .dayoff-label {
        align-items: center;
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border);
        border-radius: 999px;
        color: var(--adm-text-body);
        display: inline-flex;
        font-size: 0.8125rem;
        gap: 0.375rem;
        max-width: calc(100% - 0.5rem);
        padding: 0.25rem 0.75rem;
        position: sticky;
        top: 3.5rem;
    }
    .dayoff-label > span {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    .dayoff-label .why {
        font-weight: 500;
    }
    .compact .dayoff-label {
        font-size: 0.75rem;
        padding: 0.25rem 0.5rem;
    }

    .block {
        border-radius: 0.375rem;
        box-shadow: var(--adm-shadow-raised);
        cursor: pointer;
        display: flex;
        flex-direction: column;
        gap: 0.0625rem;
        overflow: hidden;
        padding: 0.25rem 0.5rem;
        position: absolute;
        text-align: left;
        z-index: 1;
        transition: box-shadow 150ms ease, transform 150ms ease;
    }
    .block:hover {
        box-shadow: var(--adm-shadow-hover);
        z-index: 2;
    }
    .block.selected {
        outline: 2px solid var(--adm-inverse-bg);
        outline-offset: 1px;
        z-index: 2;
    }
    .s-confirmed {
        background-color: var(--adm-accent-soft);
        border: 1px solid var(--adm-accent-line);
        color: var(--adm-text);
    }
    .s-completed {
        background-color: var(--adm-success-bg);
        border: 1px solid var(--adm-success-border);
        color: var(--adm-success-strong);
    }
    .s-cancelled,
    .s-no_show {
        background-color: var(--adm-sunken);
        border: 1px solid var(--adm-text-subtle);
        color: var(--adm-text-muted);
    }
    .inactive .n,
    .inactive .t {
        text-decoration: line-through;
    }
    .t {
        font-size: 0.75rem;
        font-variant-numeric: tabular-nums;
        font-weight: 600;
    }
    .n {
        font-size: 0.875rem;
        font-weight: 600;
        line-height: 1.2;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    .s {
        font-size: 0.75rem;
        line-height: 1.3;
        opacity: 0.85;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    /* Short visits (under 45 min): one line, so nothing is clipped. */
    .block.short {
        align-items: center;
        flex-direction: row;
        gap: 0.375rem;
        padding-block: 0;
        white-space: nowrap;
    }
    .block.short .t,
    .block.short .n {
        flex: none;
    }
    .block.short .s {
        flex: 1;
        min-width: 0;
    }
    .compact .block.short {
        align-items: flex-start;
        flex-direction: column;
        gap: 0;
        justify-content: center;
    }
    .compact .block {
        padding: 0.1875rem 0.375rem;
    }
    .compact .n {
        font-size: 0.8125rem;
    }

    .now {
        border-top: 2px solid var(--adm-now);
        left: -1px;
        pointer-events: none;
        position: absolute;
        right: 0;
        z-index: 3;
    }
    .now::before {
        background-color: var(--adm-now);
        border-radius: 50%;
        content: "";
        height: 0.625rem;
        left: -0.3125rem;
        position: absolute;
        top: -0.375rem;
        width: 0.625rem;
    }
</style>
