<script>
    // @ts-nocheck

    import { onMount } from 'svelte';
    import { API_URL } from '$lib/data/api.svelte';
    import { createAppointmentsData } from '$lib/data/appointments.svelte';
    import { createBookingData, parseDate, unparseDate, unparseTime } from '$lib/data/booking.svelte';
    import { createServicesData } from '$lib/data/services.svelte';
    import ClockIcon from '$lib/images/icons/clock.svg';

    const appointmentsData = createAppointmentsData();
    const bookingData = createBookingData();
    const servicesData = createServicesData();
    const allServices = servicesData.services;
    let asyncWorking = $state(false);
    let availableTimes = $state([]);

    const allStartTimes = [
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

    const bookServiceSlots = (options) => {
        let { id, index } = options;
        let output = [];
        let svc = servicesData.getServiceById(id);
        let slots = svc ? svc.duration / 30 : 1;

        for (let j = 0; j < slots && (index + j) < allStartTimes.length; j++) {
            output.push(allStartTimes[index + j].dt);
        }

        return output;
    };
    
    const getAvailableTimes = async (options) => {
        let date = bookingData.date;
        let service = bookingData.service;
        let bookedTimes = [];
        let now = new Date();

        asyncWorking = true;
        let apiResponse = await fetch(`${API_URL}?dt=${unparseDate(date)}`);
        let appointments = await apiResponse.json();

        let sortedData = appointments.sort((a, b) => a.time - b.time);
        let selectedService = servicesData.getServiceById(parseInt(service.toString()));
        let selectedSlots = selectedService.duration / 30;
        let serviceStartTimes = [];

        allTimesLoop: for (let i = 0, count = allStartTimes.length; i < count; i++) {
            let startTime = allStartTimes[i].dt;
            let serviceAtStartTime = sortedData.find(d => d.time === startTime);

            if (serviceAtStartTime) {
                let serviceSlots = bookServiceSlots({ id: serviceAtStartTime.sid, index: i });
                bookedTimes = bookedTimes.concat(serviceSlots);

                i += (serviceSlots.length - 1);
                continue allTimesLoop;
            }

            if ((i + selectedSlots - 1) >= count) {
                remainingSlotsLoop: for (let j = i; j < count; j++) {
                    bookedTimes.push(allStartTimes[j].dt);
                }
                i += (selectedSlots - 1);
                
                continue allTimesLoop;
            }

            let hasService = false;
            let slotIndex = i;
            selectedSlotsLoop: for (let j = 0; j < selectedSlots; j++) {
                let slotTime = allStartTimes[i + j]?.dt;
                let serviceAtSlotTime = sortedData.find(d => d.time === slotTime);

                if (!serviceAtSlotTime) {
                    continue selectedSlotsLoop;
                }

                for (let k = slotIndex; k < slotIndex + j; k++) {
                    bookedTimes.push(allStartTimes[k].dt);
                }

                let serviceSlots = bookServiceSlots({ id: serviceAtSlotTime.sid, index: i + j });
                bookedTimes = bookedTimes.concat(serviceSlots);

                i += (j + serviceSlots.length - 1);
                continue allTimesLoop;
            }

            defaultLoop: for (let j = 1; j < selectedSlots; j++) {
                if (i + j < count) {
                    bookedTimes.push(allStartTimes[i + j].dt);
                }

                bookedTimes.push(allStartTimes[i + j].dt);
            }

            i += (selectedSlots - 1);
        }

        bookedTimes =  [ ...new Set(bookedTimes) ];
        availableTimes = allStartTimes.filter(t => !bookedTimes.includes(t.dt));
        asyncWorking = false;
        console.log('asyncWorking', asyncWorking);
    };

    $effect(() => {
        getAvailableTimes();
    });
    
    const selectTime = (e) => {
        let button = e.target;
        bookingData.time = button.dataset.time;
    };
</script>

<div class="time-picker">
    <div class={[
        "loader-wrapper",
        { hidden: asyncWorking === false }
    ]} id="time-loader">
        <div class="loader"></div>
        <h3>Finding available times...</h3>
    </div>
    <div id="time-field"
        class={[
            "fieldset",
            { hidden: asyncWorking === true || availableTimes.length <= 0 }
        ]}
    >
        <h4 class="label">Pick a time</h4>
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
    
    <div
        class={[
            "fieldset",
            { hidden: asyncWorking === true || availableTimes.length > 0 }
        ]}
    >
        <h4 class="label">No available time slots</h4>
        <p class="help">Please choose another date to book.</p>
    </div>
</div>

<style>
    .time-picker {
        /* min-width: 20rem; */
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
        /* margin-left: 0.25rem; */
    }
    .help {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-xs);
        font-style: italic;
        font-weight: 200;
        margin-bottom: 0.75rem;
        /* margin-left: 0.25rem; */
    }

    #time-list {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
        grid-auto-columns: 1fr;
    }
    #time-list > button {
        padding: 1rem 0.5rem;
        border: 0;
        border-radius: 0.25rem;
        background-color: var(--color-border-lite-extra);
        box-shadow: var(--button-shadow);
        font-size: var(--fs-sm);
    }
    #time-list > button:hover {
        background-color: var(--color-border-lite);
    }
    .selected {
        background-color: var(--color-bg-btn) !important;
    }

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