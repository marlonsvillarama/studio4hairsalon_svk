<script>
// @ts-nocheck
    import { onMount } from "svelte";
    import Calendar from "../../components/Calendar.svelte";
    import AppointmentTile from "../../components/AppointmentTile.svelte";
    import { createBookingData, unparseDate } from "$lib/data/booking.svelte";

    let bookingData = createBookingData();
    let selectedDate = $state(unparseDate(new Date()));
    let appointments = $derived.by(() => {
        let output = [];
        return output;
    });

    onMount(() => {
    });
</script>

<main>
    <section class="wrapper">
        <h3 class="title">Appointments</h3>
    </section>

    <section class="wrapper">
        <Calendar />
    </section>

    <section id="appointments" class="wrapper">
        {#each appointments as item}
            <AppointmentTile data={item} />
        {/each}
    </section>
</main>

<style>
    main {
        margin-top: 2rem;
        display: flex;
        flex-direction: column;
        gap: 1rem;
        font-size: var(--fs-xs);
    }
    .title {
        /* color: var(--color-accent); */
        font-family: var(--font-serif);
        font-size: var(--fs-lg);
        font-weight: 700;
    }
</style>