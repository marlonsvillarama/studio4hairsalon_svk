<script>
    let { data } = $props();
    let { date, day, inMonth } = data;

    let outside = $derived(inMonth === false);
    console.log('CalendarDate > date', date);
    console.log('CalendarDate > day', day)
    console.log('CalendarDate > inMonth', inMonth);
</script>

<div class={[ "date", { outside } ]} data-date={date}>
    {date.getDate()}
</div>

<style>
    .date {
        display: block;
        border: 0px solid red;
        padding: 0.5rem 0;
        cursor: pointer;
        border-radius: 0.5rem;
        transition: all 100ms ease-in-out;
    }
    .date:not(.outside):hover {
        background-color: var(--color-border-lite-extra);
    }
    .outside {
        color: var(--color-border-lite);
        cursor: not-allowed;
    }
</style>