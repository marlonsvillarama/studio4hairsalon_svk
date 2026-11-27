<script>
    /**
     * Placeholder rows shown while a table's first page loads, laid out like
     * .admin-table (a table on wide screens, cards on narrow ones), so the
     * page doesn't jump when the rows arrive. Flat bars: no shimmer.
     */
    let { rows = 6, columns = 4, label = 'Loading…' } = $props();
    // Steady, varied widths (no randomness, so it doesn't flicker on re-render).
    const WIDTHS = [62, 44, 30, 52, 38, 70, 26, 48];
    const w = (r, c) => c === 0 ? WIDTHS[r % WIDTHS.length] : WIDTHS[(r * 3 + c * 5) % WIDTHS.length];
</script>

<div class="skeleton" aria-busy="true">
    <span class="sr-only" role="status">{label}</span>
    {#each { length: rows } as _, r}
        <div class="row" aria-hidden="true" style="--cols: {columns}">
            {#each { length: columns } as _, c}
                <span class="cell" class:lead={c === 0}><span class="bar" style="width: {w(r, c)}%"></span></span>
            {/each}
        </div>
    {/each}
</div>

<style>
    .skeleton {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
    }
    .row {
        align-items: center;
        border-bottom: 1px solid var(--adm-border);
        display: grid;
        gap: 1.5rem;
        grid-template-columns: 2fr repeat(calc(var(--cols) - 1), 1fr);
        min-height: 3.25rem;
        padding: 0 0.75rem;
    }
    .row:last-child {
        border-bottom: 0;
    }
    .bar {
        background-color: var(--adm-sunken);
        border-radius: 0.25rem;
        display: block;
        height: 0.75rem;
    }
    .lead .bar {
        background-color: var(--adm-border);
        height: 0.875rem;
    }
    @media (max-width: 55.99rem) {
        .skeleton {
            background: transparent;
            border: 0;
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }
        .row {
            background-color: var(--adm-surface);
            border: 1px solid var(--adm-border);
            border-radius: 0.375rem;
            gap: 0.625rem;
            grid-template-columns: 1fr;
            padding: 0.875rem 1rem;
        }
        .row:last-child {
            border-bottom: 1px solid var(--adm-border);
        }
        .cell:nth-child(n + 4) {
            display: none;
        }
    }
</style>
