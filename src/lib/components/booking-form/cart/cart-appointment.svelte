<script>
    import { getCartState } from "$lib/data/cart.svelte";

    const cartState = getCartState();
    let dateDisplay = $derived(cartState.appointmentDate.toLocaleDateString('en-NZ', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    }));
    let timeDisplay = $derived(cartState.appointmentDate.toLocaleTimeString('en-NZ', {
        hour: '2-digit',
        minute: '2-digit',
        ampm: true
    }));

    let isDateOpen = $state(false);
    let isTimeOpen = $state(false);

    const showDate = () => {
        isTimeOpen = false;
        isDateOpen = !isDateOpen;
        console.log('isDateOpen', isDateOpen)
    };

    const showTime = () => {
        isDateOpen = false;
        isTimeOpen = !isTimeOpen;
    }

    const clickOutside = (node) => {
        const handleClick = (e) => {
            if (!node.contains(e.target)) {
                console.log('node', e.target);
                if (e.target.dataset.type === 'date') isDateOpen = false;
                if (e.target.dataset.type === 'time') isTimeOpen = false;
            }
        };

        document.addEventListener('click', handleClick);
        return {
            destroy() {
                document.removeEventListener('click', handleClick);
            }
        };
    };
</script>

<div class="appointment">
    <div class="btn-container">
        <button type="button" class="row" data-type="date" use:clickOutside onclick={showDate}>
            <i class="ph-thin ph-calendar"></i>
            <div class="details">
                <span class="title">Date</span>
                <span class="value">{dateDisplay}</span>
            </div>
        </button>
        {#if isDateOpen}
            <div class="appointment-popover" id="appointment-date">
                calendar
            </div>
        {/if}
    </div>

    <div class="btn-container">
        <button type="button" class="row" data-type="time" use:clickOutside onclick={showTime}>
            <i class="ph-thin ph-clock"></i>
            <div class="details">
                <span class="title">Time</span>
                <span class="value">{timeDisplay}</span>
            </div>
        </button>
        {#if isTimeOpen}
            <div class="appointment-popover" id="appointment-time">
                calendar
            </div>
        {/if}
    </div>
</div>

<style>
    .appointment {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        position: relative;
    }
    @media (min-width: 40rem) {
        .appointment {
            display: grid;
            grid-template-columns: 1fr 1fr;
        }
    }
    .appointment > .btn-container {
        position: relative;
    }
    .appointment > .btn-container > button {
        border: 1px solid var(--light);
        border-radius: 0.25rem;
        cursor: pointer;
        /* margin-top: 1rem; */
        padding: 1rem 1.5rem;
        display: flex;
        align-items: flex-start;
        /* flex-direction: column; */
        gap: 0.5rem;
        width: 100%;
        position: relative;
    }
    .appointment > .btn-container > .row > i {
        color: var(--dark);
        font-size: 2rem;
        opacity: 0.7;
    }
    .appointment > .btn-container > .row > .details {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 0.25rem;
    }
    .appointment > .btn-container > .row > .details > .title {
        color: var(--dark);
        font-size: 1rem;
        opacity: 0.6;
        padding-top: 0.25rem;
    }
    .appointment > .btn-container > .row > .details > .value {
        font-weight: 600;
    }
    .appointment > .btn-container > .appointment-popover {
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: var(--white);
        border: 1px solid var(--light);
        border-radius: 0.25rem;
        margin-top: 0.25rem;
        padding: 0;
    }
</style>