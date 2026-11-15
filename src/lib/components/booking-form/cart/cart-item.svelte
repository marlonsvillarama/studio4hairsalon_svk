<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import { formatPrice, formatDuration } from "$lib/data/services";

    let { id, name, price, goldCardPrice = null, duration = 30, range = false } = $props();

    const cartState = getCartState();
    let selected = $derived(cartState.isSelected(id));
    let gold = $derived(cartState.goldCard && goldCardPrice != null);
</script>

<button type="button" class="cart-item" class:selected aria-pressed={selected}
    onclick={() => cartState.toggleService(id)}>
    <span class="check" aria-hidden="true">
        <i class="ph ph-check"></i>
    </span>
    <span class="name">{name}</span>
    <span class="duration">{formatDuration(duration)}</span>
    <span class="price">
        {#if gold}
            <span class="gold-tag">Gold Card</span>
            {formatPrice(goldCardPrice)}
            <s class="was"><span class="sr-only">instead of </span>{formatPrice(price)}</s>
        {:else}
            {formatPrice(price, range)}
        {/if}
    </span>
</button>

<style>
    .cart-item {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        cursor: pointer;
        display: grid;
        grid-template-columns: 1.5rem 1fr auto;
        grid-template-areas:
            "check name price"
            "check duration price";
        align-items: center;
        column-gap: 0.875rem;
        row-gap: 0.125rem;
        min-height: 3.75rem;
        padding: 0.75rem 1rem;
        text-align: start;
        width: 100%;
        transition: background-color 150ms ease, border-color 150ms ease;
    }
    .cart-item:hover {
        border-color: var(--dark);
    }
    .cart-item.selected {
        background-color: var(--color-accent-50);
        border-color: var(--color-accent-700);
        box-shadow: inset 0 0 0 1px var(--color-accent-700);
    }
    .check {
        grid-area: check;
        display: grid;
        place-items: center;
        height: 1.5rem;
        width: 1.5rem;
        border: 1.5px solid var(--input-border);
        border-radius: 0.25rem;
        color: transparent;
        font-size: 1rem;
        transition: background-color 150ms ease, border-color 150ms ease, color 150ms ease;
    }
    .selected .check {
        background-color: var(--color-accent-700);
        border-color: var(--color-accent-700);
        color: var(--white);
    }
    .name {
        grid-area: name;
        color: var(--darkest);
        font: 600 1rem / 1.3 var(--font-default);
    }
    .duration {
        grid-area: duration;
        color: var(--dark);
        font-size: 0.875rem;
    }
    .price {
        grid-area: price;
        color: var(--darkest);
        font: 600 1rem var(--font-default);
        font-variant-numeric: tabular-nums;
        text-align: end;
        white-space: nowrap;
        display: flex;
        flex-wrap: wrap;
        align-items: baseline;
        justify-content: flex-end;
        column-gap: 0.375rem;
    }
    .gold-tag {
        background-color: var(--color-accent-100);
        border-radius: 0.25rem;
        color: var(--color-accent-800);
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.0625rem 0.375rem;
    }
    .was {
        color: var(--dark);
        font-size: 0.875rem;
        font-weight: 400;
    }
</style>
