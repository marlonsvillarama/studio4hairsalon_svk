<script>
    import CalendarIcon from '$lib/images/icons/calendar.svg';
    import Calendar from './Calendar.svelte';
</script>

<div class="date-picker">
    <div class="fieldset">
        <h4 class="label">Date</h4>
        <p class="help">When would you like to drop by?</p>

        <div class="select" id="dateSelect">
            <button class="select-button" type="button">
                <span class="selected-value">99 September, 2025 (Wednesday)</span>
                <img src={CalendarIcon} alt="Pick a date">
            </button>
            <Calendar />
        </div>
    </div>
</div>

<style>
    .date-picker {
        min-width: 20rem;
        width: 100%;
        display: flex;
        flex-direction: column;
        gap: 2rem;
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
        padding: 0.75rem 1.25rem;
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
</style>