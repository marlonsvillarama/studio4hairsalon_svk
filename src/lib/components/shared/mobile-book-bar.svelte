<script>
    // Thumb-reach booking for phones. Appears once the hero (and its own
    // Book button) has scrolled away.
    let scrollY = $state(0);
    let innerHeight = $state(800);
    let visible = $derived(scrollY > innerHeight * 0.75);
</script>

<svelte:window bind:scrollY bind:innerHeight />

<div class="mobile-book-bar" class:visible inert={!visible}>
    <a href="/book" class="book">Book with John <i class="ph ph-arrow-right" aria-hidden="true"></i></a>
    <a href="tel:+64221885240" class="call" aria-label="Call John on 022 188 5240">
        <i class="ph ph-phone" aria-hidden="true"></i>
    </a>
</div>

<style>
    .mobile-book-bar {
        position: fixed;
        inset: auto 0 0 0;
        z-index: 900;
        display: flex;
        gap: 0.5rem;
        padding: 0.625rem 1rem calc(0.625rem + env(safe-area-inset-bottom));
        background-color: var(--darkest);
        box-shadow: 0 -8px 20px -10px rgba(0, 0, 0, 0.5);
        transform: translateY(110%);
        transition: transform 350ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    .mobile-book-bar.visible {
        transform: translateY(0);
    }
    .book {
        flex: 1;
        background-color: var(--color-accent-400);
        color: var(--darkest);
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        font-weight: 600;
        min-height: 3rem;
    }
    .call {
        border: 1px solid rgba(250, 250, 249, 0.5);
        color: var(--color-off-white);
        display: grid;
        place-items: center;
        font-size: 1.375rem;
        width: 3rem;
    }
    @media (min-width: 40rem) {
        .mobile-book-bar {
            display: none;
        }
    }
    @media (prefers-reduced-motion: reduce) {
        .mobile-book-bar {
            transition: none;
        }
    }
</style>
