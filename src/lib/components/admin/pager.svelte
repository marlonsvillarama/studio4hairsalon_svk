<script>
    /**
     * Pages for a server-paged table: "Showing 26–50 of 1,380", previous/next,
     * a page jump and the rows-per-page choice (10 / 25 / 50).
     */
    import { PAGE_SIZES } from '$lib/admin';

    let { page = 1, size = 20, total = 0, label = 'rows', onpage, onsize } = $props();
    const uid = `pg-${Math.random().toString(36).slice(2, 8)}`;

    let pages = $derived(Math.max(1, Math.ceil(total / size)));
    let from = $derived(total ? (page - 1) * size + 1 : 0);
    let to = $derived(Math.min(total, page * size));
    const n = new Intl.NumberFormat('en-NZ');
</script>

<nav class="pager" aria-label="Pages of {label}">
    <p class="range" aria-live="polite">
        {#if total}Showing <strong>{n.format(from)}–{n.format(to)}</strong> of <strong>{n.format(total)}</strong>{:else}No {label}{/if}
    </p>

    <label class="size">
        <span>Rows per page</span>
        <select value={size} onchange={(e) => onsize?.(Number(e.currentTarget.value))}>
            {#each PAGE_SIZES as s}<option value={s}>{s}</option>{/each}
        </select>
    </label>

    {#if pages > 1}
        <div class="moves">
            <button type="button" class="step" disabled={page <= 1} onclick={() => onpage?.(page - 1)} aria-label="Previous page">
                <i class="ph ph-caret-left" aria-hidden="true"></i><span class="word">Previous</span>
            </button>
            <label class="jump">
                <span class="sr-only">Page</span>
                <select id="{uid}-page" value={page} onchange={(e) => onpage?.(Number(e.currentTarget.value))}>
                    {#each Array.from({ length: pages }, (_, i) => i + 1) as p}<option value={p}>Page {p} of {pages}</option>{/each}
                </select>
            </label>
            <button type="button" class="step" disabled={page >= pages} onclick={() => onpage?.(page + 1)} aria-label="Next page">
                <span class="word">Next</span><i class="ph ph-caret-right" aria-hidden="true"></i>
            </button>
        </div>
    {/if}
</nav>

<style>
    .pager {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.625rem 1.25rem;
        justify-content: space-between;
        margin: 0.875rem 0 0;
    }
    .range {
        color: var(--adm-text-muted);
        font-variant-numeric: tabular-nums;
    }
    .range strong {
        color: var(--adm-text);
    }
    .size,
    .moves {
        align-items: center;
        display: flex;
        gap: 0.5rem;
    }
    .size span {
        color: var(--adm-text-muted);
        font-size: 0.9375rem;
    }
    .moves {
        margin-left: auto;
    }
    .step {
        align-items: center;
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border-strong);
        border-radius: 0.25rem;
        color: var(--adm-text);
        cursor: pointer;
        display: inline-flex;
        font-weight: 600;
        gap: 0.25rem;
        min-height: 2.75rem;
        padding: 0 0.75rem;
    }
    .step:hover:not(:disabled) {
        border-color: var(--adm-text-muted);
    }
    .step:disabled {
        color: var(--adm-text-muted);
        cursor: default;
        opacity: 0.55;
    }
    @media (max-width: 40rem) {
        .moves {
            margin-left: 0;
            width: 100%;
        }
        .jump {
            flex: 1;
        }
        .jump select {
            width: 100%;
        }
        .word {
            display: none;
        }
        .step {
            justify-content: center;
            width: 2.75rem;
        }
    }
</style>
