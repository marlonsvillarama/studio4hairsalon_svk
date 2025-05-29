<script>
    import ClockIcon from '$lib/images/icons/clock.svg';
    import DollarIcon from '$lib/images/icons/dollar.svg';
    import UserIcon from '$lib/images/icons/user.svg';
    import PhoneIcon from '$lib/images/icons/phone.svg';
    import EmailIcon from '$lib/images/icons/email.svg';

    let { data } = $props();
</script>

<div class="tile">
    <div class="header">
        <h3><span class="bold">Category</span> | Service name</h3>
    </div>
    <div class="contents">
        <!-- <div class="col"> -->
            <div class="row">
                <img src={UserIcon}>
                <span class="name">Jerolyn Villarama</span>
            </div>
            <div class="row">
                <img src={PhoneIcon}>
                <span class="name">0227000215</span>
            </div>
            <div class="row">
                <img src={EmailIcon}>
                <span class="name">apple.linson02@yahoo.com</span>
            </div>
            <!-- </div>
        <div class="col"> -->
            <div class="row">
                <img src={ClockIcon}>
                <span>About 30 minutes</span>
            </div>
            <!-- <div class="row">
                <img src={DollarIcon}>
                <span>starts from $110</span>
            </div> -->
        <!-- </div> -->
    </div>
</div>

<style>
    .tile {
        border: 1px solid var(--color-border-lite);
        border-radius: 0.5rem;
        color: var(--color-grey-dark-03-rgb);
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
        padding: 0.5rem 0.75rem;
        /* display: grid;
        gap: 1rem;
        grid-template-columns: 60% calc(40% - 1rem); */
    }
    /* .col {
        border: 1px solid red;
    } */
    .contents > *:not(:last-child) {
        margin-bottom: 0.25rem;
    }
    .row {
        display: grid;
        grid-template-columns: 2rem auto;
        /* border: 1px solid green; */
        align-items: center;
        color: var(--color-grey-dark-03-rgb);
    }
    .row img {
        height: 1rem;
    }
</style>