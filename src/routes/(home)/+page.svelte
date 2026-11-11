<script>
    import Hero from "$lib/components/shared/hero.svelte";
    import ServicesSection from "$lib/components/services-section.svelte";
    import JohnSection from "$lib/components/john-section.svelte";
    import GallerySection from "$lib/components/gallery-section.svelte";
    import ReviewsSection from "$lib/components/reviews-section.svelte";
    import ScheduleSection from "$lib/components/schedule-section.svelte";
    import Footer from "$lib/components/shared/footer.svelte";
</script>

<Hero />

<main>
    <ServicesSection />
    <JohnSection />
    <ReviewsSection />
    <!-- <GallerySection /> -->
    <ScheduleSection />
</main>
