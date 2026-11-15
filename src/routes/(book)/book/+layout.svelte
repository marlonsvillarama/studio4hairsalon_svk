<script>
	import '../../layout.css';
    import { reveal } from "$lib/reveal";
    import { setCartState } from '$lib/data/cart.svelte';
	import favicon from '$lib/assets/favicon.svg';
	import Header from '$lib/components/shared/header.svelte';

	let { children } = $props();

    setCartState();
</script>

<svelte:head>
    <link rel="icon" href={favicon} />
    <title>Book with John · Studio 4 Hair Salon</title>
</svelte:head>

<Header />

<div class="booking-page">
    <div class="img reveal-section from-left" use:reveal role="img"
        aria-label="John with two smiling clients outside the Studio 4 salon"></div>
    <main class="booking-content">
		{@render children?.()}
	</main>
</div>

<style>
    .booking-page {
        min-height: 100vh;
        display: flex;
        flex-direction: column;
    }
    @media (min-width: 60rem) {
        .booking-page {
            display: grid;
            grid-template-columns: 2fr 3fr;
        }
    }
    .booking-page > .img {
        display: none;
    }
    @media (min-width: 60rem) {
        .booking-page > .img {
            display: block;
            /* Stay in view while the form scrolls. */
            position: sticky;
            top: 0;
            height: 100vh;
            background-color: var(--darker);
            background-image: url(/images/gallery/book-001.jpg);
            background-size: cover;
            background-position: center;
        }
    }
</style>
