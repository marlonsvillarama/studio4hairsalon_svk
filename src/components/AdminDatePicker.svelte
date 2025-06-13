<script>
    // @ts-nocheck
    
        import { onMount } from 'svelte';
        import { createAdminData } from '$lib/data/admin.svelte';
        import { parseDate } from '$lib/data/booking.svelte';
        import CalendarIcon from '$lib/images/icons/calendar.svg';
        import AdminCalendar from './AdminCalendar.svelte';
    
        const adminData = createAdminData();
        let { ondateselect } = $props();
        let hideCalendar = $state(true);
        let dateText = $derived.by(() => {
            console.log('dataText derived dt', adminData.selectedDate);
            return adminData.selectedDate ?
                adminData.selectedDate.toLocaleDateString('en-NZ', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                }) : '';
        });
        
        const selectDate = () => {
            console.log('selectDate from AdminDatePicker');
            hideCalendar = true;
            ondateselect();
        };

        const toggleCalendar = () => {
            console.log('toggleCalendar from AdminDatePicker');
            hideCalendar = !hideCalendar;
        };
    </script>
    
    <div class="date-picker">
        <div class="fieldset">
            <div class="select" id="dateSelect">
                <button class="select-button" type="button" onclick={toggleCalendar}>
                    <span class="selected-value">{dateText}</span>
                    <img src={CalendarIcon} alt="Pick a date">
                </button>
                <div class={[
                    "calendar",
                    { hidden: hideCalendar === true }
                ]}>
                    <AdminCalendar ondateselect={selectDate} />
                </div>
            </div>
        </div>
    </div>
    
    <style>
        .date-picker {
            /* min-width: 20rem; */
            width: 100%;
            display: flex;
            flex-direction: column;
            gap: 2rem;
            margin-bottom: 1rem;
        }
        .label {
            color: var(--color-grey-dark-03-rgb);
            font-size: var(--fs-md);
            font-weight: 500;
            /* margin-bottom: 0.25rem; */
            /* margin-left: 0.25rem; */
        }
        .help {
            color: var(--color-grey-dark-03-rgb);
            /* font-size: var(--fs-sm); */
            font-size: var(--fs-xs);
            font-style: italic;
            font-weight: 200;
            margin-bottom: 0.75rem;
            /* margin-left: 0.25rem; */
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
            border-radius: 0.25rem;
            cursor: pointer;
            font-size: var(--fs-ssm);
            font-weight: 600;
            padding: 0.5rem 0.75rem;
            width: 100%;
        }
        .selected-value {
            color: var(--color-grey-dark-03-rgb);
        }
        img {
            width: 1.25rem;
            height: 1.25rem;
            /* border-left: 0.5rem solid transparent;
            border-right: 0.5rem solid transparent;
            border-top: 0.5rem solid var(--color-grey-dark-03-rgb);
            transition: transform ease-in-out 300ms; */
        }
        .calendar {
            position: absolute;
            top: 100%;
            left: 0;
            width: 100%;
            background-color: white;
            /* border: 1px solid var(--color-accent); */
            border-radius: 0.25rem;
            margin: 0.125rem 0 0;
            box-shadow: var(--button-shadow);
            z-index: 9999;
        }
    </style>