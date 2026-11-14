<script>
    import { getCartState } from "$lib/data/cart.svelte";

    let {
        onclick,
        id,
        category,
        name,
        price,
        duration = 30,
        range = false,
        selected = false
    } = $props();

    const cartState = getCartState();
    const toggleItem = () => {
        selected = !selected;
        selected ? cartState.addService(id) : cartState.removeService(id);
    };
</script>

<button type="button" class={[ "cart-item", selected ? 'selected' : '' ]} onclick={toggleItem}>
    <span class="name">{name}</span>
    <div class="details">
        <span class="duration">Usually takes {duration} minutes</span>
        <span class="price">{Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(price)}</span>
    </div>
</button>

<style>
    .cart-item {
        display: flex;
        flex-direction: column;
        gap: 0.125rem;
        padding: 0.75rem 1rem;
        /* background-color: var(--white); */
        border: 1px solid var(--lighter);
        border-radius: 0.25rem;
        cursor: pointer;
        text-align: start;
        margin-right: 0.75rem;
    }
    .cart-item.selected {
        background-color: var(--color-accent-50);
        border-color: var(--color-accent-400);
    }
    /* .cart-item:not(:last-of-type) {
        border-bottom: 1px solid var(--dark-bg-pale);
    } */
    .cart-item > .name {
        color: var(--dark);
        font: 600 1rem var(--font-default);
    }
    .cart-item > .details {
        display: flex;
        align-items: center;
        justify-content: space-between;
        /* border: 1px solid transparent; */
        /* border: 1px solid red; */
    }
    .cart-item > .details > .duration {
        opacity: 0.5;
        font: italic 400 1rem var(--font-default);
    }
    .cart-item > .details > .price {
        color: var(--color-accent-700);
        font: 600 1rem var(--font-default);
    }
</style>