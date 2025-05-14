<script>
// @ts-nocheck

    import { createBookingData } from "$lib/data/booking.svelte";
    import { createServicesData } from "$lib/data/services.svelte";
    import UserIcon from '$lib/images/icons/user.svg';
    import PhoneIcon from '$lib/images/icons/phone.svg';
    import EmailIcon from '$lib/images/icons/email.svg';

    let bookingData = createBookingData();
    let servicesData = createServicesData();
</script>

<div class="confirm">
    <div class="service">
        <h3>{servicesData.activeCategory.name} - {servicesData.activeService.name}</h3>
        <!-- <span class="category">{servicesData.activeCategory.name}</span> - <span class="service">{servicesData.activeService.name}</span> -->
        <p>{servicesData.activeService.description}</p>
    </div>
    <div class="client">
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

    <div class="reminder">
        <h3>Almost there!</h3>
        <p>Please confirm the details above and click 'Submit'.</p>
    </div>
</div>

<style>
    .confirm {
        /* border: 1px solid red; */
        color: var(--color-grey-dark-03-rgb);
    }
    .confirm > *:not(:last-child) {
        margin-bottom: 2rem;
    }
    /* .service {
        margin-bottom: 2rem;
    } */
    .service h3 {
        font-size: var(--fs-lg);
        font-weight: 500;
        margin-bottom: 0.375rem;
        padding-bottom: 0.5rem;
        border-bottom: 2px solid var(--color-accent);
        /* text-decoration: underline; */
    }
    .service p {
        color: var(--color-grey-dark-03-rgb-lite);
        font-size: var(--fs-sm);
    }
    .client {
        line-height: 2rem;

    }
    .client > .row:not(:last-child) {
        margin-bottom: 0.5rem;
    }
    .row {
        display: flex;
        flex-direction: row;
        align-items: center;
        gap: 1.5rem;
    }
    .client img {
        height: 1.5rem;
        /* border: 1px solid red; */
        text-align: center;
    }
    .reminder h3 {
        font-size: var(--fs-lg);
        font-weight: 700;
    }
    .reminder p {
        color: var(--color-grey-dark-03-rgb-lite);
        font-size: var(--fs-sm);
    }
</style>