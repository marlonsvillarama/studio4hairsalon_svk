<script>
    import '../../../css/app.css';
    import Header from '../../../components/Header.svelte';
    import BackIcon from '$lib/images/icons/back.svg';
    import AppointmentDetails from '../../../components/AppointmentDetails.svelte';
    import { createAdminData } from '$lib/data/admin.svelte';

    // let adminData = createAdminData();
    let { data } = $props();
    console.log('appointment data', data);

    const backToList = () => {
        // adminData.clear();
        window.location.href = '/admin';
    };
</script>

<div class="layout">

    <Header minimum={true} />

    <section class="page-header">
        <div class="wrapper">
            <div class="display-btns">
                <button onclick={backToList}
                ><img src={BackIcon}></button>
            </div>
            <h3 class="title">Edit Appointment</h3>
        </div>
    </section>

    <!-- <section class="wrapper">
        <Calendar />
    </section> -->

    <section id="detail">
        <div class="wrapper">
            <AppointmentDetails {data} />
        </div>
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
        padding: 1rem 0 1rem;
        /* border: 1px solid green; */
    }
    .title {
        /* color: var(--color-accent); */
        font-family: var(--font-sans);
        font-size: var(--fs-sm);
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
        border-radius: 0.25rem;
    }
    .display-btns > button > img {
        height: 1rem;
        /* border: 1px solid red; */
    }
    #detail {
        padding: 1rem 0 2rem;
        /* border: 1px solid red; */
        /* overflow-y: auto; */
    }
</style>