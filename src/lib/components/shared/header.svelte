<script>
    import { page } from "$app/state";
    import Logo from "./logo.svelte";
    import Nav from "./nav.svelte";

    let scrollY = $state(0);
    let onBooking = $derived(page.url.pathname.startsWith('/book'));
</script>

<svelte:window bind:scrollY />

<header class:scrolled={scrollY > 50 || page.url.pathname.length > 1} class:compact={onBooking}>
    <div class="container">
        <a href="/" class="home-link" aria-label="Studio 4 Hair Salon, home"><Logo /></a>
        <Nav />
    </div>
</header>

<style>
    header {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        z-index: 1000;
        transition: background-color 300ms ease;
    }
    header.scrolled {
        background-color: var(--darkest);
    }
    header > .container {
        margin: 0 auto;
        width: 90%;
        max-width: 110rem;
        padding: 1.5rem 0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
        transition: padding 300ms ease;
    }
    @media (min-width: 40rem) {
        header > .container {
            padding: 2rem 0;
        }
    }
    header.scrolled > .container {
        padding: 1rem 0;
    }
    .home-link {
        display: block;
        flex: none;
    }

    /* On the booking page the form needs the room: a slimmer bar on phones. */
    @media (max-width: 39.99rem) {
        header.compact > .container {
            padding: 0.5rem 0;
        }
        header.compact :global(.logo) {
            font-size: 2.25rem;
        }
    }
</style>
