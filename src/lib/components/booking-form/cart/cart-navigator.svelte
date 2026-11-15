<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import { formatPrice, formatDuration } from "$lib/data/services";

    const cartState = getCartState();

    let count = $derived(cartState.services.length);
    let submitting = $derived(cartState.status === 'submitting');
    // Only show "why can't I continue" after the client has tried, or when
    // there's nothing selected yet (so the greyed button never goes unexplained).
    let showBlocker = $derived(!!cartState.blocker && (cartState.showErrors || count === 0));

    const onPrimary = () => {
        if (cartState.isLastStep) cartState.submit();
        else cartState.next();
    };
</script>

<div class="bar">
    {#if count && cartState.currentStep.id === 'services'}
        <ul class="chips" aria-label="Your services">
            {#each cartState.selectedItems as s (s.id)}
                <li>
                    <span>{s.name}{#if cartState.usesGoldCard(s)}<span class="chip-gold">{" · "}Gold Card</span>{/if}</span>
                    <button type="button" onclick={() => cartState.removeService(s.id)}
                        aria-label="Remove {s.name}">
                        <i class="ph ph-x" aria-hidden="true"></i>
                    </button>
                </li>
            {/each}
        </ul>
    {/if}

    <div class="row">
        <div class="totals" aria-live="polite">
            {#if count}
                <strong>{formatPrice(cartState.totalPrice, cartState.hasVariablePrice)}</strong>
                <span>{count}&nbsp;{count === 1 ? 'service' : 'services'} · {formatDuration(cartState.totalDuration).replaceAll(' ', '\u00a0')}</span>
            {:else}
                <span>No services chosen yet</span>
            {/if}
        </div>

        <div class="actions">
            {#if cartState.step > 0}
                <button type="button" class="back" onclick={cartState.back} disabled={submitting}>
                    <i class="ph ph-arrow-left" aria-hidden="true"></i>
                    <span class="sr-only-narrow">Back</span>
                </button>
            {/if}
            <button type="button" class="primary"
                aria-disabled={!!cartState.blocker || submitting}
                aria-describedby={showBlocker ? 'nav-blocker' : undefined}
                onclick={onPrimary} disabled={submitting}>
                {#if submitting}
                    <span class="spinner" aria-hidden="true"></span> Booking…
                {:else if cartState.isLastStep}
                    Confirm booking
                {:else}
                    Continue <i class="ph ph-arrow-right" aria-hidden="true"></i>
                {/if}
            </button>
        </div>
    </div>

    {#if showBlocker}
        <p class="blocker" id="nav-blocker" role="status">{cartState.blocker}</p>
    {/if}
</div>

<style>
    .bar {
        position: sticky;
        bottom: 0;
        z-index: 10;
        background-color: var(--white);
        border-top: 1px solid var(--light);
        box-shadow: 0 -6px 16px -8px rgba(27, 27, 27, 0.18);
        margin: 0 -1rem;
        padding: 0.75rem 1rem calc(0.75rem + env(safe-area-inset-bottom));
        display: flex;
        flex-direction: column;
        gap: 0.625rem;
    }
    @media (min-width: 60rem) {
        .bar {
            margin: 0 -1.5rem;
            padding-inline: 1.5rem;
        }
    }

    .chips {
        list-style: none;
        display: flex;
        gap: 0.375rem;
        overflow-x: auto;
        scrollbar-width: none;
        /* Fade the right edge; end padding lets the last chip scroll clear of it. */
        mask-image: linear-gradient(to right, #000 calc(100% - 2rem), transparent);
        padding-right: 2rem;
        /* Room for the enlarged remove-button touch area. */
        padding-block: 0.5rem;
        margin-block: -0.5rem;
    }
    .chips > li {
        background-color: var(--color-accent-50);
        border: 1px solid var(--color-accent-300);
        border-radius: 999px;
        color: var(--darkest);
        display: flex;
        align-items: center;
        flex: none;
        font-size: 0.8125rem;
        font-weight: 500;
        padding: 0.25rem 0.25rem 0.25rem 0.75rem;
        white-space: nowrap;
    }
    .chip-gold {
        color: var(--color-accent-800);
        font-weight: 600;
    }
    .chips > li > span:only-child {
        padding-right: 0.5rem;
    }
    .chips > li > button {
        position: relative;
        border-radius: 50%;
        color: var(--dark);
        cursor: pointer;
        display: grid;
        place-items: center;
        height: 1.75rem;
        width: 1.75rem;
        margin-left: 0.125rem;
    }
    /* 28px visible, 44px to the touch. */
    .chips > li > button::before {
        content: "";
        position: absolute;
        inset: -0.5rem;
    }
    .chips > li > button:hover {
        background-color: var(--color-accent-200);
        color: var(--darkest);
    }

    .row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
    }
    .totals {
        display: flex;
        flex-direction: column;
        min-width: 0;
    }
    .totals > strong {
        color: var(--darkest);
        font-size: 1.125rem;
        font-variant-numeric: tabular-nums;
    }
    .totals > span {
        color: var(--dark);
        font-size: 0.875rem;
    }

    .actions {
        display: flex;
        gap: 0.5rem;
        flex: none;
    }
    .actions > button {
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        font: 600 1rem var(--font-default);
        min-height: 3rem;
        padding: 0 1.25rem;
        transition: background-color 150ms ease, border-color 150ms ease, color 150ms ease;
    }
    .back {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        color: var(--darkest);
    }
    .back:hover {
        border-color: var(--dark);
    }
    .primary {
        background-color: var(--color-accent-400);
        border: 1px solid var(--color-accent-400);
        color: var(--darkest);
        min-width: 9.5rem;
    }
    .primary:hover {
        background-color: var(--color-accent-500);
        border-color: var(--color-accent-500);
    }
    /* Still focusable and clickable (so it can explain itself), but reads as unavailable. */
    .primary[aria-disabled="true"] {
        background-color: var(--lighter);
        border-color: var(--input-border);
        color: var(--dark);
        cursor: not-allowed;
    }
    .actions > button:disabled {
        cursor: progress;
    }
    @media (max-width: 30rem) {
        .sr-only-narrow {
            position: absolute;
            width: 1px;
            height: 1px;
            overflow: hidden;
            clip-path: inset(50%);
            white-space: nowrap;
        }
        .back {
            padding: 0 1rem;
        }
    }

    .blocker {
        color: var(--dark);
        font-size: 0.875rem;
        text-align: end;
    }
    .spinner {
        height: 1rem;
        width: 1rem;
        border: 2px solid currentColor;
        border-right-color: transparent;
        border-radius: 50%;
        animation: spin 700ms linear infinite;
    }
    @keyframes spin {
        to { transform: rotate(1turn); }
    }
</style>
