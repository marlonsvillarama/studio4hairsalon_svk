<script>
// @ts-nocheck

    import { onMount } from "svelte";
    import { createBookingData } from "$lib/data/booking.svelte";
    import { createServicesData } from "$lib/data/services.svelte";
    import { linear } from "svelte/easing";

    const bookingData = createBookingData();
    const servicesData = createServicesData();
    let allServices = servicesData.list;

    const findServiceById = (id) => {
        return servicesData.services.find(d => d.id.toString() === id.toString());
    };

    const handleOptionSelect = (id) => {
        let container = document.getElementById('serviceSelect');
        let dropDown = container?.querySelector('.select-options');
        let selectButton = container?.querySelector('.select-button');
        
        const options = dropDown?.querySelectorAll('li');
        const selectedValue = selectButton?.querySelector('.selected-value');
        const option = dropDown?.querySelector(`[data-id="${id.toString()}"]`);

        options?.forEach(opt => opt.classList.remove('selected'));
        option.classList.add('selected');

        if (selectedValue) {
            servicesData.activeService = findServiceById(option.dataset.id);
            bookingData.service = option.dataset.id;

        // @ts-ignore
            let selectedText = `${option.dataset.category} - ${option.textContent.trim()}`;
            selectedValue.textContent = selectedText;
        }
    };

    const toggleDropdown = () => {
        let container = document.getElementById('serviceSelect');
        let dropDown = container?.querySelector('.select-options');
        
        const isOpen = dropDown?.classList.contains('hidden') === false;
        dropDown?.classList.toggle('hidden');
    };

    onMount(() => {
        let container = document.getElementById('serviceSelect');
        let selectButton = container?.querySelector('.select-button');
        let dropDown = container?.querySelector('.select-options');
        selectButton?.addEventListener('click', () => { toggleDropdown(); });

        const options = dropDown?.querySelectorAll('li.option');
        const selectedValue = selectButton?.querySelector('.selected-value');
        options?.forEach(option => {
            option.addEventListener('click', () => {
                // console.log('selectedId', option.dataset.id);
                handleOptionSelect(option.dataset.id);
                toggleDropdown();
            });
        });

        let serviceId = new URLSearchParams(location.search).get("id");
        if (!serviceId) { return; }

        handleOptionSelect(serviceId);
        servicesData.activeService = findServiceById(serviceId);
    });
</script>

<div class="service-picker">
    <div class="fieldset">
        <h4 class="label">Service</h4>
        <p class="help">What would you like to have?</p>
    
        <div class="select" id="serviceSelect">
            <button class="select-button" type="button">
                <span class="selected-value"></span>
                <span class="arrow"></span>
            </button>
            <ul class="select-options hidden">
                {#each allServices as category}
                    <li class="category">{category.name}</li>
                    {#each category.services as item}
                        <li class="option" data-id={item.id} data-category={category.name}>{item.name}</li>
                    {/each}
                {/each}
            </ul>
        </div>
    </div>

    {#if servicesData.activeService.description}
        <p class="help">{servicesData.activeService.description}</p>
    {/if}

    {#if !!servicesData.activeService.price === true}
    <div class="price">
        <span>About {servicesData.activeService.duration} minutes</span>
        <div>
            {#if servicesData.activeService.range === true}
                <span class="label">starts from</span>
            {/if}
            <span class="value">${servicesData.activeService.price}</span>
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
        /* margin-bottom: 0.25rem; */
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
    ul {
        position: absolute;
        top: 100%;
        left: 0;
        width: 100%;
        border: 1px solid var(--color-accent);
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
    ul::-webkit-scrollbar {
        width: 0.5rem;
    }
    ul::-webkit-scrollbar-track {
        background-color: #f1f1f1;
        border-radius: 0.5rem;
    }
    ul::-webkit-scrollbar-thumb {
        background-color: var(--color-grey-dark-03-rgb);
        border-radius: 0.5rem;
    }
    li {
        padding: 0.5rem 1.5rem;
        cursor: pointer;
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-sm);
        font-weight: 300;
        transition: all 150ms ease-in-out;
        border-radius: 0.25rem;
    }
    li.category {
        font-weight: 600;
        padding: 0.5rem 0;
        border-radius: 0;
        border-bottom: 2px solid var(--color-accent);
    }
    li.category:not(:first-of-type) {
        margin-top: 1rem;
    }
    /* li:not(.reminder) {
        display: flex;
        justify-content: space-between;
        align-items: center;
    } */
    /* li.selected {
        background-color: var(--color-accent);
        font-weight: 600;
    } */
    li:hover:not(.category),
    li:focus {
        background-color: #f2f2f2;
        font-weight: 400;
    }

    .price {
        /* border: 1px solid red; */
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