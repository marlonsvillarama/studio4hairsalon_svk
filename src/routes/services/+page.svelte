<script>
    import { createServicesData } from "$lib/data/services.svelte";
    import PageHeader from "../../components/PageHeader.svelte";
    import ServiceRow from "../../components/ServiceRow.svelte";

    const services = createServicesData();
</script>

<div class="page">
    <PageHeader title="Our Services" text="" />
    {#each services.list as service, index}
        <ServiceRow data={service} flip={index % 2 > 0} />
    {/each}
</div>

<style>
    /* .page {}
    @media (min-width: 64rem) {
        .page {

        }
    } */
</style>