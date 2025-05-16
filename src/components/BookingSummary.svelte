<script>
// @ts-nocheck

    import { createBookingData } from "$lib/data/booking.svelte";
    import { createServicesData } from "$lib/data/services.svelte";
    import UserIcon from '$lib/images/icons/user.svg';
    import PhoneIcon from '$lib/images/icons/phone.svg';
    import EmailIcon from '$lib/images/icons/email.svg';

    let bookingData = createBookingData();
    let servicesData = createServicesData();

    let activeService = $derived.by(() => {
        return bookingData.service ? servicesData.getServiceById(bookingData.service) : '';
    });

    let activeServiceName = $derived.by(() => {
        return activeService ? `${activeService.category.name} - ${activeService.name}` : '';
    });

    let bookingDate = $derived.by(() => {
        return bookingData.date ?
            bookingData.date.toLocaleDateString('en-NZ', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            }) : '';
    });

    let bookingTime = $derived.by(() => {
        let hours = parseInt(bookingData.time.slice(0, 2));
        console.log(`bookingTime >>> hours`, hours);
        let ampm = hours >= 12 ? 'PM' : 'AM';

        return `${hours > 12 ? (hours - 12) : hours}:${bookingData.time.slice(2)} ${ampm}`;
    });

    $inspect('bookingData', bookingData.data);
</script>

<div class="confirm">
    <div class="reminder">
        <h3>Almost there!</h3>
        <p>Please confirm the details below and click 'Submit'.</p>
    </div>

    <div class="service">
        <h3>{activeServiceName}</h3>
        <p>{activeService.description}</p>
    </div>

    <div class="date">
        <span>{bookingDate}</span>
        <span class="value">{bookingTime}</span>
    </div>
    
    <div class="price">
        <span>About {activeService.duration} minutes</span>
        <div>
            {#if activeService.range === true}
                <span class="label">starts from</span>
            {/if}
            <span class="value">${activeService.price}</span>
        </div>
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
</div>

<style>
    .confirm {
        color: var(--color-grey-dark-03-rgb);
    }
    .confirm > *:not(:last-child) {
        margin-bottom: 2rem;
    }

    .reminder h3 {
        font-size: var(--fs-xl);
        font-weight: 700;
        border-bottom: 2px solid var(--color-accent);
        margin-bottom: 0.25rem;
        padding-bottom: 0.625rem;
    }
    .reminder p {
        color: var(--color-grey-dark-03-rgb-lite);
        font-size: var(--fs-sm);
    }

    .service h3 {
        font-size: var(--fs-lg);
        font-weight: 500;
        /* margin-bottom: 0.375rem; */
        /* padding-bottom: 0.5rem;
        border-bottom: 2px solid var(--color-accent); */
    }
    .service p {
        color: var(--color-grey-dark-03-rgb-lite);
        font-size: var(--fs-sm);
    }

    .date {
        display: flex;
        flex-direction: row;
        align-items: center;
        justify-content: space-between;
        color: var(--color-grey-dark-03-rgb);
        /* color: white; */
        font-weight: 400;
        letter-spacing: 0.25px;
        padding: 1rem 2rem;
        border: 0;
        border-radius: 0.5rem;
        background-color: var(--color-accent);
        /* box-shadow: var(--box-shadow); */
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
    .row > span {
        font-size: var(--fs-sm);
        font-weight: 300;
        letter-spacing: 0.5px;
    }

    .price {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        padding: 1rem 2rem;
        /* border: 0; */
        border: 1px solid var(--color-border-lite);
        border-radius: 0.5rem;
        /* background-color: var(--color-border-lite-extra); */
        color: var(--color-grey-dark-03-rgb);
        font-weight: 200;
    }
    .value {
        /* margin-left: 1rem; */
        font-weight: 500;
        font-size: var(--fs-xl);
        letter-spacing: 0;
    }
</style>