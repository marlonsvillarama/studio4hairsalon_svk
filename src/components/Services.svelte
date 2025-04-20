<script>
    import { createServicesData } from '$lib/services.svelte';
    import ServiceTile from './ServiceTile.svelte';

    const services = createServicesData();
</script>

<section class="wrapper">
    {#each services.list as service}
        <ServiceTile image={service.image} label={service.name} description={service.description}/>
    {/each}
</section>

<style>
    section {
        padding-top: 3rem;
        padding-bottom: 3rem;
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
        gap: 3rem;
    }
    @media (min-width: 40rem) {
        section {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 3rem;
        }
    }
    @media (min-width: 96rem) {
        section {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 1rem;
        }
    }
    /* .tile {
        border: 1px solid red;
    } */
</style>