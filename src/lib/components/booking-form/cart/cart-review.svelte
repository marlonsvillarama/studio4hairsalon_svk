<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import { formatPrice, formatDuration } from "$lib/data/services";
    import { formatLongDate, formatTime } from "$lib/data/availability";

    const cartState = getCartState();
    let c = $derived(cartState.client);
</script>

<dl class="summary">
    <div class="row">
        <dt>When</dt>
        <dd>
            {formatLongDate(cartState.date)} at {formatTime(cartState.time)}
            <span class="sub">About {formatDuration(cartState.totalDuration)}</span>
        </dd>
        <button type="button" class="edit" onclick={() => cartState.goTo('appointment')}>
            Change<span class="sr-only"> date and time</span>
        </button>
    </div>

    <div class="row">
        <dt>Where</dt>
        <dd>
            Studio 4 Hair Salon, 7 George Street, Palmerston North
            <span class="sub">With John Fernandez</span>
        </dd>
    </div>

    <div class="row">
        <dt>Services</dt>
        <dd>
            <ul class="items">
                {#each cartState.selectedItems as s (s.id)}
                    <li>
                        <span>{s.name}{#if cartState.usesGoldCard(s)}{" "}<span class="tag">Gold Card</span>{/if}</span>
                        <span class="price">{formatPrice(cartState.priceOf(s), s.range)}</span>
                    </li>
                {/each}
                <li class="total">
                    <span>Total</span>
                    <span class="price">{formatPrice(cartState.totalPrice, cartState.hasVariablePrice)}</span>
                </li>
            </ul>
            {#if cartState.hasVariablePrice}
                <span class="sub">Prices marked "from" are starting prices.</span>
            {/if}
        </dd>
        <button type="button" class="edit" onclick={() => cartState.goTo('services')}>
            Change<span class="sr-only"> services</span>
        </button>
    </div>

    <div class="row">
        <dt>Your details</dt>
        <dd>
            {c.firstName} {c.lastName}
            <span class="sub">{[c.phone.trim(), c.email.trim()].filter(Boolean).join(' · ')}</span>
            {#if cartState.account}<span class="sub">Booking linked to your Google account</span>{/if}
            {#if c.notes}<span class="sub note">"{c.notes}"</span>{/if}
        </dd>
        <button type="button" class="edit" onclick={() => cartState.goTo('details')}>
            Change<span class="sr-only"> your details</span>
        </button>
    </div>
</dl>

{#if cartState.status === 'error'}
    <div class="alert" role="alert">
        <i class="ph ph-warning-circle" aria-hidden="true"></i>
        <div>
            <strong>Your booking didn't go through.</strong>
            <p>
                {cartState.errorMessage} Nothing has been booked yet. Try again, or call me on
                <a href="tel:+64221885240">022 188 5240</a> and I'll book you in.
            </p>
        </div>
    </div>
{/if}

<style>
    .summary {
        border-top: 1px solid var(--light);
    }
    .row {
        border-bottom: 1px solid var(--light);
        display: grid;
        grid-template-columns: 1fr auto;
        grid-template-areas: "dt edit" "dd dd";
        gap: 0.25rem 1rem;
        padding: 1rem 0;
    }
    @media (min-width: 40rem) {
        .row {
            grid-template-columns: 8rem 1fr auto;
            grid-template-areas: "dt dd edit";
        }
    }
    dt {
        grid-area: dt;
        color: var(--dark);
        font-size: 0.875rem;
        font-weight: 500;
        padding-top: 0.125rem;
    }
    dd {
        grid-area: dd;
        color: var(--darkest);
        font-weight: 500;
        line-height: 1.5;
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        min-width: 0;
        overflow-wrap: anywhere;
    }
    .sub {
        color: var(--dark);
        font-size: 0.875rem;
        font-weight: 400;
    }
    .note {
        font-style: italic;
    }
    .edit {
        grid-area: edit;
        align-self: start;
        color: var(--darkest);
        cursor: pointer;
        font-size: 0.875rem;
        font-weight: 600;
        padding: 0.125rem 0.25rem;
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
        text-underline-offset: 3px;
    }
    .items {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
    }
    .items > li {
        display: flex;
        justify-content: space-between;
        gap: 1rem;
    }
    .items > li.total {
        border-top: 1px solid var(--light);
        font-weight: 700;
        margin-top: 0.25rem;
        padding-top: 0.5rem;
    }
    .price {
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }
    .tag {
        background-color: var(--color-accent-100);
        border-radius: 0.25rem;
        color: var(--color-accent-800);
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.0625rem 0.375rem;
        white-space: nowrap;
    }

    .alert {
        background-color: var(--error-bg);
        border: 1px solid var(--error);
        border-radius: 0.25rem;
        color: var(--darkest);
        display: flex;
        gap: 0.75rem;
        padding: 1rem;
        line-height: 1.5;
    }
    .alert > i {
        color: var(--error);
        font-size: 1.5rem;
        flex: none;
    }
    .alert a {
        color: var(--darkest);
        font-weight: 600;
        white-space: nowrap;
    }
</style>
