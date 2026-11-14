<script>
    import { getCartState } from "$lib/data/cart.svelte";

    const cartState = getCartState();
    const cartUser = cartState.currentUser;
    const greeting = `Welcome${cartUser.isReturning ? ' back' : ''}, ${cartUser.firstName}!`;

    let totalPriceDisplay = $derived(Intl.NumberFormat('en-US', {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    }).format(cartState.totalPrice));

    let totalDurationDisplay = $derived.by(() => {
        let hours = parseInt(cartState.totalDuration / 60);
        let minutes = cartState.totalDuration - parseInt(hours * 60);

        let hoursText = hours > 0 ? `${hours} hr` : '';
        let minutesText = hours > 0 && minutes > 0 ? ' and ' : '';
        minutesText += hours > 0 ? (minutes > 0 ? `${minutes} min` : '') : `${minutes} min`
        return `${hoursText}${minutesText}`;
    });
</script>

<div class="cart-user">
    <span class="greeting">{greeting}</span>
    <div class="details">
        <!-- <button type="button" class="rebook">Rebook your last session?</button> -->
        <div class="totals">
            <span class="title">For this session</span>
            <div class="row">
                <span class="label">Subtotal</span>
                <span class="value">$ {totalPriceDisplay}</span>
            </div>
            <div class="row">
                <span class="label">Est. Duration</span>
                <span class="value">{totalDurationDisplay}</span>
            </div>
        </div>
    </div>
</div>

<style>
    .cart-user {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        width: 100%;
        padding: 0.5rem;
    }
    .cart-user > .greeting {
        color: var(--accent);
        font: 600 1.25rem var(--font-serif);
    }
    .cart-user > .details {
        border: 1px solid var(--light);
        border-radius: 0.25rem;
        padding: 0.5rem 1rem;
        width: 100%;
    }
    .cart-user > .details > .rebook {
        cursor: pointer;
        text-decoration: underline;
        color: blue;
        font: 400 1rem var(--font-default);
        margin-bottom: 0.5rem;
    }
    .cart-user > .details > .totals {
        color: var(--dark);
        font-size: 1rem;
    }
    .cart-user > .details > .totals > .title {
        font-weight: 600;
    }
    .cart-user > .details > .totals > .row {
        display: grid;
        grid-template-columns: 8rem 1fr;
        padding-left: 0.75rem;
    }
    .cart-user > .details > .totals > .row > .label {
        opacity: 0.6;
    }
    .cart-user > .details > .totals > .row > .value {
        /* opacity: 0.6; */
        font-weight: 600;
    }
</style>