<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import { formatDuration, formatPrice } from "$lib/data/services";
    import { formatLongDate, formatTime } from "$lib/data/availability";

    let { heading = $bindable() } = $props();

    const cartState = getCartState();
    // Saved at the moment of booking, so it survives a reload.
    const booked = cartState.confirmation;
</script>

<section class="confirmed" aria-labelledby="confirmed-heading">
    <span class="mark" aria-hidden="true"><i class="ph ph-check"></i></span>
    <h2 id="confirmed-heading" tabindex="-1" bind:this={heading}>
        You're booked in, {booked.name}.
    </h2>
    <p class="lead">
        See you on <strong>{formatLongDate(booked.date)} at {formatTime(booked.time)}</strong>
        at 7 George Street, Palmerston North.
    </p>

    <dl>
        <div><dt>Services</dt><dd>{booked.services.join(', ')}</dd></div>
        <div><dt>Allow about</dt><dd>{formatDuration(booked.duration)}</dd></div>
        <div><dt>Total</dt><dd>{formatPrice(booked.total, booked.variablePrice)}</dd></div>
        {#if booked.email}<div><dt>Email</dt><dd>{booked.email}</dd></div>{/if}
        <div><dt>Reference</dt><dd class="ref">{booked.reference}</dd></div>
    </dl>

    <p class="note">
        Need to change or cancel? Call or text me on
        <a href="tel:+64221885240">022 188 5240</a>.
    </p>

    <a class="home" href="/" onclick={() => cartState.startOver()}>Back to the home page</a>
</section>

<style>
    .confirmed {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 1rem;
        padding-bottom: 4rem;
    }
    .mark {
        display: grid;
        place-items: center;
        height: 3.5rem;
        width: 3.5rem;
        border-radius: 50%;
        background-color: var(--color-accent-400);
        color: var(--darkest);
        font-size: 1.75rem;
        animation: pop 500ms cubic-bezier(0.16, 1, 0.3, 1) both;
    }
    @keyframes pop {
        from { transform: scale(0.6); opacity: 0; }
    }
    h2 {
        color: var(--darkest);
        font: 700 clamp(1.75rem, 5vw, 2.25rem) / 1.15 var(--font-serif);
        text-wrap: balance;
    }
    h2:focus {
        outline: none;
    }
    .lead {
        color: var(--charcoal);
        font-size: 1.125rem;
        line-height: 1.5;
        max-width: 34rem;
    }
    .lead strong {
        color: var(--darkest);
    }
    dl {
        border-block: 1px solid var(--light);
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        padding: 1rem 0;
        width: 100%;
    }
    dl > div {
        display: grid;
        grid-template-columns: 7.5rem 1fr;
        gap: 1rem;
    }
    dt {
        color: var(--dark);
        font-size: 0.9375rem;
    }
    dd {
        color: var(--darkest);
        font-weight: 500;
    }
    .ref {
        font-variant-numeric: tabular-nums;
        letter-spacing: 0.04em;
    }
    .note {
        color: var(--dark);
        line-height: 1.5;
    }
    .note a {
        color: var(--darkest);
        font-weight: 600;
        white-space: nowrap;
    }
    .home {
        background-color: var(--color-accent-400);
        color: var(--darkest);
        font-weight: 600;
        margin-top: 0.5rem;
        padding: 0.875rem 1.75rem;
        transition: background-color 150ms ease;
    }
    .home:hover {
        background-color: var(--color-accent-500);
    }
    @media (prefers-reduced-motion: reduce) {
        .mark { animation: none; }
    }
</style>
