<script>
// @ts-nocheck

    import Stepper from './Stepper.svelte';
    import FieldSet from './FieldSet.svelte';
    import ServiceSelector from './ServiceSelector.svelte';
    import DatePicker from './DatePicker.svelte';
    import TimePicker from './TimePicker.svelte';

    import { createBookingData } from '$lib/data/booking.svelte';
    import { createServicesData } from '$lib/data/services.svelte';

    const bookingData = createBookingData();
    const servicesData = createServicesData();
    let step = $state(1);

    $effect(() => {
        let bookingForm = document.getElementById('bookingForm');
        let allSteps = bookingForm?.querySelectorAll('.step');
        allSteps?.forEach(step => {
            step.classList.remove('active');
        });

        let activeStep = bookingForm?.querySelector(`[data-step="${step.toString()}"]`);
        console.log('activeStep', activeStep);
        if (activeStep) {
            activeStep.classList.add('active');
        }
    });

    const doNext = () => {
        if (step >= 3) {
            step = 3;
            return;
        }

        step++;
    };

    const doBack = () => {
        if (step <= 1) {
            step = 1;
            return;
        }

        step--;
    };
</script>

<section class="wrapper">
    <Stepper {step} />
    
    <div class="form" id="bookingForm">
        <div class="step step-1 active" data-step="1">
            <ServiceSelector />
            <DatePicker />
            <TimePicker />
        </div>

        <div class="step" data-step="2">
            <FieldSet id="name" label="Your name" help="Tell us who you are..." bind:value={bookingData.name} />
            <FieldSet id="phone" label="Phone" help="Where can we call you..." bind:value={bookingData.phone} type='phone' />
            <FieldSet id="email" label="Email" help="How can we notify you..." bind:value={bookingData.email} type='email' />
        </div>

        <div class="step confirm" data-step="3">
            <div>
                <h3>You have chosen the following service:</h3>
                <span class="category">{servicesData.activeCategory.name}</span> - <span class="service">{servicesData.activeService.name}</span>
            </div>
            <div>
                <span class="name">{bookingData.name}</span><br/>
                <span class="name">{bookingData.phone}</span><br/>
                <span class="name">{bookingData.email}</span>
            </div>
        </div>

        <div class="actions">
            <button type="button" class="cta" onclick={doNext}>{ step >= 3 ? 'Submit' : 'Next' }</button>
            {#if step > 1}
            <button type="button" onclick={doBack}>Go back</button>
            {/if}
        </div>
    </div>
</section>

<style>
    section {
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }
    .step {
        border: 0px solid green;
        padding: 0;
        margin-bottom: 0.5rem;
        max-width: 50%;
        min-width: 20rem;
        width: 50%;
        display: none;
        box-sizing: content-box;
    }
    .step.active {
        display: block;
        flex-direction: column;
        gap: 2rem;
    }
    @media (min-width: 40rem) {
        .step {
            padding: 1.5rem 1.75rem;
        }
    }
    .step > *:not(:last-child) {
        margin-bottom: 2rem;
    }
    .step-1 {}
    .step.confirm {
        border: 1px solid red;
    }
    .form {
        border: 0px solid red;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 2rem;
    }
    .actions {
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