<script>
    import PageHeader from "../../../components/PageHeader.svelte";
    import Gallery from "../../../components/Gallery.svelte";

    import { createGalleryData } from "$lib/data/gallery.svelte";
    const gallery = createGalleryData();
</script>

<!-- <main> -->
<div class="page">
    <PageHeader title="Gallery" text="" />
    <Gallery images={gallery.images} />
</div>
<!-- </main> -->

<style></style>