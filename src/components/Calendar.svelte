<script>
    // @ts-nocheck
    import { createBookingData } from "$lib/data/booking.svelte";
    import CalendarDate from "./CalendarDate.svelte";
    
    const allMonths = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
    ];

    let bookingData = createBookingData();
    let currentDate = new Date();
    let currentMonth = $derived(currentDate.getMonth());
    let currentYear = $derived(currentDate.getFullYear());

    let activeDate = $state(new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate()));
    let activeMonth = $derived(activeDate.getMonth());
    let activeYear = $derived(activeDate.getFullYear());

    // @ts-ignore
    // let monthDates = $state([]);
    let monthDates = $derived.by(() => {
        let output = [];
        let startOfMonth = new Date(activeYear, activeMonth, 1);
        let endOfMonth = new Date(activeYear, activeMonth + 1, 0);

        if (startOfMonth.getDay() > 0) {
            startOfMonth.setDate(startOfMonth.getDate() - startOfMonth.getDay());
        }

        if (endOfMonth.getDay() < 6) {
            endOfMonth.setDate(endOfMonth.getDate() + (6 - endOfMonth.getDay()));
        }

        let dateValue = new Date(startOfMonth.getFullYear(), startOfMonth.getMonth(), startOfMonth.getDate());
        while (dateValue <= endOfMonth) {
            let dateCursor = new Date(dateValue.getFullYear(), dateValue.getMonth(), dateValue.getDate());
            output.push({
                date: dateCursor,
                day: dateCursor.getDay(),
                inMonth: (dateCursor.getMonth() === currentMonth)
            });
            dateValue.setDate(dateValue.getDate() + 1);
        }

        console.log('output', output);
        return output;
    });
    let sundays = $derived(monthDates.filter(d => d.day === 0));
    let mondays = $derived(monthDates.filter(d => d.day === 1));
    let tuesdays = $derived(monthDates.filter(d => d.day === 2));
    let wednesdays = $derived(monthDates.filter(d => d.day === 3));
    let thursdays = $derived(monthDates.filter(d => d.day === 4));
    let fridays = $derived(monthDates.filter(d => d.day === 5));
    let saturdays = $derived(monthDates.filter(d => d.day === 6));

    const clearGrid = () => {
        const calendarGrid = document.querySelector('.calendar > .grid');
        const calendarDates = calendarGrid?.querySelectorAll('.dates');
        calendarDates?.forEach(d => d.textContent = '');
    };

    const getMonthDates = () => {
        let output = [];
        let startOfMonth = new Date(activeYear, activeMonth, 1);
        let endOfMonth = new Date(activeYear, activeMonth + 1, 0);

        if (startOfMonth.getDay() > 0) {
            startOfMonth.setDate(startOfMonth.getDate() - startOfMonth.getDay());
        }

        if (endOfMonth.getDay() < 6) {
            endOfMonth.setDate(endOfMonth.getDate() + (6 - endOfMonth.getDay()));
        }

        let dateValue = new Date(startOfMonth.getFullYear(), startOfMonth.getMonth(), startOfMonth.getDate());
        while (dateValue <= endOfMonth) {
            let dateCursor = new Date(dateValue.getFullYear(), dateValue.getMonth(), dateValue.getDate());
            output.push({
                date: dateCursor,
                day: dateCursor.getDay(),
                inMonth: (dateCursor.getMonth() === currentMonth)
            });
            dateValue.setDate(dateValue.getDate() + 1);
        }

        console.log('output', output);
        return output;
    };

    const previousMonth = () => {
        console.log('previousMonth');
        if (activeMonth <= currentMonth) { return; }

        activeDate.setMonth(activeDate.getMonth() - 1);
        monthDates = getMonthDates();
        activeDate = new Date(activeDate.getFullYear(), activeDate.getMonth(), activeDate.getDate())
        console.log('previousMonth END', activeDate);
    };

    const nextMonth = () => {
        console.log('nextMonth');
        // if (activeMonth <= currentMonth) { return; }

        // clearGrid();
        activeDate.setMonth(activeDate.getMonth() + 1);
        activeDate = new Date(activeDate.getFullYear(), activeDate.getMonth(), activeDate.getDate())
        // monthDates = getMonthDates();
        console.log('monthDates', monthDates);
        logDays();
        console.log('nextMonth END', activeDate);
    };

    const logDays = () => {
        console.log('logDays SUNDAY', sundays);
        console.log('logDays MONDAY', mondays);
        console.log('logDays TUESDAY', tuesdays);
        console.log('logDays WEDNESDAY', wednesdays);
        console.log('logDays THURSDAY', thursdays);
        console.log('logDays FRIDAY', fridays);
        console.log('logDays SATURDAY', saturdays);
    };
</script>

<div class="calendar">
    <div class="calendar-header">
        <button type="button" class="nav disabled" onclick={previousMonth}>&lt;</button>
        <span>{allMonths[activeMonth]} {activeYear}</span>
        <button type="button" class="nav" onclick={nextMonth}>&gt;</button>
    </div>
    <div class="grid">
        <div class="col">
            <div class="header">S</div>
            <div class="dates">
                {#each sundays as monthDate}
                    <CalendarDate data={monthDate} />
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">M</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 1) as monthDate}
                    <CalendarDate data={monthDate} />
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">T</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 2) as monthDate}
                    <CalendarDate data={monthDate} />
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">W</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 3) as monthDate}
                    <CalendarDate data={monthDate} />
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">T</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 4) as monthDate}
                    <CalendarDate data={monthDate} />
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">F</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 5) as monthDate}
                    <CalendarDate data={monthDate} />
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">S</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 6) as monthDate}
                    <CalendarDate data={monthDate} />
                {/each}
            </div>
        </div>
    </div>
</div>

<style>
    .calendar {
        border: 1px solid var(--color-accent);
        border-radius: 0.5rem;
        padding: 0.75rem 1.25rem;
        color: var(--color-grey-dark-03-rgb);
        text-align: center;
    }
    .calendar-header {
        padding-bottom: 0.5rem;
        border-bottom: 1px dashed var(--color-accent);
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
    }
    .calendar-header > span {
        font-size: var(--fs-md);
        font-weight: 700;
    }
    .nav {
        border: 0;
        border-radius: 0.25rem;
        padding: 0.5rem 1rem;
        background-color: var(--color-bg-btn);
        box-shadow: var(--button-shadow);
    }
    .nav:not(.disabled):hover {
        background-color: var(--color-bg-btn-hover);
    }
    .nav.disabled {
        background-color: white;
        color: var(--color-border-lite);
        cursor: not-allowed;
    }
    .grid {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        gap: 2px;
        /* flex-direction: row; */
        /* justify-content: space-between; */
        /* align-items: start; */
        font-size: var(--fs-sm);
    }
    .col {
        border: 0px solid red;
    }
    .header {
        font-weight: 500;
        padding: 0.5rem 0;
        border-bottom: 2px solid var(--color-accent);
    }
    .dates {
        display: flex;
        flex-direction: column;
    }
</style>