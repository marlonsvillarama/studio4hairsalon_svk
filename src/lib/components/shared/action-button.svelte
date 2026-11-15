<script>
    /**
     * variant: 'primary' (yellow, the one action that matters),
     *          'ghost'   (outlined, for use on dark photos),
     *          'text'    (quiet link for "next section" nudges)
     */
    let {
        icon = '',
        label = 'Action',
        link = '',
        variant = 'primary',
        onclick
    } = $props();
</script>

<div class="btn-action-container">
{#if link}
    <a href={link} class="btn-action {variant}" {onclick}>
        <span class="label">{label}</span>
        {#if icon}
            <i class="ph ph-{icon}" aria-hidden="true"></i>
        {/if}
    </a>
{:else}
    <button type="button" class="btn-action {variant}" {onclick}>
        <span class="label">{label}</span>
        {#if icon}
            <i class="ph ph-{icon}" aria-hidden="true"></i>
        {/if}
    </button>
{/if}
</div>

<style>
    .btn-action-container {
        display: flex;
        align-items: center;
    }
    .btn-action {
        cursor: pointer;
        font-weight: 600;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: background-color 150ms ease-in-out, border-color 150ms ease-in-out, color 150ms ease-in-out;
    }
    .btn-action > i {
        font-size: 1.5rem;
    }

    .primary {
        background-color: var(--color-accent-400);
        border: 1px solid var(--color-accent-400);
        color: var(--darkest);
        min-height: 3rem;
        padding: 0.75rem 2rem;
    }
    .primary:hover {
        background-color: var(--color-accent-500);
        border-color: var(--color-accent-500);
    }

    .ghost {
        background-color: transparent;
        border: 1px solid rgba(250, 250, 249, 0.7);
        color: var(--color-off-white);
        min-height: 3rem;
        padding: 0.75rem 2rem;
    }
    .ghost:hover {
        background-color: rgba(250, 250, 249, 0.12);
        border-color: var(--color-off-white);
    }

    .text {
        color: var(--darkest);
        font-weight: 600;
        min-height: 2.75rem;
        padding: 0.5rem 0.25rem;
    }
    .text > .label {
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
        text-decoration-thickness: 2px;
        text-underline-offset: 6px;
    }
    .text > i {
        font-size: 1.125rem;
        transition: transform 200ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    .text:hover > i {
        transform: translateY(2px);
    }
</style>
