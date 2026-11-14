<script>
    import { allServices } from "$lib/data/services";
    import { getCartState } from "$lib/data/cart.svelte";
    import CartUser from "./cart-user.svelte";
    import CartNavigator from "./cart-navigator.svelte";

    const cartState = getCartState();

    cartState.currentUser.updateFirstName('Marlon');
    cartState.currentUser.updateLastName('Villarama');
    cartState.currentUser.updateEmail('marlonsvillarama@gmail.com');
    // cartState.currentUser.updatePhone('marlonsvillarama@gmail.com');

    let CartComponent = $derived(cartState.currentView?.content);
    let selectedServices = $state([]);

    let totalPriceDisplay = $derived(Intl.NumberFormat('en-US', {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    }).format(cartState.totalPrice));

    let totalDurationDisplay = $derived.by(() => {
        let hours = parseInt(cartState.totalDuration / 60);
        let minutes = cartState.totalDuration - parseInt(hours * 60);

        let hoursText = hours > 0 ? `${hours} hr` : '';
        let minutesText = hours > 0 && minutes > 0 ? ', ' : '';
        minutesText += hours > 0 ? (minutes > 0 ? `${minutes} min` : '') : `${minutes} min`
        return `${hoursText}${minutesText}`;
    });

    const toggleService = (id) => {
        if (selectedServices.indexOf(id) >= 0) {
            selectedServices = selectedServices.filter(s => s !== id);
        }
        else {
            selectedServices.push(id);
            selectedServices = selectedServices;
        }

        let items = allServices.filter(s => selectedServices.indexOf(s.id) >= 0);
        totalPrice = items.reduce((sum, next) => sum += next.price, 0);
        totalDuration = items.reduce((sum, next) => sum += next.duration, 0)
    };

    const submitCart = () => {
        console.log('TODO: submitCart')
    };
</script>

<div class="cart">
    <CartUser />

    <!-- <div class="header">
        <span class="total">
            <i class="ph ph-currency-circle-dollar"></i>
            {totalPriceDisplay}
        </span>
        <span class="time">
            <i class="ph ph-clock"></i>
            {totalDurationDisplay}
        </span>
    </div> -->

    <CartNavigator items={cartState.allSteps} bind:step={cartState.currentStep}
        onnext={() => updateStep()}
        onprevious={() => updateStep(-1)}
        onfinish={submitCart}
    />
    
    <div class="content">
        <CartComponent />
    </div>
</div>

<style>
    .cart {
        /* border: 1px solid red; */
        padding: 6rem 0 3rem;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        height: 100vh;
        max-height: 100vh;
        width: min(92%, 110rem);
        margin: 0 auto;
    }
    @media (min-width: 60rem) {
        .cart {
            padding: 6rem;
        }
    }
    .cart > .header {
        display: flex;
        /* flex-direction: column; */
        align-items: center;
        justify-content: space-between;
        width: 100%;
        padding: 0.5rem;
        /* border-bottom: 1px solid red; */
    }
    .cart > .header > h1 {
        color: var(--darkest);
        font: 600 1rem var(--font-serif);
    }
    .cart > .header > .details {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.25rem;
    }
    /* .cart > .header > .details > span { */
    .cart > .header > span {
        border: 1px solid var(--light);
        border-radius: 0.25rem;
        padding: 0.25rem 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    /* }
    .cart > .header > .details > .total { */
        color: var(--accent);
        font: 500 0.875rem var(--font-serif);
    }
    /* .cart > .header > .details > span > i { */
    .cart > .header > span > i {
        font-size: 1.25rem;
    }
    .cart > .content {
        padding: 0.5rem;
        flex: 1;
        overflow-y: auto;
        display: flex;
        flex-direction: column;
        /* gap: 1rem; */
        /* border: 1px solid red; */
        margin-bottom: 1rem;
    }
</style>