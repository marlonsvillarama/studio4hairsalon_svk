<script>
    import Hero from "$lib/components/shared/hero.svelte";
    import ServicesSection from "$lib/components/services-section.svelte";
    import JohnSection from "$lib/components/john-section.svelte";
    import ReviewsSection from "$lib/components/reviews-section.svelte";
    import ScheduleSection from "$lib/components/schedule-section.svelte";
    import MobileBookBar from "$lib/components/shared/mobile-book-bar.svelte";

    let { data } = $props();
</script>

<svelte:head>
    <title>Studio 4 Hair Salon · John Fernandez, Palmerston North</title>
    <meta name="description" content="Cuts, colour, treatments and styling with John Fernandez at Studio 4 Hair Salon, 7 George Street, Palmerston North. See prices and book." />
</svelte:head>

<Hero />

<main>
    <ServicesSection catalogue={data.catalogue} />
    <JohnSection />
    <ReviewsSection />
    <!-- <GallerySection /> -->
    <ScheduleSection />
</main>

<MobileBookBar />
