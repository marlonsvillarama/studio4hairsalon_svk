<script>
    // @ts-nocheck

    import { onMount } from 'svelte';
    import { createBookingData } from '$lib/data/booking.svelte';
    import ClockIcon from '$lib/images/icons/clock.svg';

    const bookingData = createBookingData();
    let startTimes = $state([
        '9:30 AM',
        '10:00 AM',
        '10:30 AM',
        '11:00 AM',
        '11:30 AM',
        '12:00 PM',
        '12:30 PM',
        '1:00 PM',
        '1:30 PM',
        '2:00 PM',
        '2:30 PM',
        '3:00 PM',
    ]);
    
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
    });
</script>

<div class="time-picker">
    <div class="fieldset">
        <h4 class="label">Time</h4>
        <p class="help">What time works best for you?</p>

        <div class="select" id="timeSelect">
            <button class="select-button" type="button">
                <span class="selected-value"></span>
                <img src={ClockIcon} alt="Pick a time">
            </button>
            <ul class="select-options hidden">
                {#each startTimes as time}
                    <li class="option" data-time={time}>{time}</li>
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
</style>