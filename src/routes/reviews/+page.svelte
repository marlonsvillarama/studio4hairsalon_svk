<script>
    import PageHeader from "../../components/PageHeader.svelte";
    import Gallery from "../../components/Gallery.svelte";

    import { createReviewsData } from "$lib/data/reviews.svelte";
    const gallery = createReviewsData();
</script>

<!-- <main> -->
<div class="page">
    <PageHeader title="Reviews" text="See what our customers say." />
    <Gallery images={gallery.images} />
</div>
<!-- </main> -->

<style></style>