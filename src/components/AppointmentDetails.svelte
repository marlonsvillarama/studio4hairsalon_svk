<script>
// @ts-nocheck

    import { createAdminData } from '$lib/data/admin.svelte';
    import CalendarIcon from '$lib/images/icons/calendar.svg';
    import ClockIcon from '$lib/images/icons/clock.svg';
    import UserIcon from '$lib/images/icons/user.svg';
    import PhoneIcon from '$lib/images/icons/phone.svg';
    import EmailIcon from '$lib/images/icons/email.svg';
    import { parseDate, parseTime, writeDateString } from '$lib/data/booking.svelte';
    import { onMount } from 'svelte';

    let { data } = $props();

    const changeService = () => {};

    const changeDateTime = () => {};
</script>

<div class="content">

    <div class="detail">
        <!-- <div class="header">
            <h3><span class="bold">{data ? parseTime(data?.time) : ''}</span> | {data?.service?.name}</h3>
        </div> -->
        <div class="contents">
            <div class="row">
                <img src={UserIcon}>
                <span class="name">{data?.name}</span>
            </div>
            <div class="row">
                <img src={EmailIcon}>
                <span class="name">{data?.email}</span>
            </div>
            <div class="row">
                <img src={PhoneIcon}>
                <span class="name">{data?.phone}</span>
            </div>
        </div>
    </div>

    <div>
        <div class="detail">
            <div class="contents">
                <span class="bold">{data.service?.name}</span>
            </div>
        </div>
    
        <div class="actions">
            <button>Change the service</button>
        </div>
    </div>

    <div>
        <div class="detail">
            <div class="contents">
                <div class="row">
                    <img src={CalendarIcon}>
                    <span>{ writeDateString(parseDate(data.dt)) }</span>
                </div>
                <div class="row">
                    <img src={ClockIcon}>
                    <span>{parseTime(data.time)}</span>
                </div>
            </div>
        </div>
    
        <div class="actions">
            <button>Change the date/time</button>
        </div>
    </div>
    
</div>

<style>
    .content > *:not(:last-child) {
        margin-bottom: 1rem;
    }
    .detail {
        background-color: white;
        border: 1px solid var(--color-border-lite-extra);
        /* border: ; */
        border-left: 3px solid var(--color-accent);
        border-radius: 0.25rem;
        color: var(--color-grey-dark-03-rgb);
        /* cursor: pointer; */
    }
    .header {
        display: flex;
        flex-direction: flex;
        justify-content: space-between;
        align-items: center;
        /* gap: 0.25rem; */
        padding: 0.25rem 0.75rem;
        border-bottom: 1px solid var(--color-accent);
    }
    .header h3 {
        font-size: var(--fs-xxs);
        font-weight: 300;
    }
    .header .bold {
        font-weight: 700;
        /* border: 1px solid red; */
    }
    .header span {
        font-size: var(--fs-xs);
    }
    .contents {
        padding: 0.25rem 0.75rem;
        font-size: var(--fs-xxs);
        /* display: grid;
        gap: 1rem;
        grid-template-columns: 60% calc(40% - 1rem); */
    }
    /* .col {
        border: 1px solid red;
    } */
    .contents > *:not(:last-child) {
        /* margin-bottom: 0.125rem; */
        margin-bottom: 0;
    }
    .row {
        display: grid;
        grid-template-columns: 1.5rem auto;
        /* border: 1px solid green; */
        align-items: center;
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-xxs);
    }
    .row img {
        height: 0.75rem;
    }

    .actions {
        /* border: 1px solid red; */
        width: 100%;
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        gap: 0.5rem;
        padding: 0 0 0.25rem;
    }
    .actions button {
        width: 100%;
        font-size: var(--fs-xxs);
        padding: 0.5rem 0.25rem;
        border: 1px solid var(--color-border-lite);
        border-radius: 0.25rem;
        transition: all 150ms ease-in-out;
    }
</style>