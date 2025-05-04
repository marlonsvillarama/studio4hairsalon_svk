<script>
// @ts-nocheck

    import Stepper from './Stepper.svelte';
    import FieldSet from './FieldSet.svelte';
    import ServicePicker from './ServicePicker.svelte';
    import DatePicker from './DatePicker.svelte';
    import TimePicker from './TimePicker.svelte';

    import { createBookingData } from '$lib/data/booking.svelte';
    import { createServicesData } from '$lib/data/services.svelte';

    const bookingData = createBookingData();
    const servicesData = createServicesData();
    let step = $state(1);
    let availableTimes = $state([]);

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

    const navNext = () => {
        if (step >= 3) {
            step = 3;
            return;
        }

        if (validateStep(step) === false) { return; }

        step++;
    };

    const navBack = () => {
        if (step <= 1) {
            step = 1;
            return;
        }

        step--;
    };

    const validateStep = (step) => {
        switch (step) {
            case 1: {
                if (!bookingData.service) {
                    alert('Please choose which service you like.');
                    return false;
                }

                if (!bookingData.date || !bookingData.time) {
                    alert('Please choose a date and time for your appointment.');
                    return false;
                }

                break;
            }
            case 2: {
                if (!bookingData.name || !bookingData.email || !bookingData.phone) {
                    alert('Please complete your personal details.');
                    return false;
                }
                
                break;
            }
        }

        return true;
    };
</script>

<section class="wrapper">
    <Stepper {step} />
    
    <div class="form" id="bookingForm">
        <div class="step step-1 active" data-step="1">
            <ServicePicker />
            {#if bookingData.service}
                <DatePicker />
            {/if}
            {#if bookingData.date}
                <TimePicker />
            {/if}
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
            {#if step > 1}
            <button type="button" onclick={navBack}>Go back</button>
            {/if}
            <button type="button" class="cta" onclick={navNext}>{ step >= 3 ? 'Submit' : 'Next' }</button>
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