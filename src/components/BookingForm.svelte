<script>
// @ts-nocheck

    import FieldSet from './FieldSet.svelte';
    import ServiceSelector from './ServiceSelector.svelte';
    import DatePicker from './DatePicker.svelte';
    import Stepper from './Stepper.svelte';
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
        <div class="step active" data-step="1">
            <ServiceSelector />
            <DatePicker />
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
    <!-- <aside>
        <h4>How to book</h4>
        <div class="steps">
            <div class="step" data-form-step="1">
                <span>Step 1: Choose what you want</span><br>
                <p>Some text here...</p>
            </div>
            <div class="step" data-form-step="2">
                <span>Step 2: Share your details</span><br>
                <p>Leave your contact details so we can confirm your appointment.</p>
            </div>
            <div class="step" data-form-step="3">
                <span>Step 3: Confirm your appointment</span><br>
                <p>Some text here...</p>
            </div>
        </div>
    </aside> -->

    <!--  -->

    <!-- <div class="form">
        test
    </div> -->
</section>

<style>
    section {
        /* padding-top: 3rem; */
        /* padding-bottom: 3rem; */
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }
    /* @media (min-width: 64rem) {
        section {
            display: grid;
            grid-template-columns: 40% calc(60% - 4rem);
            gap: 4rem;
        }
    } */
    /* .steps {
        border: 1px solid red;
    } */
    /* aside h4 {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-serif);
        font-size: var(--fs-xl);
        font-weight: 700;
        padding-bottom: 1.5rem;
    } */
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
        /* border: 1px dotted var(--color-accent);
        border-radius: 1rem;
        box-shadow: var(--card-shadow); */
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
    /* .step > span {
        color: var(--color-accent);
        font-family: var(--font-default);
        font-size: var(--fs-lg);
        font-weight: 300;
        display: inline-block;
        letter-spacing: 0.25px;
        padding-bottom: 0.5rem;
    } */
    /* .step > p {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-sm);
        font-weight: 200;
        padding-left: 2rem;
        letter-spacing: 0.25px;
    } */
    /* section > div {
        align-items: flex-start;
        justify-content: center;
    } */
    /* section:first-child {
        display: none;
    } */
    /* @media (min-width: 64rem) {
        section:first-child {
            display: block;
            justify-content: flex-end;
            width: auto;
            align-items: right;
        }
    } */

    /* img {
        display: none;
    } */
    /* @media (min-width: 64rem) {
        img {
            display: block;
            /!* max-inline-size: 100%; *!/
            width: 100%;
            block-size: auto;
            object-fit: contain;
            object-position: center center;
        }
    } */
     .step.confirm {
        border: 1px solid red;
     }
    .form {
        /* width: 50%; */
        /* min-width: 20rem; */
        /* margin: 0 auto; */
        border: 0px solid red;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 2rem;
        /* width: 60%; */
    }
    .actions {
        width: 100%;
        /* border: 1px solid green; */
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
        /* box-shadow: none; */
        /* box-shadow: var(--button-shadow); */
    }
    /* @media (min-width: 40rem) {
        button:hover {
            box-shadow: var(--button-shadow);
        }
    } */

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