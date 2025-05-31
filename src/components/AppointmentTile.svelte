<script>
    import { createAdminData } from '$lib/data/admin.svelte';
    import UserIcon from '$lib/images/icons/user.svg';
    import PhoneIcon from '$lib/images/icons/phone.svg';
    import EmailIcon from '$lib/images/icons/email.svg';
    import { parseTime } from '$lib/data/booking.svelte';

    let adminData = createAdminData();
    let { data } = $props();

    let collapse = $derived(adminData.listDisplay === true)

    const viewDetail = () => {
        // adminData.appointment = data;
        window.location.href = `/admin/appointment?id=${data.id}`;
    };
</script>

<div class="tile" onclick={viewDetail}>
    <div class="header">
        <h3><span class="bold">{data ? parseTime(data.time) : ''}</span> | {data?.service?.name}</h3>
    </div>
    <div class="contents">
        <!-- <div class="col"> -->
            <div class="row">
                <img src={UserIcon}>
                <span class="name">{data?.name}</span>
            </div>
            <div class={[
                "row",
                { hidden: collapse === true }
            ]}>
                <img src={EmailIcon}>
                <span class="name">{data?.email}</span>
            </div>
            <div class={[
                "row",
                { hidden: collapse === true }
            ]}>
                <img src={PhoneIcon}>
                <span class="name">{data?.phone}</span>
            </div>
            <!-- <div class="row">
                <img src={ClockIcon}>
                <span>About 30 minutes</span>
            </div> -->
            <!-- <div class="row">
                <img src={DollarIcon}>
                <span>starts from $110</span>
            </div> -->
        <!-- </div> -->
    </div>
    <!-- <div class="actions">
        <button class="cta">Edit</button>
        <button class="delete">Delete</button>
    </div> -->
</div>

<style>
    .tile {
        background-color: white;
        border: 1px solid var(--color-border-lite-extra);
        /* border: ; */
        border-left: 3px solid var(--color-accent);
        border-radius: 0.25rem;
        color: var(--color-grey-dark-03-rgb);
        cursor: pointer;
    }
    .tile:not(:last-of-type) {
        margin-bottom: 1rem;
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
        font-size: var(--fs-xs);
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
        font-size: var(--fs-xs);
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
        padding: 0 0.25rem 0.25rem;
    }
    .actions button {
        width: 100%;
        font-size: var(--fs-xs);
        padding: 0.3125rem 0.25rem;
        border: 1px solid var(--color-border-lite);
        border-radius: 0.25rem;
        transition: all 150ms ease-in-out;
    }
    button.cta {
        background-color: var(--color-bg-btn);
        border: 1px solid var(--color-bg-btn);
        font-weight: 700;
    }
    button.cta:hover {
        background-color: var(--color-bg-btn-hover);
    }
    button.delete {
        background-color: white;
        border: 1px solid var(--color-border-lite);
        color: var(--color-grey-lite-01);
    }
    button.delete:hover {
        border: 1px solid var(--color-grey-dark-03-rgb-lite);
        color: var(--color-grey-dark-03-rgb-dark);
    }
</style>