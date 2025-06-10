<script>
// @ts-nocheck
    import '../../css/app.css';
    import Calendar from "../../components/Calendar.svelte";
    import Header from "../../components/Header.svelte";
    import AdminDatePicker from '../../components/AdminDatePicker.svelte';
    import AppointmentTile from "../../components/AppointmentTile.svelte";
    import ListIcon from '$lib/images/icons/list.svg';
    import RowsIcon from '$lib/images/icons/rows.svg';
    import { appointments } from '$lib/data/appointments.svelte';
    import { createAdminData } from "$lib/data/admin.svelte";
    import { createBookingData, unparseDate } from "$lib/data/booking.svelte";

    let adminData = createAdminData();
    let bookingData = createBookingData();
    let selectedDate = $state(unparseDate(new Date()));
    /* let appointments = $derived.by(() => {
        let output = [];
        return output;
    }); */

</script>

<div class="layout">

    <Header minimum={true} />

    <section class="page-header">
        <div class="wrapper">
            <h3 class="title">Appointments</h3>
            <div class="display-btns">
                <button
                    class={[
                        { active: adminData.listDisplay === true }
                    ]}
                    onclick={() => adminData.listDisplay = true }
                ><img src={ListIcon}></button>
    
                <button
                    class={[
                        { active: adminData.listDisplay !== true }
                    ]}
                    onclick={() => adminData.listDisplay = false }
                ><img src={RowsIcon}></button>
            </div>
        </div>
        <div class="wrapper">
            <AdminDatePicker />
        </div>
    </section>

    <!-- <section class="wrapper">
        <Calendar />
    </section> -->

    <section id="appointments">
        <!-- <div class="wrapper"> -->
            {#each appointments as item}
                <AppointmentTile data={item} />
            {/each}
        <!-- </div> -->
    </section>

</div>

<style>
    .layout {
        display: flex;
        flex-direction: column;
        gap: 0;
        box-sizing: border-box;
        background-color: var(--color-bg-xlite);
        /* border: 2px solid red; */
        height: 100vh;
    }
    .layout > *:not(:first-child) {
        flex: 0 1 auto;
    }
    .layout > *:last-child {
        flex: 1 1 auto;
        overflow: scroll;
    }
    .page-header {
        background-color: white;
        box-shadow: var(--button-shadow);
        z-index: 9999;
    }
    .page-header > * {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        /* padding-top: 1rem; */
        /* border: 1px solid green; */
    }
    .page-header > *:first-child {
        padding-top: 1rem;
    }
    .page-header > *:not(:first-child) {
        padding-top: 0.5rem;
    }
    .title {
        /* color: var(--color-accent); */
        font-family: var(--font-sans);
        font-size: var(--fs-md);
        font-weight: 500;
    }
    .display-btns {
        display: flex;
        flex-direction: row;
        gap: 0;
        align-items: center;
        /* display: inline-block; */
    }
    .display-btns > button {
        padding: 0.25rem 1rem;
        border: 1px solid var(--color-border-lite);
        align-items: center;
        background-color: white;
        border-collapse: collapse;
    }
    .display-btns > button.active {
        background-color: var(--color-bg-btn);
        box-shadow: var(--button-shadow);
    }
    .display-btns > button > img {
        height: 1rem;
        /* border: 1px solid red; */
    }
    .display-btns > button:first-child {
        border-top-left-radius: 0.25rem;
        border-bottom-left-radius: 0.25rem;
    }
    .display-btns > button:last-child {
        border-top-right-radius: 0.25rem;
        border-bottom-right-radius: 0.25rem;
    }

    #appointments {
        padding: 1rem 0.75rem 2rem;
        /* border: 1px solid red; */
        /* overflow-y: auto; */
    }
</style>