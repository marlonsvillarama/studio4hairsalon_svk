<script>
    /**
     * Native <dialog> modal: focus is trapped while open, Esc closes it, the
     * page behind is inert, and focus returns to the button that opened it.
     * On narrow screens it becomes a bottom sheet.
     */
    let { open = $bindable(false), title, onclose, children, footer } = $props();

    let dialog = $state();
    const id = `modal-${Math.random().toString(36).slice(2, 8)}`;

    $effect(() => {
        if (!dialog) return;
        if (open && !dialog.open) dialog.showModal();
        if (!open && dialog.open) dialog.close();
    });

    function handleClose() {
        if (open) open = false;
        onclose?.();
    }

    // Clicking the dimmed backdrop (the dialog element itself) closes it.
    function onclick(e) {
        if (e.target === dialog) dialog.close();
    }
</script>

<dialog bind:this={dialog} aria-labelledby="{id}-title" onclose={handleClose} {onclick}>
    {#if open}
        <div class="sheet">
            <header>
                <h2 id="{id}-title">{title}</h2>
                <button type="button" class="close" aria-label="Close" onclick={() => dialog.close()}>
                    <i class="ph ph-x" aria-hidden="true"></i>
                </button>
            </header>
            <div class="body">
                {@render children?.()}
            </div>
            {#if footer}
                <footer>{@render footer()}</footer>
            {/if}
        </div>
    {/if}
</dialog>

<style>
    dialog {
        background: transparent;
        border: 0;
        margin: auto;
        max-height: calc(100dvh - 2rem);
        max-width: none;
        padding: 0;
        width: min(32rem, 100vw - 2rem);
    }
    dialog::backdrop {
        background-color: var(--adm-backdrop);
    }
    dialog[open] {
        animation: rise 220ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes rise {
        from { opacity: 0; transform: translateY(12px); }
    }
    .sheet {
        background-color: var(--adm-surface);
        border-radius: var(--adm-radius-lg);
        box-shadow: var(--adm-shadow-overlay);
        color: var(--adm-text-body);
        display: flex;
        flex-direction: column;
        max-height: calc(100dvh - 2rem);
    }
    header {
        align-items: center;
        border-bottom: 1px solid var(--adm-border);
        display: flex;
        gap: 1rem;
        justify-content: space-between;
        padding: 0.75rem 0.75rem 0.75rem 1.25rem;
    }
    h2 {
        color: var(--adm-text);
        font: 600 1.125rem / 1.3 var(--font-default);
        letter-spacing: var(--adm-heading-tracking);
    }
    .close {
        border-radius: 50%;
        color: var(--adm-text-muted);
        cursor: pointer;
        display: grid;
        font-size: 1.25rem;
        height: 2.75rem;
        place-items: center;
        width: 2.75rem;
    }
    .close:hover {
        background-color: var(--adm-sunken);
        color: var(--adm-text);
    }
    .body {
        overflow-y: auto;
        padding: 1.25rem;
    }
    footer {
        border-top: 1px solid var(--adm-border);
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        justify-content: flex-end;
        padding: 0.875rem 1.25rem;
    }

    /* Phones: bottom sheet. */
    @media (max-width: 40rem) {
        dialog {
            margin: auto 0 0;
            max-height: 92dvh;
            width: 100vw;
        }
        .sheet {
            border-radius: 0.75rem 0.75rem 0 0;
            max-height: 92dvh;
            padding-bottom: env(safe-area-inset-bottom);
        }
        footer {
            justify-content: stretch;
        }
        footer :global(button) {
            flex: 1;
        }
    }
    @media (prefers-reduced-motion: reduce) {
        dialog[open] { animation: none; }
    }
</style>
