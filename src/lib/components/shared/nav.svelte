<script>
    import { page } from "$app/state";
    import { afterNavigate } from "$app/navigation";

    let scrollY = $state(0);
    let mobileMenu = $state();
    const closeMobileMenu = () => {
        mobileMenu.hide();
    }

    afterNavigate(() => {
        if (mobileMenu && mobileMenu.matches(':popover-open')) {
            mobileMenu.hidePopover();
        }
    })
</script>

<ul class="menu">
    <li><a href="/services" title="Services">Services</a></li>
    <li><a href="/gallery" title="Gallery">Gallery</a></li>
    <li><a href="/reviews" title="Reviews">Reviews</a></li>
</ul>
<button type="button" class="mobile-menu-btn" title="Menu" popovertarget="mobile-menu">
    <i class="ph ph-list"></i>
</button>
<div class="mobile-menu" id="mobile-menu" popover bind:this={mobileMenu}>
    <button class="btn-mobile-menu-close" type="button" popovertarget="mobile-menu" popovertargetaction="hide">
        <i class="ph ph-x"></i>
    </button>
    <a href="/" title="Home"
        class:active={page.url.pathname === '/'}
        >Home</a>
    <a href="/services" title="Expertise"
        data-sveltekit-reload
        class:active={page.url.pathname.startsWith('/services')}
        >Services</a>
    <a href="/gallery" title="Gallery"
        data-sveltekit-reload
        class:active={page.url.pathname.startsWith('/gallery')}
        >Gallery</a>
    <a href="/reviews" title="Reviews"
        data-sveltekit-reload
        class:active={page.url.pathname.startsWith('/reviews')}
        >Reviews</a>
    <a href="/book" title="Book Now" class="book"
        data-sveltekit-reload
        // class:active={page.url.pathname.startsWith('/book')}
        >Book Now</a>
</div>

<style>
    ul.menu {
        list-style: none;
        display: none;
    }
    ul.menu > li > a {
        color: var(--white);
        font-weight: 500;
        padding: 0.75rem 1.25rem;
        border-top: 3px solid transparent;
        /* border-bottom: 3px solid transparent; */
        transition: background-color 200ms ease, color 200ms ease, border-color 200ms ease;
    }
    ul.menu > li > a:hover {
        /* background: linear-gradient(to bottom, var(--dark-bg-lightest) 0%, var(--dark-bg-pale) 100%); */
        background-color: var(--dark-bg-pale);
        border-color: var(--color-accent-500);
        /* color: var(--darkest); */
    }
    .mobile-menu-btn {
        border-radius: 50%;
        color: var(--white);
        cursor: pointer;
        font-size: 1.5rem;
        height: 3rem;
        transition: background-color 200ms ease, color 200ms ease;
        width: 3rem;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    .mobile-menu-btn:hover {
        background-color: var(--color-accent-500);
        color: var(--darkest);
    }
    .mobile-menu {
        inset: 0;
        background-color: var(--darkest);
        background-color: var(--darker);
        /* border: 0; */
        border-top: 3px solid var(--color-accent-500);
        color: var(--white);
        transform: translateX(100%);
        transition: transform 400ms, overlay 400ms ease-out;
        display: block;
        width: 100vw;
        /* max-width: 20rem; */
        inset: unset;
        right: 0;
        top: 0;
        height: 100dvh;
        display: flex;
        flex-direction: column;
        padding-top: 1rem;

        /* position: absolute; */
        /* z-index: 9999; */
        /* inset: 0; */
    }
    .mobile-menu:popover-open {
        transform: translateX(0);
    }
    .mobile-menu::backdrop {
        background-color: var(--dark-bg-semi-light);
    }
    .mobile-menu > .btn-mobile-menu-close {
        position: absolute;
        right: 0rem;
        top: 0;
        border: 0;
        background-color: transparent;
        outline: 0;
        color: var(--off-white);
        text-align: right;
        padding: 1rem 1.5rem;
        font-size: 1.5rem;
        display: flex;
        align-items: center;
        justify-content: end;
        gap: 0.5rem;
    }
    .mobile-menu > a {
        background-color: transparent;
        border-left: 5px solid transparent;
        color: var(--white);
        font-weight: 500;
        padding: 1.25rem 2rem;
        text-decoration: none;
    }
    .mobile-menu > a.book {
        margin-top: 1rem;
        background: linear-gradient(120deg, var(--color-accent-600) 0%, var(--color-accent-400) 100%);
        border-left: 5px solid var(--color-accent-700);
        color: var(--darkest);
    }

    @media (min-width: 40rem) {
        ul.menu {
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        .mobile-menu-btn {
            display: none;
        }
    }
</style>