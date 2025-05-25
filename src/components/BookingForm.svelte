<script>
// @ts-nocheck

    import Stepper from './Stepper.svelte';
    import FieldSet from './FieldSet.svelte';
    import ServicePicker from './ServicePicker.svelte';
    import DatePicker from './DatePicker.svelte';
    import TimePicker from './TimePicker.svelte';
    import BookingSummary from './BookingSummary.svelte';

    import { API_URL } from '$lib/data/api.svelte';
    import { createBookingData } from '$lib/data/booking.svelte';
    import { createServicesData } from '$lib/data/services.svelte';
    import { onMount } from 'svelte';

    const bookingData = createBookingData();
    const servicesData = createServicesData();
    let step = $state(1);
    let availableTimes = $state([]);
    let submitted = $state(false);
    let success = $state(false);

    $effect(() => {
        let bookingForm = document.getElementById('bookingForm');
        let allSteps = bookingForm?.querySelectorAll('.step');
        allSteps?.forEach(s => {
            s.classList.remove('active');
        });

        let activeStep = bookingForm?.querySelector(`[data-step="${step.toString()}"]`);
        if (activeStep) {
            activeStep.classList.add('active');
        }
    });

    const goBook = () => {
        bookingData.reset();
        window.location = '/book';
    };

    const navNext = () => {
        console.log('**** step', step);
        if (step >= 3) {
            submitData();
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

    const submitData = async () => {
        console.log('submitData payload', bookingData.data);

        let jsonResponse = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                ...bookingData.data,
                id: (new Date()).getTime().toString(),
                service: servicesData.getServiceById(bookingData.service)
            })
        });
        jsonResponse = await jsonResponse.json();

        // let jsonResponse = { ok: true, id: 12345678890 };
        console.log(`submitData jsonResponse`, jsonResponse);

        submitted = true;
        success = jsonResponse.ok;
        if (success && jsonResponse.id) {
            window.location.href = `/confirm?id=${jsonResponse.id}`;
        }
    };

    const tryAgain = () => {
        step = 3;
        submitted = false;
        success = false;
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
                console.log('bookingData', bookingData);
                if (!bookingData.name || !bookingData.email) {
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
    
    <div id="bookingForm"
        class={[
            "form",
            { hidden: submitted === true }
        ]}
    >
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
            <FieldSet id="email" label="Email" help="How can we notify you?" bind:value={bookingData.email} type='email' />
            <FieldSet id="phone" label="Phone" help="Where can we call you?" bind:value={bookingData.phone} type='phone' optional={true} />
        </div>

        <div class="step confirm" data-step="3">
            <BookingSummary />
        </div>

        <div class="actions">
            {#if step > 1 && step < 4}
                <button type="button" onclick={navBack}>Go back</button>
            {/if}
            {#if step < 4}
                <button type="button" class="cta" onclick={navNext}>{ step === 3 ? 'Submit' : 'Next' }</button>
            {/if}
            {#if step >= 4}
                <div class="loader"></div>
            {/if}
        </div>
    </div>

    <div id="errorForm"
        class={[
            "form",
            { hidden: step < 4 &&
                (
                    submitted === false || (submitted === true && success === true)
                )
            }
        ]}
    >
        <div class="step active">
            <h1>Something went wrong...</h1>
            <!-- <h1>{success === true ? 'Awesome!' : 'Something went wrong...'}</h1> -->
            <!-- {#if success === true}
                <p>You have successfully booked an appointment with <strong>Studio 04 Hair Salon</strong>. You should receive an email shortly containing its details.</p>
                <p>Please note that service cancellations must be requested <strong><u>at least 1 day</u></strong> before your scheduled appointment.</p>
            {:else} -->
                <p>Your appointment did not go through this time. Please click the button below to try again.</p>
            <!-- {/if} -->
            
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
        </div>

        <div class="actions">
            <!-- {#if success === true}
                <button type="button" onclick={() => { window.location = '/'; }}>Home</button>
                <button type="button" class="cta" onclick={goBook}>Book again</button>
            {:else} -->
                <button type="button" class="cta" onclick={tryAgain}>Try again</button>
            <!-- {/if} -->
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
        /* border: 1px solid green; */
        padding: 0;
        margin-bottom: 0.5rem;
        /* max-width: 50%; */
        /* min-width: 20rem; */
        width: 100%;
        display: none;
    }
    @media (min-width: 40rem) {
        .step {
            width: 34rem;
        }
    }
    .step.active {
        display: block;
        flex-direction: column;
        gap: 2rem;
    }
    /* @media (min-width: 40rem) {
        .step {
            padding: 1.5rem 1.75rem;
        }
    } */
    .step > *:not(:last-child) {
        margin-bottom: 2rem;
    }
    .form {
        /* border: 1px solid red; */
        /* box-sizing: content-box; */
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

    .loader-wrapper {
        display: flex;
        flex-direction: row;
        gap: 1rem;
        align-items: center;
    }
    .loader {
        width: 1.5rem;
        padding: 0.25rem;
        aspect-ratio: 1;
        border-radius: 50%;
        background: var(--color-grey-dark-03-rgb);
        --_m: 
            conic-gradient(#0000 10%,#000),
            linear-gradient(#000 0 0) content-box;
        -webkit-mask: var(--_m);
                mask: var(--_m);
        -webkit-mask-composite: source-out;
                mask-composite: subtract;
        animation: l3 500ms infinite linear;
    }
    @keyframes l3 {to{transform: rotate(1turn)}}
    .loader + h3 {
        font-size: var(--fs-sm);
        font-weight: 200;
        letter-spacing: 0.25px;
    }
    
    #errorForm {
        color: var(--color-grey-dark-03-rgb);
        /* border: 1px solid red; */
    }
    #errorForm p {
        font-size: var(--fs-xs);
    }
    .contact > .row {
        display: grid;
        grid-template-columns: 4rem auto;
        align-items: center;
        font-size: var(--fs-xs);
    }
    .contact > .row:not(:last-child) {
        margin-bottom: 0.5rem;
    }
</style>