<script>
    // @ts-nocheck

    import { onMount } from 'svelte';
    import { createBookingData, parseDate, unparseDate } from '$lib/data/booking.svelte';
    import { createServicesData } from '$lib/data/services.svelte';
    import ClockIcon from '$lib/images/icons/clock.svg';

    const API_URL = 'https://1j6rfkw7g4.execute-api.ap-southeast-2.amazonaws.com/default/appointments';
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
    let availableTimes = $state([]);
    // let bookedTimes = $state([]);

    $effect(async () => {
        console.log('TimePicker > bookingData.date', bookingData.date);
        let dt = unparseDate(bookingData.date);
        console.log('TimePicker > dt', dt);

        let timeLoader = document.getElementById('time-loader');
        timeLoader.classList.remove('hidden');

        let timeField = document.getElementById('time-field');
        timeField.classList.add('hidden');

        let response = await fetch(API_URL + `?dt=${dt}`);
        let responseJSON = await response.json();
        console.log('responseJSON', responseJSON);

        availableTimes = filterAvailableTimes({ data: responseJSON });
        console.log('availableTimes', availableTimes);

        timeLoader.classList.add('hidden');
        timeField.classList.remove('hidden');
    });

    const filterAvailableTimes = (options) => {
        let { data } = options;
        let bookedTimes = [];
        let now = new Date();

        let sortedData = data.sort((a, b) => a.time - b.time);
        sortedData.forEach(d => {
            let svc = servicesData.getServiceById(d.service);
            let slots = svc.duration / 30;

            let dt = new Date(
                now.getFullYear(),
                now.getMonth(),
                now.getDate(),
                parseInt(d.time.slice(0, 2)),
                parseInt(d.time.slice(2))
            );
            bookedTimes.push(`${dt.getHours().toString().padStart(2, '0')}${dt.getMinutes().toString().padStart(2, '0')}`);

            for (let i = 0; i < slots - 1; i++) {
                dt.setMinutes(dt.getMinutes() + 30);
                bookedTimes.push(`${dt.getHours().toString().padStart(2, '0')}${dt.getMinutes().toString().padStart(2, '0')}`);
            }
        });
        console.log('bookedTimes', bookedTimes);

        let selectedService = servicesData.getServiceById(bookingData.service);
        // TODO Make sure to account for the duration of the selected service.

        // let output = [];
        // let now = new Date();
        // for (let i = 0, count = allStartTimes.length; i < count; i++) {
        //     if (!bookedTimes.includes(allStartTimes[i])) {
        //         output.push(allStartTimes[i]);
        //         continue;
        //     }

        //     let dt = new Date(
        //         now.getFullYear,
        //         now.getMonth(),
        //         now.getDate(),
        //         bookedTimes.
        //     );
        // }

        // let bookedServices = sortedData.map(d => d.service);
        // let serviceData = allServices.filter(d => bookedServices.includes(d.id));
        // console.log('serviceData', serviceData);

        // let tempTimes = allStartTimes.filter(t => !bookedTimes.includes(t.dt));
        
        return allStartTimes.filter(t => !bookedTimes.includes(t.dt));
    };
    
    const selectTime = () => {
        console.log('TimePicker selectTime', bookingData.time);
        const timeSelect = document.getElementById('timeSelect');
        const selectedValue = timeSelect?.querySelector('.selected-value');
        selectedValue.textContent = bookingData.time;

        toggleOptions();
    };

    const toggleOptions = () => {
        let container = document.getElementById('timeSelect');
        let selectOptions = container?.querySelector('.select-options');
        
        const isOpen = selectOptions?.classList.contains('hidden') === false;
        selectOptions?.classList.toggle('hidden');
    };

    onMount(() => {
        let container = document.getElementById('timeSelect');
        let selectButton = container?.querySelector('.select-button');
        selectButton?.addEventListener('click', () => { toggleOptions(); });

        let selectOptions = container?.querySelectorAll('.select-options li');
        selectOptions.forEach(li => {
            li.addEventListener('click', (e) => {
                bookingData.time = e.target.dataset.time;
                console.log('selected time', bookingData.time);

                selectTime();
            });
        });

        // startTimes.push({ dt: '111', text: '111' });
    });
</script>

<div class="time-picker">
    <div class="loader-wrapper hidden" id="time-loader">
        <div class="loader"></div>
        <h3>Finding available times...</h3>
    </div>
    <div class="fieldset hidden" id="time-field">
        <h4 class="label">Time</h4>
        <p class="help">What time works best for you?</p>

        <div class="select" id="timeSelect">
            <button class="select-button" type="button">
                <span class="selected-value"></span>
                <img src={ClockIcon} alt="Pick a time">
            </button>
            <ul class="select-options hidden">
                {#each availableTimes as time}
                    <li class="option" data-time={time.dt}>{time.text}</li>
                {/each}
            </ul>
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
        /* margin-bottom: 0.25rem; */
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
    .select {
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
    }
    img {
        width: 1.5rem;
        height: 1.5rem;
        /* border-left: 0.5rem solid transparent;
        border-right: 0.5rem solid transparent;
        border-top: 0.5rem solid var(--color-grey-dark-03-rgb);
        transition: transform ease-in-out 300ms; */
    }
    ul {
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