<script>
    import { page } from "$app/state";
    import { afterNavigate } from "$app/navigation";

    let mobileMenu = $state();
    const closeMenu = () => {
        if (mobileMenu?.matches(':popover-open')) mobileMenu.hidePopover();
    };

    afterNavigate(closeMenu);

    const sections = [
        { href: '/#services-section', label: 'Services & prices', short: 'Prices' },
        { href: '/#john-section', label: 'About John', short: 'About John' },
        { href: '/#reviews-section', label: 'Reviews', short: 'Reviews' },
        { href: '/#visit-section', label: 'Visit the salon', short: 'Visit' },
    ];
    let onBooking = $derived(page.url.pathname.startsWith('/book'));
</script>

<nav aria-label="Main">
    <ul class="sections">
        {#each sections as s}
            <li><a href={s.href}>{s.short}</a></li>
        {/each}
    </ul>

    <a href="tel:+64221885240" class="phone" class:full={onBooking} aria-label="Call John on 022 188 5240">
        <i class="ph ph-phone" aria-hidden="true"></i>
        <span class="number">022 188 5240</span>
    </a>

    {#if !onBooking}
        <a href="/book" class="book-link">Book Now</a>
    {/if}

    <button type="button" class="mobile-menu-btn" aria-label="Open menu" popovertarget="mobile-menu">
        <i class="ph ph-list" aria-hidden="true"></i>
    </button>
</nav>

<div class="mobile-menu" id="mobile-menu" popover bind:this={mobileMenu} aria-label="Menu">
    <button class="btn-mobile-menu-close" type="button" aria-label="Close menu"
        popovertarget="mobile-menu" popovertargetaction="hide">
        <i class="ph ph-x" aria-hidden="true"></i>
    </button>
    <a href="/" aria-current={page.url.pathname === '/' ? 'page' : undefined} onclick={closeMenu}>Home</a>
    {#each sections as s}
        <a href={s.href} onclick={closeMenu}>{s.label}</a>
    {/each}
    {#if !onBooking}
        <a href="/book" class="book" onclick={closeMenu}>Book with John</a>
    {/if}
    <a href="tel:+64221885240" class="call">
        <i class="ph ph-phone" aria-hidden="true"></i> Call 022 188 5240
    </a>
</div>

<style>
    nav {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    /* Section links: wide screens only; phones and tablets use the menu. */
    .sections {
        display: none;
        list-style: none;
    }
    .sections a {
        color: var(--color-off-white);
        display: inline-flex;
        align-items: center;
        font-weight: 500;
        min-height: 2.75rem;
        padding: 0.5rem 0.875rem;
        text-decoration: underline;
        text-decoration-color: transparent;
        text-decoration-thickness: 2px;
        text-underline-offset: 8px;
        transition: text-decoration-color 200ms ease;
    }
    .sections a:hover {
        text-decoration-color: var(--color-accent-400);
    }

    .phone {
        color: var(--color-off-white);
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        font-weight: 600;
        font-variant-numeric: tabular-nums;
        min-height: 2.75rem;
        min-width: 2.75rem;
        padding: 0.5rem;
        white-space: nowrap;
    }
    .phone > i {
        font-size: 1.375rem;
    }
    .phone:hover .number {
        text-decoration: underline;
        text-decoration-color: var(--color-accent-400);
        text-underline-offset: 6px;
    }
    /* Phones: icon only, except on the booking page where the Book button is hidden. */
    .phone > .number {
        display: none;
    }

    /* Same treatment as every other booking button on the site. */
    .book-link {
        background-color: var(--color-accent-400);
        color: var(--darkest);
        display: inline-flex;
        align-items: center;
        font-weight: 600;
        min-height: 2.75rem;
        padding: 0.5rem 1.125rem;
        margin-left: 0.25rem;
        white-space: nowrap;
        transition: background-color 150ms ease;
    }
    .book-link:hover {
        background-color: var(--color-accent-500);
    }

    .mobile-menu-btn {
        border-radius: 50%;
        color: var(--white);
        cursor: pointer;
        font-size: 1.5rem;
        height: 2.75rem;
        width: 2.75rem;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: background-color 200ms ease, color 200ms ease;
    }
    .mobile-menu-btn:hover {
        background-color: var(--color-accent-500);
        color: var(--darkest);
    }

    .phone.full > .number {
        display: inline;
    }
    @media (min-width: 40rem) {
        .phone > .number {
            display: inline;
        }
    }
    @media (min-width: 64rem) {
        .sections {
            display: flex;
            align-items: center;
            margin-right: 0.5rem;
        }
        .mobile-menu-btn {
            display: none;
        }
    }

    .mobile-menu {
        /* No `display` here: the popover's own hidden state must win, or the
           off-screen links stay in the keyboard tab order. */
        background-color: var(--darker);
        border: 0;
        border-top: 3px solid var(--color-accent-500);
        color: var(--white);
        flex-direction: column;
        height: 100dvh;
        inset: 0 0 0 auto;
        margin: 0;
        max-width: 100vw;
        padding-top: 4.5rem;
        width: min(100vw, 24rem);
        transform: translateX(100%);
        transition:
            transform 400ms cubic-bezier(0.16, 1, 0.3, 1),
            display 400ms allow-discrete,
            overlay 400ms allow-discrete;
    }
    .mobile-menu:popover-open {
        display: flex;
        transform: translateX(0);
    }
    @starting-style {
        .mobile-menu:popover-open {
            transform: translateX(100%);
        }
    }
    .mobile-menu::backdrop {
        background-color: var(--dark-bg-semi-light);
    }
    .mobile-menu > .btn-mobile-menu-close {
        position: absolute;
        right: 0.75rem;
        top: 0.75rem;
        height: 3rem;
        width: 3rem;
        border-radius: 50%;
        color: var(--off-white);
        cursor: pointer;
        font-size: 1.5rem;
        display: grid;
        place-items: center;
    }
    .mobile-menu > .btn-mobile-menu-close:hover {
        background-color: var(--dark);
    }
    .mobile-menu > a {
        color: var(--white);
        font-size: 1.0625rem;
        font-weight: 500;
        padding: 1rem 2rem;
        text-decoration: none;
        transition: background-color 150ms ease;
    }
    .mobile-menu > a:hover {
        background-color: var(--dark);
    }
    .mobile-menu > a[aria-current="page"] {
        color: var(--color-accent-400);
    }
    .mobile-menu > a.book {
        background-color: var(--color-accent-400);
        color: var(--darkest);
        font-weight: 600;
        margin: 1.5rem 2rem 0;
        padding: 1rem 1.25rem;
        text-align: center;
    }
    .mobile-menu > a.book:hover {
        background-color: var(--color-accent-500);
    }
    .mobile-menu > a.call {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        margin: 0.5rem 2rem 0;
        border: 1px solid rgba(250, 250, 249, 0.4);
        padding: 1rem 1.25rem;
    }
    @media (prefers-reduced-motion: reduce) {
        .mobile-menu {
            transition: none;
        }
    }
</style>
