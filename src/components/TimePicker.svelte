<script>
    // @ts-nocheck

    import { onMount } from 'svelte';
    import { createAppointmentsData } from '$lib/data/appointments.svelte';
    import { createBookingData, parseDate, unparseDate, unparseTime } from '$lib/data/booking.svelte';
    import { createServicesData } from '$lib/data/services.svelte';
    import ClockIcon from '$lib/images/icons/clock.svg';

    const appointmentsData = createAppointmentsData();
    const bookingData = createBookingData();
    const servicesData = createServicesData();
    const allServices = servicesData.services;

    let allStartTimes = [
        { dt: '0930', text: '9:30 AM' },
        { dt: '1000', text: '10:00 AM' },
        { dt: '1030', text: '10:30 AM' },
        { dt: '1100', text: '11:00 AM' },
        { dt: '1130', text: '11:30 AM' },
        { dt: '1200', text: '12:00 PM' },
        { dt: '1230', text: '12:30 PM' },
        { dt: '1300', text: '1:00 PM' },
        { dt: '1330', text: '1:30 PM' },
        { dt: '1400', text: '2:00 PM' },
        { dt: '1430', text: '2:30 PM' },
        { dt: '1500', text: '3:00 PM' },
        { dt: '1530', text: '3:30 PM' },
        { dt: '1600', text: '4:00 PM' },
        { dt: '1630', text: '4:30 PM' }
    ];
    
    let availableTimes = $derived.by(() => {
        // console.log('TimePicker > bookingData.date', bookingData.date);
        let dt = unparseDate(bookingData.date);
        // console.log('TimePicker > dt', dt);

        let responseJSON = appointmentsData.getByDate(dt);
        let output = getAvailableTimes({ data: responseJSON });
        console.log('$derived.by ==> output', output);

        return output;
    });

    const getAvailableTimes = (options) => {
        let { data } = options;
        let bookedTimes = [];
        let now = new Date();

        let sortedData = data.sort((a, b) => a.time - b.time);
        let selectedService = servicesData.getServiceById(parseInt(bookingData.service.toString()));
        let selectedSlots = selectedService.duration / 30;
        let serviceStartTimes = [];

        allTimesLoop: for (let i = 0, count = allStartTimes.length; i < count; i++) {
            let startTime = allStartTimes[i].dt;
            let serviceAtStartTime = sortedData.find(d => d.time === startTime);
            let serviceSlots = 0;
            let svc = '';

            if (serviceAtStartTime) {
                svc = servicesData.getServiceById(serviceAtStartTime.sid);
                serviceSlots = svc.duration / 30;
                // console.log(`** serviceAtStartTime ** serviceSlots = ${serviceSlots}; svc ==>`, svc);

                for (let j = 0; j < serviceSlots && (i + j) < count; j++) {
                    // console.log(`j = ${j}; [i + j] = ${i + j}; dt = ${allStartTimes[i + j].dt}`);
                    bookedTimes.push(allStartTimes[i + j].dt);
                }

                i += (serviceSlots - 1);
                continue;
            }

            let hasService = false;
            let slotIndex = i;
            selectedSlotsLoop: for (let j = 0; j < selectedSlots; j++) {
                let slotTime = allStartTimes[i + j]?.dt;
                let serviceAtSlotTime = sortedData.find(d => d.time === slotTime);
                // console.log(`** selectedSlotsLoop ** i = ${i}; j = ${j}; slotTime = ${slotTime}; serviceAtStartTime ==>`, serviceAtSlotTime);

                if (serviceAtSlotTime) {
                    svc = servicesData.getServiceById(serviceAtSlotTime.service);
                    serviceSlots = svc.duration / 30;
                    slotIndex = j;
                    hasService = true;
                    break selectedSlotsLoop;
                }
            }
            // console.log(`hasService = ${hasService}; slotIndex = ${slotIndex}`);

            if (hasService === true) {
                for (let j = 0; j < slotIndex; j++) {
                    bookedTimes.push(allStartTimes[i + j].dt);
                }

                for (let j = 0; j <= serviceSlots; j++) {
                    bookedTimes.push(allStartTimes[i + slotIndex + j].dt);
                }
                
                // console.log(`** selectedSlotsLoop ** i = ${i}; bookedTimes ===>>`, bookedTimes);
                i += (slotIndex + selectedSlots - 1);
                continue;
            }

            defaultLoop: for (let j = 1; j < selectedSlots; j++) {
                if (i + selectedSlots >= count) {
                    bookedTimes.push(allStartTimes[i].dt);
                    break defaultLoop;
                }

                bookedTimes.push(allStartTimes[i + j].dt);
            }
            // console.log(`** defaultLoop ** i = ${i}; startTime = ${startTime}; bookedTimes ===>>`, bookedTimes);
            i += (selectedSlots - 1);
        }

        let output = allStartTimes.filter(t => !bookedTimes.includes(t.dt));
        console.log('getAvailableTimes >>> output', output);
        return output;
    };
    
    const selectTime = (e) => {
        let button = e.target;
        bookingData.time = button.dataset.time;
    };

    $effect(() => {
        $inspect('availableTimes', availableTimes);
    });
</script>

<div class="time-picker">
    <div class={[
        "loader-wrapper hidden"
    ]} id="time-loader">
        <div class="loader"></div>
        <h3>Finding available times...</h3>
    </div>
    <div class="fieldset" id="time-field">
        <h4 class="label">Time</h4>
        <p class="help">What time works best for you?</p>

        <div id="time-list">
            {#each availableTimes as time}
                <button
                    class={[
                        "time-option",
                        { selected: bookingData.time === time.dt }
                    ]}
                    data-time={time.dt}
                    onclick={selectTime}
                >{time.text}</button>
            {/each}
        </div>
    </div>
</div>

<style>
    .time-picker {
        min-width: 20rem;
        width: 100%;
        display: flex;
        flex-direction: column;
        gap: 2rem;
        margin-bottom: 2rem;
    }
    .label {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-md);
        font-weight: 500;
        margin-left: 0.25rem;
    }
    .help {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-sm);
        font-style: italic;
        font-weight: 200;
        margin-bottom: 0.25rem;
        margin-left: 0.25rem;
    }

    #time-list {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
        grid-auto-columns: 1fr;
    }
    #time-list > button {
        padding: 0.75rem;
        border: 0;
        border-radius: 0.25rem;
        background-color: var(--color-border-lite-extra);
        box-shadow: var(--button-shadow);
    }
    #time-list > button:hover {
        background-color: var(--color-border-lite);
    }
    .selected {
        background-color: var(--color-bg-btn) !important;
    }

    /* .select {
        position: relative;
        display: inline-block;
        width: 100%;
    }
    .select-button {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background-color: white;
        border: 1px solid var(--color-border-lite);
        border-radius: 0.5rem;
        cursor: pointer;
        font-size: var(--fs-sm);
        padding: 0.5rem 1.25rem;
        width: 100%;
    }
    .selected-value {
        color: var(--color-grey-dark-03-rgb);
    } */
    /* img {
        width: 1.5rem;
        height: 1.5rem;
        /!* border-left: 0.5rem solid transparent;
        border-right: 0.5rem solid transparent;
        border-top: 0.5rem solid var(--color-grey-dark-03-rgb);
        transition: transform ease-in-out 300ms; *!/
    } */
    /* ul {
        position: absolute;
        top: 100%;
        left: 0;
        width: 10rem;
        border: 1px solid var(--color-accent);
        border-radius: 0.5rem;
        background-color: white;
        list-style: none;
        padding: 0.75rem 1.25rem;
        margin: 0.5rem 0 0;
        box-shadow: var(--button-shadow);
        max-height: 15rem;
        overflow-y: auto;
        z-index: 9999;
    }
    ul::-webkit-scrollbar {
        width: 0.5rem;
    }
    ul::-webkit-scrollbar-track {
        background-color: #f1f1f1;
        border-radius: 0.5rem;
    }
    ul::-webkit-scrollbar-thumb {
        background-color: var(--color-grey-dark-03-rgb);
        border-radius: 0.5rem;
    }
    li {
        padding: 0.5rem 1rem;
        cursor: pointer;
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-sm);
        font-weight: 300;
        transition: all 150ms ease-in-out;
        border-radius: 0.25rem;
    }
    li:hover:not(.category),
    li:focus {
        background-color: #f2f2f2;
        font-weight: 400;
    } */

    /* HTML: <div class="loader"></div> */
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
</style>