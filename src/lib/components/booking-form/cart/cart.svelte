<script>
    import { onMount, tick } from "svelte";
    import { getCartState, STEPS } from "$lib/data/cart.svelte";
    import CartServices from "./cart-services.svelte";
    import CartAppointment from "./cart-appointment.svelte";
    import CartDetails from "./cart-details.svelte";
    import CartReview from "./cart-review.svelte";
    import CartConfirmed from "./cart-confirmed.svelte";
    import CartNavigator from "./cart-navigator.svelte";

    const cartState = getCartState();

    const views = {
        services: CartServices,
        appointment: CartAppointment,
        details: CartDetails,
        review: CartReview
    };
    let View = $derived(views[cartState.currentStep.id]);

    let initialCategory = $state(1);
    let heading = $state();

    onMount(() => {
        cartState.init();
        // Deep link from the home page, e.g. /book?category=2. Read on the
        // client because /book is prerendered.
        const category = Number(new URLSearchParams(window.location.search).get('category'));
        if (category) initialCategory = category;
    });

    // Move focus to the step heading when the step changes, so keyboard and
    // screen-reader users land at the start of the new step.
    let lastStep = -1;
    $effect(() => {
        const step = cartState.step;
        const done = cartState.status === 'done';
        if (lastStep !== -1 && (step !== lastStep || done)) {
            tick().then(() => heading?.focus());
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
        lastStep = step;
    });
</script>

<div class="cart">
    <header class="cart-header">
        <img class="avatar" src="/images/john-avatar.webp" alt="" width="48" height="48" />
        <div>
            <h1>Book with John</h1>
            <p>Studio 4 Hair Salon · 7 George Street, Palmerston North</p>
        </div>
    </header>

    {#if cartState.loadState === 'loading'}
        <div class="state" role="status">
            <span class="spinner" aria-hidden="true"></span>
            Loading services and times…
        </div>
    {:else if cartState.loadState === 'error'}
        <div class="state error" role="alert">
            <p>{cartState.loadError}</p>
            <p>You can also book by calling me on <a href="tel:+64221885240">022 188 5240</a>.</p>
            <button type="button" class="retry" onclick={cartState.init}>Try again</button>
        </div>
    {:else if cartState.status === 'done'}
        <CartConfirmed bind:heading />
    {:else if !cartState.schedule?.onlineBooking}
        <div class="state" role="status">
            <p><strong>Online booking is paused at the moment.</strong></p>
            <p>Call or text me on <a href="tel:+64221885240">022 188 5240</a> and I'll book you in.</p>
        </div>
    {:else}
        <ol class="steps" aria-label="Booking progress">
            {#each STEPS as step, i}
                <li class:current={i === cartState.step} class:complete={i < cartState.step}
                    aria-current={i === cartState.step ? 'step' : undefined}>
                    {#if i < cartState.step}
                        <button type="button" onclick={() => cartState.goTo(step.id)}>
                            <span class="marker"><i class="ph ph-check" aria-hidden="true"></i></span>
                            <span class="label">{step.label}<span class="sr-only"> (completed, edit)</span></span>
                        </button>
                    {:else}
                        <span class="marker">{i + 1}</span>
                        <span class="label">{step.label}</span>
                    {/if}
                </li>
            {/each}
        </ol>

        <section class="step" aria-labelledby="step-heading">
            <h2 id="step-heading" tabindex="-1" bind:this={heading}>
                <span class="sr-only">Step {cartState.step + 1} of {STEPS.length}: </span>
                {#if cartState.currentStep.id === 'services'}What would you like done?
                {:else if cartState.currentStep.id === 'appointment'}When suits you?
                {:else if cartState.currentStep.id === 'details'}Who's coming in?
                {:else}Check and confirm{/if}
            </h2>
            <View {initialCategory} />
        </section>

        <CartNavigator />
    {/if}
</div>

<style>
    .cart {
        padding: 5rem 0 0;
        width: min(100% - 2rem, 44rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 1.75rem;
        min-height: 100vh;
    }
    @media (min-width: 40rem) {
        .cart {
            padding-top: 7.5rem;
        }
    }
    @media (min-width: 60rem) {
        .cart {
            padding-top: 8.5rem;
            width: min(100% - 6rem, 44rem);
        }
    }

    .cart-header {
        display: flex;
        align-items: center;
        gap: 1rem;
    }
    .cart-header > .avatar {
        border-radius: 50%;
        flex: none;
        height: 3rem;
        width: 3rem;
        object-fit: cover;
    }
    .cart-header h1 {
        color: var(--darkest);
        font: 700 clamp(1.5rem, 4vw, 2rem) / 1.15 var(--font-serif);
        text-wrap: balance;
    }
    .cart-header p {
        color: var(--dark);
        font-size: 0.875rem;
        margin-top: 0.25rem;
    }
    @media (min-width: 60rem) {
        /* The full photo of John sits beside the form on wide screens. */
        .cart-header > .avatar {
            display: none;
        }
    }

    .steps {
        list-style: none;
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 0.5rem;
        counter-reset: none;
    }
    .steps > li,
    .steps > li > button {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 0.5rem;
        color: var(--dark);
        font-size: 0.8125rem;
        font-weight: 500;
        line-height: 1.2;
        text-align: left;
    }
    .steps > li {
        border-top: 3px solid var(--light);
        padding-top: 0.625rem;
    }
    .steps > li.complete {
        border-color: var(--color-accent-600);
    }
    .steps > li.current {
        border-color: var(--darkest);
        color: var(--darkest);
        font-weight: 700;
    }
    .steps > li > button {
        cursor: pointer;
        width: 100%;
    }
    .steps > li > button:hover .label {
        text-decoration: underline;
        text-underline-offset: 3px;
    }
    .steps .marker {
        display: inline-grid;
        place-items: center;
        height: 1.5rem;
        width: 1.5rem;
        border-radius: 50%;
        border: 1px solid currentColor;
        font-size: 0.75rem;
        font-variant-numeric: tabular-nums;
    }
    .steps > li.current .marker {
        background-color: var(--darkest);
        border-color: var(--darkest);
        color: var(--white);
    }
    .steps > li.complete .marker {
        background-color: var(--color-accent-400);
        border-color: var(--color-accent-400);
        color: var(--darkest);
    }
    @media (max-width: 30rem) {
        /* On narrow phones only the current step keeps its label. */
        .steps > li:not(.current) .label {
            position: absolute;
            width: 1px;
            height: 1px;
            overflow: hidden;
            clip-path: inset(50%);
            white-space: nowrap;
        }
    }

    .step {
        display: flex;
        flex-direction: column;
        gap: 1.25rem;
        flex: 1;
    }
    .step > h2 {
        color: var(--darkest);
        font: 600 1.375rem / 1.25 var(--font-default);
        letter-spacing: -0.01em;
    }
    .step > h2:focus {
        outline: none;
    }

    .state {
        border: 1px solid var(--light);
        border-radius: 0.25rem;
        color: var(--charcoal);
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 0.75rem;
        line-height: 1.5;
        padding: 1.5rem;
    }
    .state:has(.spinner) {
        flex-direction: row;
        align-items: center;
        color: var(--dark);
    }
    .state.error {
        background-color: var(--error-bg);
        border-color: var(--error);
    }
    .state a {
        color: var(--darkest);
        font-weight: 600;
        white-space: nowrap;
    }
    .retry {
        background-color: var(--color-accent-400);
        color: var(--darkest);
        cursor: pointer;
        font-weight: 600;
        min-height: 2.75rem;
        padding: 0 1.25rem;
    }
    .retry:hover {
        background-color: var(--color-accent-500);
    }
    .spinner {
        height: 1.25rem;
        width: 1.25rem;
        border: 2px solid var(--light);
        border-top-color: var(--darkest);
        border-radius: 50%;
        animation: spin 700ms linear infinite;
    }
    @keyframes spin {
        to { transform: rotate(1turn); }
    }
</style>
