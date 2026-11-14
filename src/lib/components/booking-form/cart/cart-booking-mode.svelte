<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import CartBookTogether from "./cart-book-together.svelte";
    import CartBookSeparated from "./cart-book-separated.svelte";

    const cartState = getCartState();
    let page = $state('home')

    const selectMode = (value) => {
        cartState.updateBookingMode(value);
        console.log('selected Mode ==>', cartState.currentBookingMode)
    };
</script>

<div class="appt-options">
    <span class="title">How do you want to book the services?</span>

    {#if page === 'home'}
        {#each cartState.allBookingModes as mode}
            <button type="button" class="option" data-booking-mode={mode.id}
                class:selected={ cartState.currentBookingMode === mode.id }
                onclick={() => selectMode(mode.id)}>
                <span class="title">{mode.name}</span>
                <div class="desc">{mode.desc}</div>
            </button>
        {/each}
    {:else if page === 'together'}
    {:else if page === 'separate'}
    {/if}
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
    .appt-options > .option.selected {
        background-color: var(--color-accent-50);
        border-color: var(--color-accent-400);
    }
    .appt-options > .option > .title {
        font-weight: 500;
    }
    .appt-options > .option > .desc {
        color: var(--semi-dark);
        font: italic 300 0.875rem var(--font-default);
        text-align: left;
    }
</style>