<script>
    /**
     * On/off switch (a checkbox with role="switch"). `label` is always the
     * accessible name; set `showLabel` to also display it beside the switch.
     */
    let { checked = $bindable(false), label, showLabel = false, disabled = false, onchange } = $props();
</script>

<label class="switch" class:disabled>
    <input type="checkbox" role="switch" bind:checked {disabled} aria-label={showLabel ? undefined : label}
        onchange={(e) => onchange?.(e.currentTarget.checked)} />
    <span class="track" aria-hidden="true"></span>
    {#if showLabel}<span class="text">{label}</span>{/if}
</label>

<style>
    .switch {
        align-items: center;
        cursor: pointer;
        display: inline-flex;
        gap: 0.625rem;
        min-height: 2.75rem;
        position: relative;
    }
    .switch.disabled {
        cursor: progress;
        opacity: 0.6;
    }
    input {
        cursor: inherit;
        height: 100%;
        inset: 0;
        margin: 0;
        opacity: 0;
        position: absolute;
        width: 100%;
    }
    .track {
        background-color: var(--adm-border-strong);
        border-radius: 999px;
        flex: none;
        height: 1.5rem;
        position: relative;
        width: 2.625rem;
        transition: background-color 200ms ease;
    }
    .track::after {
        background-color: var(--adm-surface);
        border-radius: 50%;
        box-shadow: 0 1px 3px rgba(9, 30, 66, 0.3);
        content: "";
        height: 1.125rem;
        left: 0.1875rem;
        position: absolute;
        top: 0.1875rem;
        width: 1.125rem;
        transition: transform 200ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    input:checked + .track {
        background-color: var(--adm-selected-border);
    }
    input:checked + .track::after {
        transform: translateX(1.125rem);
    }
    input:focus-visible + .track {
        outline: 2px solid var(--adm-focus);
        outline-offset: 3px;
    }
    .text {
        color: var(--adm-text);
        font-weight: 600;
    }
    @media (prefers-reduced-motion: reduce) {
        .track, .track::after { transition: none; }
    }
</style>
