<script>
    // @ts-nocheck
    import { createBookingData, parseDate, unparseDate } from "$lib/data/booking.svelte";
    
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

    // let { ondateclick } = $props();

    let bookingData = createBookingData();
    let currentDate = new Date();
    let currentMonth = $derived(currentDate.getMonth());
    let currentYear = $derived(currentDate.getFullYear());

    let activeDate = $state(new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate()));
    let activeMonth = $derived(activeDate.getMonth());
    let activeYear = $derived(activeDate.getFullYear());
    let disabled = $derived(activeMonth <= currentMonth && activeYear === currentYear);

    // @ts-ignore
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
            // console.log('dateCursor', dateCursor);
            // console.log('dateCursor.getMonth() === activeMonth', dateCursor.getMonth() === activeMonth);
            // console.log('dateCursor.getDate() > activeDate.getDate()', dateCursor.getDate() > activeDate.getDate());
            // console.log('dateCursor > activeDate', dateCursor > activeDate);

            output.push({
                date: dateCursor,
                day: dateCursor.getDay(),
                active: dateCursor.getDay() !== 0 && (
                    dateCursor.getMonth() === activeMonth &&
                    dateCursor > currentDate
                    /* (
                        dateCursor.getMonth() === currentMonth &&
                        dateCursor.getDate() > activeDate.getDate()
                    ) || (
                        dateCursor.getMonth() > currentMonth &&
                        dateCursor.getMonth() === activeMonth
                    ) */
                )
            });
            dateValue.setDate(dateValue.getDate() + 1);
        }

        return output;
    });

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
                active: (dateCursor.getMonth() === currentMonth)
            });
            dateValue.setDate(dateValue.getDate() + 1);
        }

        return output;
    };

    const previousMonth = () => {
        // if (activeMonth <= currentMonth && activeYear === ) { return; }

        // let dateCursor = new Date(activeDate.getFullYear(), activeDate.getMonth(), 0);
        // console.log('previousMonth dateCursor', dateCursor);
        activeDate.setMonth(activeDate.getMonth() - 1);
        monthDates = getMonthDates();
        activeDate = new Date(activeDate.getFullYear(), activeDate.getMonth(), activeDate.getDate())
    };

    const nextMonth = () => {
        activeDate.setMonth(activeDate.getMonth() + 1);
        activeDate = new Date(activeDate.getFullYear(), activeDate.getMonth(), activeDate.getDate())
    };

    const selectDate = (e) => {
        // bookingData.date = e.target.dataset.date;
        bookingData.date = parseDate(e.target.dataset.date);
        // ondateclick();
    };

    let blockedDates = [ '20260106', '20260110' ];
</script>

{#snippet calendarDay(options)}
    <button type="button"
        class={[
            "date",
            { 
                outside: options.active === false || blockedDates.indexOf(unparseDate(options.date)) >= 0,
                selected: unparseDate(bookingData.date) === unparseDate(options.date)
            }
        ]}
        disabled={options.active === false || blockedDates.indexOf(unparseDate(options.date)) >= 0}
        data-date={unparseDate(options.date)}
        onclick={(options) => selectDate(options)}
    >
        {options.date.getDate()}
    </button>
{/snippet}

<div class="calendar">
    <div class="calendar-header">
        <button type="button" class={[ "nav", { disabled } ]} onclick={previousMonth}>&lt;</button>
        <span>{allMonths[activeMonth]} {activeYear}</span>
        <button type="button" class="nav" onclick={nextMonth}>&gt;</button>
    </div>
    <div class="grid">
        <div class="col">
            <div class="header">S</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 0) as monthDate}
                    {@render calendarDay(monthDate)}
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">M</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 1) as monthDate}
                    {@render calendarDay(monthDate)}
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">T</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 2) as monthDate}
                    {@render calendarDay(monthDate)}
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">W</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 3) as monthDate}
                    {@render calendarDay(monthDate)}
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">T</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 4) as monthDate}
                    {@render calendarDay(monthDate)}
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">F</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 5) as monthDate}
                    {@render calendarDay(monthDate)}
                {/each}
            </div>
        </div>
        <div class="col">
            <div class="header">S</div>
            <div class="dates">
                {#each monthDates.filter(d => d.day === 6) as monthDate}
                    {@render calendarDay(monthDate)}
                {/each}
            </div>
        </div>
    </div>
</div>

<style>
    .calendar {
        /* border: 1px solid var(--color-accent); */
        border: 1px solid var(--color-border-lite);
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
    .date {
        display: block;
        background-color: white;
        border: 0px solid red;
        padding: 0.5rem 0;
        cursor: pointer;
        border-radius: 0.25rem;
        font-size: var(--fs-sm);
    }
    .date:not(.outside):hover {
        background-color: var(--color-border-lite-extra);
    }
    .outside {
        color: var(--color-border-lite);
        cursor: not-allowed;
    }
    .selected {
        background-color: var(--color-bg-btn) !important;
    }
</style>