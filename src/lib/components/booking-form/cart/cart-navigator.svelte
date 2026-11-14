<script>
    import { getCartState } from "$lib/data/cart.svelte";
    let {
        // items = [],
        // step = $bindable(),
        // onnext,
        // onprevious,
        // onfinish
    } = $props();

    const cartState = getCartState();
    // console.log('items', cartState.allSteps);
    console.log('step', cartState.currentStep);
    // let currentItem = $derived(items[step]);
    // let prevItem = $derived(step > 0 ? items[step - 1] : null);
    // let nextItem = $derived(step < items.length - 1 ? items[step + 1] : null);

    // const updateStep = (inc = 1) => {
    //     if (step === 0 && inc < 0) return;
    //     if (step === items.length - 1 && inc > 0) return;

    //     step = step + inc;
    //     console.log('updateStep step ==>', step);
    //     if (inc > 0) onnext();
    //     if (inc < 0) onprevious();
    // };
</script>

<div class="navigator">
    <button type="button" id="navigator-back"
        class:disabled={cartState.currentStep === 0}
        onclick={() => cartState.updateStep(-1)}
    >&lt; Back</button>

    <span class="current">{cartState.currentView?.label}</span>

    {#if cartState.currentStep < cartState.allSteps.length - 1}
        <button type="button" id="navigator-next"
            class:disabled={cartState.currentStep === cartState.allSteps.length - 1}
            onclick={() => cartState.updateStep()}>Next &gt;</button>
            <!-- {/if} -->
        <!-- </div> -->
    {:else}
        <button type="button" id="navigator-submit"
            onclick={onfinish}>Submit</button>
    {/if}
    <!-- {#each items as item}
        <button>{item.label}</button>
    {/each} -->
</div>

<style>
    .navigator {
        /* border-top: 1px solid var(--light); */
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 0.5rem;
    }
    .navigator > button {
        border-radius: 0.25rem;
        cursor: pointer;
        font: 500 0.875rem var(--font-default);
        padding: 0.5rem 1rem;
        transition: background-color 150ms ease-in-out;
    }
    #navigator-back {
        background-color: var(--lighter);
    }
    #navigator-back:hover {
        background-color: var(--light);
    }
    #navigator-next {
        background-color: var(--accent-lighter);
    }
    #navigator-next:hover {
        background-color: var(--accent-light);
    }
    #navigator-back.disabled,
    #navigator-next.disabled {
        background-color: var(--lighter);
        color: var(--semi-dark);
        cursor: not-allowed;
    }
    .navigator > .current {
        /* background-color: var(--lighter); */
        /* border: 1px solid var(--light); */
        border-radius: 0.25rem;
        font: 600 0.875rem var(--font-default);
        padding: 0.5rem 1rem;
    }
</style>