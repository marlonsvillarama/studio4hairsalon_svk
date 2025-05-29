<script>
    import PageHeader from "../../../components/PageHeader.svelte";
    import { createBookingData } from "$lib/data/booking.svelte";
    import { createServicesData } from "$lib/data/services.svelte";
    import ClockIcon from '$lib/images/icons/clock.svg';
    import DollarIcon from '$lib/images/icons/dollar.svg';
    import UserIcon from '$lib/images/icons/user.svg';
    import PhoneIcon from '$lib/images/icons/phone.svg';
    import EmailIcon from '$lib/images/icons/email.svg';

    const bookingData = createBookingData();
    /* let { data } = $props();
    const servicesData = createServicesData();

    const appointmentData = data.getAppointment();
    let activeServiceName = appointmentData.service.name;
    let activeCategoryName = appointmentData.service.category.name; */

    const goBook = () => {
        bookingData.reset();
        window.location.href = '/book';
    };
</script>

<div class="page">
    <PageHeader title="Thank you!" />

    <div class="wrapper contents">
        <p>You have successfully booked an appointment with <strong>Studio 4 Hair Salon</strong>. You should receive an email shortly containing its details.</p>

        <!-- <div class="details">
            <div class="service">
                <span>{activeServiceName}</span>
                <p>{activeCategoryName}</p>
            </div>
        
            <div class="date">
                <span>{bookingDate}</span>
                <span class="value">{bookingTime}</span>
            </div>

            <div class="client">
                <div class="row">
                    <img src={ClockIcon}>
                    <span>About {activeService.duration} minutes</span>
                </div>
                <div class="row">
                    <img src={DollarIcon}>
                    <span>This service {#if activeService.range === true}starts from {:else}costs {/if} ${activeService.price}</span>
                </div>
                <div class="row">
                    <img src={UserIcon}>
                    <span class="name">{bookingData.name}</span>
                </div>
                <div class="row">
                    <img src={PhoneIcon}>
                    <span class="name">{bookingData.phone}</span>
                </div>
                <div class="row">
                    <img src={EmailIcon}>
                    <span class="name">{bookingData.email}</span>
                </div>
            </div>
        </div> -->

        <p>Please note that service cancellations must be requested <strong><u>at least 1 day</u></strong> before your scheduled appointment.</p>
        <p>For any questions or concerns, please feel free to contact us:</p>
    
        <div class="contact">
            <div class="row">
                <span>Phone:</span>
                <span>(06) 353-5678</span>
            </div>
            <div class="row">
                <span>Mobile:</span>
                <span>(022) 1888-5240</span>
            </div>
        </div>

        <div class="actions">
            <button type="button" onclick={() => { window.location.href = '/'; }}>Home</button>
            <button type="button" class="cta" onclick={goBook}>Book again</button>
        </div>
    </div>

</div>

<style>
    .contents {
        /* border: 1px solid red; */
        font-size: var(--fs-xs);
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    .actions {
        margin-top: 2rem;
        width: 100%;
        display: flex;
        flex-direction: row;
        justify-content: center;
        align-items: center;
        gap: 2rem;
    }
    button {
        background-color: white;
        border: 0px solid var(--color-border-lite);
        border-radius: 0.5rem;
        color: var(--color-grey-dark-03-rgb);
        cursor: pointer;
        padding: 0.75rem 1.25rem;
        box-shadow: var(--button-shadow);
        transition: all 100ms ease-in-out;
    }
    button:not(.cta):hover {
        background-color: var(--color-border-lite);
    }

    button.cta {
        background-color: var(--color-bg-btn);
        box-shadow: var(--button-shadow);
        border: 0px solid transparent;
        padding: 0.75rem 2rem;
        font-weight: 700;
    }
    button.cta:hover {
        background-color: var(--color-bg-btn-hover);
    }
</style>