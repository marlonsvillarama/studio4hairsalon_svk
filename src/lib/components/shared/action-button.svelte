<script>
    let {
        icon = '',
        label = 'Action',
        link = '',
        onclick
    } = $props();
</script>

<div class="btn-action-container">
{#if link}
    <a href={link} title={label} class="btn-action">
        {label}
        {#if icon}
            <i class="ph ph-{icon}"></i>
        {/if}
    </a>
{:else}
    <button type="button" title={label} class="btn-action" {onclick}>
        {label}
        {#if icon}
            <i class="ph ph-{icon}"></i>
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
        background-color: var(--color-accent-400);
        border: 1px solid var(--color-accent-400);
        color: var(--darkest);
        cursor: pointer;
        font-weight: 600;
        padding: 0.75rem 2rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: background-color 150ms ease-in-out, border-color 150ms ease-in-out;
        /* flex: 0; */
    }
    .btn-action > i {
        font-size: 1.5rem;
    }
    .btn-action:hover {
        background-color: var(--color-accent-500);
    }
</style>