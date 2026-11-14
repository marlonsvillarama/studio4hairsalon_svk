<script>
    import { allCategories, allServices } from "$lib/data/services";
    import { getCartState } from "$lib/data/cart.svelte";
    import CartItem from "./cart-item.svelte";

    // const cartState = getCartState();
    let activeTab = $state(1);
    let activeServices = $derived.by(() => {
        return allServices.filter(s => s.category === activeTab)
            .map(d => {
                return {
                    ...d,
                    selected: getCartState().selectedServices.indexOf(d.id) >= 0
                }
            })
    });
    const selectTab = (id) => activeTab = id;
</script>

<div class="service-tabs">
    <ul>
        {#each allCategories as category}
            <li>
                <button type="button" class:active={activeTab === category.id}
                    onclick={() => selectTab(category.id)}
                >{category.name}</button>
            </li>
        {/each}
        <!-- <li><button type="button" class:active={activeTab === 'colours'}>Colours</button></li>
        <li><button type="button" class:active={activeTab === 'treatment'}>Treatment</button></li>
        <li><button type="button" class:active={activeTab === 'other'}>Others</button></li> -->
    </ul>
    <span class="reminder">You may choose one or more services.</span>
</div>
<div class="service-list">
    <div class="content">
        {#each activeServices as service}
            <CartItem {...service} />
        {/each}
    </div>
</div>

<style>
    .service-tabs {
        display: block;
        /* border: 1px solid red; */
        overflow-x: auto;
        overflow-y: hidden;
        /* scrollbar-width: none; */
        padding-bottom: 1rem;
    }
    .service-tabs > ul {
        display: flex;
        align-items: center;
        gap: 1.5rem;
        margin-bottom: 0.5rem;
    }
    .service-tabs > ul > li > button {
        cursor: pointer;
        font-size: 1rem;
        padding: 0.375rem 0.5rem;
        border-top: 4px solid transparent;
        transition: border-color 150ms ease-in-out;
    }
    .service-tabs > ul > li > button:hover {
        border-color: var(--dark-bg-pale);
    }
    .service-tabs > ul > li > button.active {
        background-color: var(--accent-very-light);
        border-color: var(--color-accent-400);
        font-weight: 600;
    }
    .service-tabs > .reminder {
        opacity: 0.6;
        font: italic 300 1rem var(--font-default);
    }

    .service-list {
        overflow-x: none;
        overflow-y: auto;
        /* border: 1px solid green; */
    }
    .service-list > .content {
        scrollbar-width: none;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }
</style>