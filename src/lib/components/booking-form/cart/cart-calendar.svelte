<script></script>

<div class="appt-options">
    <span class="title">How do you want to book the services?</span>
    <button type="button" class="option">
        <span class="title">Grouped together</span>
        <div class="desc">We will find the soonest available time where all services can be availed.</div>
    </button>
    
    <button type="button" class="option">
        <span class="title">Pick a date/time for each service</span>
        <div class="desc">Choose a date and time for each service.</div>
    </button>

    <button type="button" class="option">
        <span class="title">Pick a date/time for each service</span>
        <div class="desc">Choose a date and time for each service.</div>
    </button>

    <button type="button" class="option">
        <span class="title">Pick a date/time for each service</span>
        <div class="desc">Choose a date and time for each service.</div>
    </button>

    <button type="button" class="option">
        <span class="title">Pick a date/time for each service</span>
        <div class="desc">Choose a date and time for each service.</div>
    </button>

    <button type="button" class="option">
        <span class="title">Pick a date/time for each service</span>
        <div class="desc">Choose a date and time for each service.</div>
    </button>

    <button type="button" class="option">
        <span class="title">Pick a date/time for each service</span>
        <div class="desc">Choose a date and time for each service.</div>
    </button>

    <button type="button" class="option">
        <span class="title">Pick a date/time for each service</span>
        <div class="desc">Choose a date and time for each service.</div>
    </button>
</div>

<style>
    .appt-options {
        margin-top: 0.5rem;
    }
    .appt-options > .title {
        display: block;
        font: 600 1rem var(--font-default);
        margin-bottom: 0.75rem;
    }
    .appt-options > .option {
        border: 1px solid var(--light);
        border-radius: 0.25rem;
        cursor: pointer;
        margin-top: 1.5rem;
        padding: 1rem 1.5rem;
        display: flex;
        align-items: flex-start;
        flex-direction: column;
        gap: 0.25rem;
        width: 100%;
    }
    .appt-options > .option > .title {
        font-weight: 500;
    }
    .appt-options > .option > .desc {
        color: var(--semi-dark);
        font: italic 300 0.875rem var(--font-default);
    }
</style>