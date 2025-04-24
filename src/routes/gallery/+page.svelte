<script>
    import PageHeader from "../../components/PageHeader.svelte";
    import Gallery from "../../components/Gallery.svelte";

    import { createGalleryData } from "$lib/data/gallery.svelte";
    const gallery = createGalleryData();
</script>

<!-- <main> -->
<div class="page">
    <PageHeader title="Our Gallery" text="See our past work and." />
    <Gallery images={gallery.images} />
</div>
<!-- </main> -->

<style></style>