<script>
    import { formatPrice } from "$lib/data/services";
    import { getCartState } from "$lib/data/cart.svelte";
    import CartItem from "./cart-item.svelte";

    const cartState = getCartState();
    let allCategories = $derived(cartState.catalogue.categories);
    let allServices = $derived(cartState.catalogue.services);

    let { initialCategory = 1 } = $props();

    let activeTab = $state(cartState.catalogue.categories[0]?.id ?? 1);
    // Follow a deep-linked category (?category=2) once it's read on the client.
    $effect(() => {
        if (allCategories.some(c => c.id === initialCategory)) activeTab = initialCategory;
    });

    let inTab = $derived(allServices.filter(s => s.category === activeTab));
    let regular = $derived(inTab.filter(s => !s.addon));
    let goldCardItems = $derived(inTab.filter(s => s.goldCardPrice != null));
    let addOns = $derived(inTab.filter(s => s.addon));

    const tabs = $state([]);
    // Arrow keys move between tabs, as screen-reader users expect.
    const onTabKey = (e, index) => {
        const keys = { ArrowRight: 1, ArrowLeft: -1, Home: -index, End: allCategories.length - 1 - index };
        if (!(e.key in keys)) return;
        e.preventDefault();
        const next = (index + keys[e.key] + allCategories.length) % allCategories.length;
        activeTab = allCategories[next].id;
        tabs[next]?.focus();
    };
</script>

<div class="tabs" role="tablist" aria-label="Service type">
    {#each allCategories as category, i}
        <button type="button" role="tab" id="tab-{category.slug}"
            aria-selected={activeTab === category.id}
            aria-controls="panel-services"
            tabindex={activeTab === category.id ? 0 : -1}
            bind:this={tabs[i]}
            onclick={() => activeTab = category.id}
            onkeydown={(e) => onTabKey(e, i)}
        >{category.name}</button>
    {/each}
</div>

<div class="panel" id="panel-services" role="tabpanel"
    aria-labelledby="tab-{allCategories.find(c => c.id === activeTab)?.slug}">
    {#if goldCardItems.length}
        <label class="gold-card" class:on={cartState.goldCard}>
            <input type="checkbox" role="switch" checked={cartState.goldCard}
                aria-describedby="gold-card-detail"
                onchange={(e) => cartState.setGoldCard(e.currentTarget.checked)} />
            <span class="switch" aria-hidden="true"></span>
            <span class="text">
                <span class="title">I have a Gold Card</span>
                <span class="detail" id="gold-card-detail">
                    {goldCardItems.map(s => `${s.name} ${formatPrice(s.goldCardPrice)} instead of ${formatPrice(s.price)}`).join(' · ')}
                </span>
            </span>
        </label>
    {/if}

    <p class="hint">Choose as many as you like. I'll do them all in one visit.</p>

    <ul class="list">
        {#each regular as service (service.id)}
            <li><CartItem {...service} /></li>
        {/each}
    </ul>

    {#if addOns.length}
        <h3>Add-ons</h3>
        <p class="hint">Added to a haircut.</p>
        <ul class="list">
            {#each addOns as service (service.id)}
                <li><CartItem {...service} /></li>
            {/each}
        </ul>
    {/if}
</div>

<style>
    .tabs {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 0.5rem;
    }
    @media (min-width: 40rem) {
        .tabs {
            grid-template-columns: repeat(4, 1fr);
        }
    }
    .tabs > button {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        color: var(--charcoal);
        cursor: pointer;
        font: 500 0.9375rem var(--font-default);
        min-height: 2.75rem;
        padding: 0.5rem 0.75rem;
        transition: background-color 150ms ease, border-color 150ms ease;
    }
    .tabs > button:hover {
        border-color: var(--dark);
    }
    .tabs > button[aria-selected="true"] {
        background-color: var(--darkest);
        border-color: var(--darkest);
        color: var(--white);
        font-weight: 600;
    }

    .panel {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }
    .panel > h3 {
        color: var(--darkest);
        font: 600 1rem var(--font-default);
        margin-top: 1rem;
    }
    .gold-card {
        align-items: center;
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        cursor: pointer;
        display: flex;
        gap: 0.875rem;
        padding: 0.875rem 1rem;
        position: relative;
        transition: background-color 150ms ease, border-color 150ms ease;
    }
    .gold-card:hover {
        border-color: var(--dark);
    }
    .gold-card.on {
        background-color: var(--color-accent-50);
        border-color: var(--color-accent-700);
    }
    /* Visually replaced by .switch; stays in the tab order and the a11y tree. */
    .gold-card > input {
        position: absolute;
        opacity: 0;
        inset: 0;
        cursor: pointer;
        margin: 0;
    }
    .gold-card:has(input:focus-visible) {
        outline: 2px solid var(--color-accent-700);
        outline-offset: 3px;
    }
    .switch {
        background-color: var(--input-border);
        border-radius: 999px;
        flex: none;
        height: 1.75rem;
        position: relative;
        width: 3rem;
        transition: background-color 200ms ease;
    }
    .switch::after {
        background-color: var(--white);
        border-radius: 50%;
        box-shadow: 0 1px 3px rgba(27, 27, 27, 0.3);
        content: "";
        height: 1.375rem;
        left: 0.1875rem;
        position: absolute;
        top: 0.1875rem;
        width: 1.375rem;
        transition: transform 200ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    .on .switch {
        background-color: var(--color-accent-700);
    }
    .on .switch::after {
        transform: translateX(1.25rem);
    }
    .gold-card .text {
        display: flex;
        flex-direction: column;
        gap: 0.125rem;
    }
    .gold-card .title {
        color: var(--darkest);
        font-weight: 600;
    }
    .gold-card .detail {
        color: var(--dark);
        font-size: 0.875rem;
        line-height: 1.4;
    }
    @media (prefers-reduced-motion: reduce) {
        .switch,
        .switch::after {
            transition: none;
        }
    }

    .hint {
        color: var(--dark);
        font-size: 0.9375rem;
    }
    .panel > h3 + .hint {
        margin-top: -0.5rem;
    }
    .list {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
</style>
