<script>
// @ts-nocheck

    import { onMount } from "svelte";
    import { createBookingData } from "$lib/data/booking.svelte";
    import { createServicesData } from "$lib/data/services.svelte";
    import { linear } from "svelte/easing";

    const bookingData = createBookingData();
    const servicesData = createServicesData();
    let activeService = $state('');
    let activeServiceName = $state('');
    let allServices = servicesData.list;
    let hideOptions = $state(true);
    
    const selectOption = (id) => {
        activeService = id ? servicesData.getServiceById(id) : '';
        activeServiceName = id ?  `${activeService.category.name} - ${activeService.name}` : '';
        bookingData.service = id || '';
        hideOptions = true;
    };

    const toggleDropdown = () => {
        hideOptions = !hideOptions;
    };

    onMount(() => {
        let serviceId = new URLSearchParams(location.search).get("id");
        selectOption(parseInt(serviceId || '0'));
    });
</script>

<div class="service-picker">
    <div class="fieldset">
        <h4 class="label">Service</h4>
        <p class="help">What would you like to have?</p>

        <div class="select" id="serviceSelect">
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button class="select-button" type="button"
                onclick={() => { hideOptions = !hideOptions }}
            >
                <span class="selected-value">{activeServiceName}</span>
                <span class="arrow"></span>
            </button>
            
            <div
                onblur={() => { hideOptions = true }}
                class={[
                    "select-options",
                    { hidden: hideOptions === true }
                ]}
            >
                {#each allServices as category}
                    <div class="category">{category.name}</div>
                    {#each category.services as item}
                        <div class="option"
                            data-id={item.id}
                            data-category={category.name}
                            onclick={() => { selectOption(item.id) }}
                        >{item.name}</div>
                    {/each}
                {/each}
            </div>
        </div>
    </div>

    {#if activeService}
        <p class="help">{activeService.description}</p>
        
        <div class="price">
            <span>About {activeService.duration} minutes</span>
            <div>
                {#if activeService.range === true}
                    <span class="label">starts from</span>
                {/if}
                <span class="value">${activeService.price}</span>
            </div>
        </div>
    {/if}
</div>

<style>
    .service-picker {
        min-width: 20rem;
        width: 100%;
        display: flex;
        flex-direction: column;
        gap: 1rem;
        margin-bottom: 2rem;
    }
    .fieldset,
    .price {
        width: 100%;
    }
    .label {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-md);
        font-weight: 500;
        margin-left: 0.25rem;
    }
    .help {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-sm);
        font-style: italic;
        font-weight: 200;
        margin-bottom: 0.25rem;
        margin-left: 0.25rem;
    }
    .select {
        position: relative;
        display: inline-block;
        width: 100%;
    }
    .select-button {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background-color: white;
        border: 1px solid var(--color-border-lite);
        border-radius: 0.5rem;
        cursor: pointer;
        font-size: var(--fs-sm);
        padding: 0.75rem 1.25rem;
        width: 100%;
    }
    .selected-value {
        color: var(--color-grey-dark-03-rgb);
    }
    .arrow {
        border-left: 0.5rem solid transparent;
        border-right: 0.5rem solid transparent;
        border-top: 0.5rem solid var(--color-grey-dark-03-rgb);
        transition: transform ease-in-out 300ms;
    }
    .select-options {
        position: absolute;
        top: 100%;
        left: 0;
        width: 100%;
        border: 1px solid var(--color-border-lite);
        border-radius: 0.5rem;
        background-color: white;
        list-style: none;
        padding: 0.75rem 1.25rem;
        margin: 0.5rem 0 0;
        box-shadow: var(--button-shadow);
        max-height: 15rem;
        overflow-y: auto;
        z-index: 9999;
    }
    .select-options::-webkit-scrollbar {
        width: 0.75rem;
    }
    .select-options::-webkit-scrollbar-track {
        background-color: var(--color-border-lite);
        border-radius: 0.5rem;
    }
    .select-options::-webkit-scrollbar-thumb {
        background-color: var(--color-grey-dark-03-rgb-lite);
        border-radius: 0.5rem;
    }
    .select-options > * {
        padding: 0.5rem 1.5rem;
        cursor: pointer;
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-sm);
        font-weight: 300;
        transition: all 150ms ease-in-out;
        border-radius: 0.25rem;
        display: block;
    }
    .select-options > .category {
        font-weight: 600;
        padding: 0.5rem 0;
        border-radius: 0;
        border-bottom: 2px solid var(--color-accent);
    }
    .select-options > .category:not(:first-of-type) {
        margin-top: 1rem;
    }
    .select-options > *:hover:not(.category),
    .select-options > *:focus {
        background-color: #f2f2f2;
    }

    .price {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        padding: 1rem 2rem;
        border: 0;
        border-radius: 0.5rem;
        background-color: var(--color-border-lite-extra);
        font-weight: 200;
    }
    .value {
        margin-left: 1rem;
        font-weight: 500;
        font-size: var(--fs-xl);
    }
</style>