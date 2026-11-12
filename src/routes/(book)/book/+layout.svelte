<script>
	import '../../layout.css';
    import { reveal } from "$lib/reveal";
	import favicon from '$lib/assets/favicon.svg';
	import Header from '$lib/components/shared/header.svelte';
	import Footer from '$lib/components/shared/footer.svelte';

	let { children } = $props();
</script>

<Header />

<div class="booking-page">
    <div class="img reveal-section from-left" use:reveal></div>
    <div class="booking-content reveal-section from-bottom" use:reveal>

		{@render children?.()}

	</div>
</div>

<style>
    .booking-page {
        min-height: 100vh;
        /* border: 1px solid red; */
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
            height: 100%;
            background-color: red;
            background-image: url(/images/gallery/book-001.jpg);
            background-size: cover;
            background-position: center;
        }
    }
	/* .booking-content {
        min-height: 100%;
        border: 1px solid red;
        display: flex;
        flex-direction: column;
	} */
</style>