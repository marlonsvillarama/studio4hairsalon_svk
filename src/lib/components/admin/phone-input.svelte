<script>
    /**
     * Phone number with a country selector (NZ by default), formatted as it's
     * typed. `country` and `value` (the displayed text) are bindable; turn it
     * into E.164 with toE164() from $lib/phone.
     */
    import { tick } from 'svelte';
    import { COUNTRIES, formatPhone, nationalDigits } from '$lib/phone';

    let { id, country = $bindable('NZ'), value = $bindable(''), invalid = false, describedby, disabled = false } = $props();

    let input = $state();

    // Keep the caret after the same number of digits once the text is reformatted.
    const digitsBefore = (text, pos) => text.slice(0, pos).replace(/\D/g, '').length;
    function caretAfterDigits(text, n) {
        if (n <= 0) return text.startsWith('+') ? 1 : 0;
        let seen = 0;
        for (let i = 0; i < text.length; i++) {
            if (/\d/.test(text[i]) && ++seen === n) return i + 1;
        }
        return text.length;
    }

    async function apply(raw, caret) {
        const before = digitsBefore(raw, caret);
        const res = formatPhone(country, raw);
        // A leading 0 may have been added for the local format.
        const shift = res.text.replace(/\D/g, '').length - raw.replace(/\D/g, '').length;
        value = res.text;
        country = res.country;
        await tick();
        if (input && document.activeElement === input) {
            const at = caretAfterDigits(value, before + Math.max(0, shift));
            input.setSelectionRange(at, at);
        }
    }

    const oninput = (e) => apply(e.currentTarget.value, e.currentTarget.selectionStart ?? e.currentTarget.value.length);

    // Backspace just after a space or bracket removes the digit before it.
    function onkeydown(e) {
        if (e.key !== 'Backspace' || e.metaKey || e.ctrlKey || e.altKey) return;
        const el = e.currentTarget;
        const pos = el.selectionStart;
        if (pos !== el.selectionEnd || pos === 0 || /\d/.test(el.value[pos - 1])) return;
        let i = pos - 1;
        while (i > 0 && !/\d/.test(el.value[i - 1])) i--;
        if (i === 0) return;
        e.preventDefault();
        const raw = el.value.slice(0, i - 1) + el.value.slice(pos);
        apply(raw, i - 1);
    }

    function onCountry() {
        if (!value) return;
        // Picking a country keeps the local part of a full "+…" number.
        const raw = country ? nationalDigits(value) : value;
        apply(raw, raw.length);
    }

    let placeholder = $derived({ NZ: '021 123 4567', AU: '0412 345 678', US: '(201) 555-0123', GB: '07700 900123' }[country] ?? (country ? '' : '+33 6 12 34 56 78'));
    let current = $derived(COUNTRIES.find(c => c.code === country));
    let title = $derived(current ? `${current.name} (${current.dial})` : 'Other country: type the number with + and its code');
</script>

<div class="phone" class:invalid class:disabled>
    <!-- A short "NZ" label over a real (invisible) select: the open list shows full names. -->
    <span class="country" {title}>
        <span class="code" aria-hidden="true">{current ? current.code : '+'}</span>
        <i class="ph ph-caret-down" aria-hidden="true"></i>
        <select aria-label="Country" bind:value={country} onchange={onCountry} {disabled}>
            {#each COUNTRIES as c}<option value={c.code}>{c.name} ({c.dial})</option>{/each}
            <option value="">Other (type +code)</option>
        </select>
    </span>
    <input {id} bind:this={input} type="tel" inputmode="tel" autocomplete="off" {value} {oninput} {onkeydown} {placeholder} {disabled}
        aria-invalid={invalid} aria-describedby={describedby} />
</div>

<style>
    /* Country and number look like one field: one border, one focus ring. */
    .phone {
        align-items: stretch;
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border-strong);
        border-radius: 0.25rem;
        box-sizing: border-box;
        display: flex;
        min-height: 2.75rem;
        min-width: 0;
    }
    .phone:focus-within {
        outline: 2px solid var(--adm-focus);
        outline-offset: 2px;
    }
    .phone.invalid {
        border-color: var(--adm-danger);
    }
    .phone.disabled {
        opacity: 0.6;
    }
    .country {
        align-items: center;
        border-right: 1px solid var(--adm-border);
        color: var(--adm-text);
        display: flex;
        flex: none;
        font-weight: 600;
        gap: 0.25rem;
        padding: 0 0.5rem 0 0.75rem;
        position: relative;
    }
    .country:hover {
        background-color: var(--adm-sunken);
    }
    .code {
        font-variant-numeric: tabular-nums;
        min-width: 1.5rem;
    }
    .country i {
        color: var(--adm-text-muted);
        font-size: 0.875rem;
    }
    .country select {
        appearance: none;
        border: 0;
        cursor: pointer;
        inset: 0;
        min-height: 0;
        opacity: 0;
        position: absolute;
        width: 100%;
    }
    /* (Specific enough to beat the admin's shared input style.) */
    .phone input[type="tel"] {
        background: transparent;
        border: 0;
        border-radius: 0 0.25rem 0.25rem 0;
        flex: 1;
        min-height: 0;
        min-width: 0;
        outline: none;
    }
</style>
