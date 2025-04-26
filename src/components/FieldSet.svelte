<script>
    let {
        help = '',
        id,
        label,
        type = 'text',
        value = $bindable()
    } = $props();
</script>

{#snippet text()}
    <input type="text" {value}>
{/snippet}

{#snippet email()}
    <input type="email" {value}>
{/snippet}

{#snippet phone()}
    <input type="tel" {value}>
{/snippet}

<div class="fieldset">
    <h4 class="label">{label}</h4>
    {#if help}
        <p class="help">{help}</p>
    {/if}

    {#if type === 'email'}
        {@render email()}
    {:else if type === 'phone'}
        {@render phone()}
    {:else}
        {@render text()}
    {/if}
</div>

<style>
    .fieldset {
        min-width: 20rem;
        width: 100%;
        /* border: 1px solid red; */
    }
    h4 {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-sm);
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
    input {
        border: 1px solid var(--color-border-lite);
        border-radius: 0.25rem;
        color: var(--color-grey-dark-03-rgb);
        padding: 0.5rem 1rem;
        transition: all 150ms ease-in-out;
    }
    @media (min-width: 40rem) {
        input {
            padding: 0.75rem 1.25rem;
        }
    }
    input[type=text],
    input[type=email],
    input[type=tel] {
        position: relative;
        width: 100%;
    }
    @media (min-width: 40rem) {
        input[type=text],
        input[type=email] {
            width: 20rem;
        }
        input[type=tel] {
            width: 10rem;
        }
    }
</style>