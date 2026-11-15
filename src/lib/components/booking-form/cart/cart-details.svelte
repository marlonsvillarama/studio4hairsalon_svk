<script>
    import { getCartState } from "$lib/data/cart.svelte";
    import { tick } from "svelte";

    const cartState = getCartState();
    let form = $state();

    // After a failed Continue, take the client straight to the first problem.
    let lastRequest = cartState.focusRequest;
    $effect(() => {
        if (cartState.focusRequest === lastRequest) return;
        lastRequest = cartState.focusRequest;
        tick().then(() => {
            const field = form?.querySelector('[aria-invalid="true"]');
            field?.focus();
            field?.scrollIntoView({ block: 'center', behavior: 'smooth' });
        });
    });

    let errors = $derived(cartState.showErrors ? cartState.detailErrors : {});

    // Google's "G" mark, as required by Google's sign-in branding guidelines.
    const googleG = '<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>';

    const fields = [
        { id: 'firstName', label: 'First name', autocomplete: 'given-name', type: 'text', required: true },
        { id: 'lastName', label: 'Last name', autocomplete: 'family-name', type: 'text', optional: true },
        { id: 'phone', label: 'Mobile number', autocomplete: 'tel', type: 'tel', inputmode: 'tel', required: true,
          help: "So I can reach you if anything changes." },
        { id: 'email', label: 'Email', autocomplete: 'email', type: 'email', inputmode: 'email', optional: true,
          help: 'For a copy of your booking.' },
    ];
</script>

<div class="account">
    {#if cartState.account}
        <div class="signed-in">
            <svg class="g" viewBox="0 0 48 48" aria-hidden="true">{@html googleG}</svg>
            <span>Signed in as <strong>{cartState.account.email}</strong></span>
            <button type="button" class="link" onclick={cartState.signOut}>Not you? Sign out</button>
        </div>
    {:else}
        <button type="button" class="google" onclick={cartState.signInWithGoogle}>
            <svg class="g" viewBox="0 0 48 48" aria-hidden="true">{@html googleG}</svg>
            Continue with Google
        </button>
        <p class="why">Fills in your details and keeps your bookings together.</p>
    {/if}
    {#if cartState.authNotice}
        <p class="auth-notice" role="status">{cartState.authNotice}</p>
    {/if}
</div>

{#if !cartState.account}
    <p class="divider"><span>or enter your details</span></p>
{/if}

<form class="details" novalidate bind:this={form} onsubmit={(e) => { e.preventDefault(); cartState.next(); }}>
    {#each fields as f (f.id)}
        <div class="field" class:invalid={errors[f.id]}>
            <label for="field-{f.id}">
                {f.label}
                {#if f.optional}<span class="optional">(optional)</span>{/if}
            </label>
            {#if f.help}<span class="help" id="help-{f.id}">{f.id === 'email' && cartState.account ? 'From your Google account.' : f.help}</span>{/if}
            <input id="field-{f.id}" name={f.id} type={f.type} inputmode={f.inputmode}
                autocomplete={f.autocomplete} required={f.required}
                readonly={f.id === 'email' && !!cartState.account}
                aria-invalid={errors[f.id] ? 'true' : undefined}
                aria-describedby={[f.help && `help-${f.id}`, errors[f.id] && `error-${f.id}`].filter(Boolean).join(' ') || undefined}
                value={cartState.client[f.id]}
                oninput={(e) => cartState.updateClient(f.id, e.currentTarget.value)} />
            {#if errors[f.id]}
                <span class="error" id="error-{f.id}">
                    <i class="ph ph-warning-circle" aria-hidden="true"></i>{errors[f.id]}
                </span>
            {/if}
        </div>
    {/each}

    <div class="field wide">
        <label for="field-notes">Anything I should know? <span class="optional">(optional)</span></label>
        <textarea id="field-notes" name="notes" rows="3"
            placeholder="e.g. bringing a photo of the look you want"
            value={cartState.client.notes}
            oninput={(e) => cartState.updateClient('notes', e.currentTarget.value)}></textarea>
    </div>

    <!-- Lets Enter submit the form; the visible button lives in the bottom bar. -->
    <button type="submit" hidden>Continue</button>
</form>

<style>
    .details {
        display: grid;
        gap: 1.25rem 1rem;
    }
    @media (min-width: 40rem) {
        .details {
            grid-template-columns: 1fr 1fr;
        }
        .wide {
            grid-column: 1 / -1;
        }
    }
    .account {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 0.5rem;
    }
    .google {
        align-items: center;
        background-color: var(--white);
        border: 1px solid #747775;
        border-radius: 0.25rem;
        color: #1f1f1f;
        cursor: pointer;
        display: inline-flex;
        font: 500 1rem var(--font-default);
        gap: 0.75rem;
        min-height: 2.875rem;
        padding: 0 1.25rem 0 0.875rem;
        transition: background-color 150ms ease, box-shadow 150ms ease;
    }
    .google:hover {
        background-color: #f8f9fa;
        box-shadow: 0 1px 3px rgba(60, 64, 67, 0.3);
    }
    .g {
        flex: none;
        height: 1.25rem;
        width: 1.25rem;
    }
    .why,
    .auth-notice {
        color: var(--dark);
        font-size: 0.875rem;
    }
    .signed-in {
        align-items: center;
        background-color: var(--color-accent-50);
        border: 1px solid var(--color-accent-300);
        border-radius: 0.25rem;
        color: var(--darkest);
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 0.75rem;
        padding: 0.75rem 1rem;
        width: 100%;
        overflow-wrap: anywhere;
    }
    .link {
        color: var(--darkest);
        cursor: pointer;
        font-size: 0.875rem;
        font-weight: 600;
        margin-left: auto;
        min-height: 2.75rem;
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
        text-underline-offset: 3px;
    }
    .divider {
        align-items: center;
        color: var(--dark);
        display: flex;
        font-size: 0.875rem;
        gap: 0.75rem;
    }
    .divider::before,
    .divider::after {
        border-top: 1px solid var(--light);
        content: "";
        flex: 1;
    }
    input[readonly] {
        background-color: var(--lighter);
        color: var(--dark);
    }
    .field {
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
    }
    label {
        color: var(--darkest);
        font-weight: 600;
        font-size: 0.9375rem;
    }
    .optional,
    .help {
        color: var(--dark);
        font-weight: 400;
        font-size: 0.875rem;
    }
    input,
    textarea {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        color: var(--darkest);
        font: 400 1rem / 1.4 var(--font-default);
        min-height: 2.875rem;
        padding: 0.625rem 0.75rem;
        width: 100%;
        transition: border-color 150ms ease, box-shadow 150ms ease;
    }
    textarea {
        resize: vertical;
    }
    input::placeholder,
    textarea::placeholder {
        color: var(--dark);
    }
    input:hover,
    textarea:hover {
        border-color: var(--dark);
    }
    input:focus-visible,
    textarea:focus-visible {
        border-color: var(--darkest);
        box-shadow: 0 0 0 3px var(--color-accent-300);
        outline: none;
    }
    .invalid input {
        border-color: var(--error);
    }
    .error {
        color: var(--error);
        display: flex;
        align-items: flex-start;
        gap: 0.375rem;
        font-size: 0.875rem;
        font-weight: 500;
        line-height: 1.4;
    }
    .error > i {
        font-size: 1.125rem;
        flex: none;
    }
</style>
