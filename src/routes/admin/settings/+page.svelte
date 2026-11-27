<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { adminError } from '$lib/admin';
    import { showGst } from '$lib/invoices';

    const sb = getSupabase();
    const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    let settings = $state(null);
    let hours = $state([]);
    let business = $state(null);
    let gstText = $state('');
    let loading = $state(true);
    let error = $state('');
    let message = $state('');
    let saving = $state(false);

    async function load() {
        loading = true;
        const [s, h, b] = await Promise.all([
            sb.from('s4_settings').select('*').single(),
            sb.from('s4_business_hours').select('*').order('weekday'),
            sb.from('s4_business').select('*').maybeSingle()
        ]);
        loading = false;
        if (s.error || h.error || b.error) { error = adminError(s.error || h.error || b.error); return; }
        settings = s.data;
        business = b.data;
        gstText = showGst(b.data?.gst_number);
        // Shown Monday first; weekday stays 0 = Sunday in the data.
        const mondayFirst = (w) => (w + 6) % 7;
        hours = h.data.toSorted((a, z) => mondayFirst(a.weekday) - mondayFirst(z.weekday)).map(d => ({
            ...d,
            opens_at: d.opens_at?.slice(0, 5) ?? '09:30',
            closes_at: d.closes_at?.slice(0, 5) ?? '17:00'
        }));
    }
    onMount(load);

    async function save(e) {
        e.preventDefault();
        error = '';
        message = '';
        for (const d of hours) {
            if (d.is_open && d.closes_at <= d.opens_at) {
                error = `${DAYS[d.weekday]}: closing time must be after opening time.`;
                return;
            }
        }
        const gstDigits = gstText.replace(/\D/g, '');
        if (business && gstDigits && !/^\d{8,9}$/.test(gstDigits)) {
            error = 'A GST number has 8 or 9 digits, e.g. 123-456-789.';
            return;
        }
        saving = true;
        const biz = business ? await sb.from('s4_business').update({
            trading_name: business.trading_name.trim(),
            legal_name: business.legal_name.trim(),
            gst_number: gstDigits,
            address: business.address.trim(),
            phone: business.phone.trim(),
            email: business.email.trim(),
            invoice_note: business.invoice_note.trim()
        }).eq('id', true) : { error: null };
        const s = await sb.from('s4_settings').update({
            online_booking_enabled: settings.online_booking_enabled,
            slot_step_min: Number(settings.slot_step_min)
        }).eq('id', true);
        const h = await sb.from('s4_business_hours').upsert(hours.map(d => ({
            weekday: d.weekday,
            is_open: d.is_open,
            opens_at: d.is_open ? d.opens_at : null,
            closes_at: d.is_open ? d.closes_at : null
        })));
        saving = false;
        if (s.error || h.error || biz.error) { error = adminError(s.error || h.error || biz.error); return; }
        if (business) gstText = showGst(gstDigits);
        message = 'Saved.';
    }
</script>

<h1>Settings</h1>

{#if loading}
    <p class="muted" role="status">Loading…</p>
{:else if !settings}
    <p class="error">{error}</p>
{:else}
    <form class="layout" onsubmit={save}>
        <section class="panel">
            <h2>Online booking</h2>
            <label class="check big">
                <input type="checkbox" bind:checked={settings.online_booking_enabled} />
                Take bookings online
            </label>
            <p class="muted">When off, the booking page asks clients to call or text instead.</p>

            <div class="grid">
                <label>Start times every (minutes)
                    <select bind:value={settings.slot_step_min}>
                        <option value={15}>15</option>
                        <option value={30}>30</option>
                        <option value={60}>60</option>
                    </select>
                </label>
            </div>
        </section>

        <section class="panel">
            <h2>Opening hours</h2>
            <ul class="hours">
                {#each hours as d (d.weekday)}
                    <li>
                        <label class="check day"><input type="checkbox" bind:checked={d.is_open} /> {DAYS[d.weekday]}</label>
                        {#if d.is_open}
                            <label class="sr-label"><span class="sr-only">{DAYS[d.weekday]} opens</span>
                                <input type="time" step="900" bind:value={d.opens_at} /></label>
                            <span aria-hidden="true">to</span>
                            <label class="sr-label"><span class="sr-only">{DAYS[d.weekday]} closes</span>
                                <input type="time" step="900" bind:value={d.closes_at} /></label>
                        {:else}
                            <span class="muted">Closed</span>
                        {/if}
                    </li>
                {/each}
            </ul>
        </section>

        {#if business}
            <section class="panel">
                <h2>Business details</h2>
                <p class="muted">Printed on every tax invoice. Changes apply to invoices issued from now on.</p>
                <div class="grid">
                    <label>Trading name
                        <input bind:value={business.trading_name} required maxlength="120" autocomplete="organization" />
                    </label>
                    <label>
                        <span>Legal name <span class="optional">(if different)</span></span>
                        <input bind:value={business.legal_name} maxlength="120" />
                    </label>
                    <label>GST number
                        <input bind:value={gstText} inputmode="numeric" placeholder="123-456-789" maxlength="11" />
                    </label>
                    <label>Phone
                        <input bind:value={business.phone} maxlength="40" autocomplete="tel" />
                    </label>
                    <label>Email
                        <input type="email" bind:value={business.email} maxlength="120" autocomplete="email" />
                    </label>
                </div>
                <div class="grid">
                    <label>Address
                        <textarea rows="3" bind:value={business.address} maxlength="300"></textarea>
                    </label>
                    <label>
                        <span>Invoice note <span class="optional">(optional, e.g. bank account)</span></span>
                        <textarea rows="3" bind:value={business.invoice_note} maxlength="500"></textarea>
                    </label>
                </div>
            </section>
        {/if}

        <div class="bar">
            <button type="submit" class="primary" disabled={saving}>{saving ? 'Saving…' : 'Save settings'}</button>
            {#if message}<span class="ok" role="status">{message}</span>{/if}
            {#if error}<span class="error" role="alert">{error}</span>{/if}
        </div>
    </form>
{/if}

<style>
    h1 {
        margin-bottom: 1.5rem;
    }
    .layout {
        display: grid;
        gap: 1.25rem;
        grid-template-columns: minmax(0, 1fr);
        max-width: 44rem;
    }
    /* Wide screens: Online booking and Opening hours side by side,
       business details and Save across the full width under them. */
    @media (min-width: 72rem) {
        .layout {
            align-items: start;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            max-width: 76rem;
        }
        .layout > :nth-child(n + 3) {
            grid-column: 1 / -1;
        }
    }
    .panel h2 {
        margin-bottom: 0.75rem;
    }
    label {
        display: flex;
        flex-direction: column;
        font-weight: 600;
        gap: 0.25rem;
    }
    .check {
        align-items: center;
        flex-direction: row;
        gap: 0.5rem;
    }
    .big {
        font-size: 1.0625rem;
    }
    .grid {
        display: grid;
        gap: 1rem;
        grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr));
        margin-top: 1.25rem;
    }
    .hours {
        list-style: none;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    .hours li {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        min-height: 2.75rem;
    }
    .day {
        width: 9rem;
    }
    .sr-label {
        flex-direction: row;
    }
    .optional {
        color: var(--adm-text-muted);
        font-weight: 400;
    }
    textarea {
        resize: vertical;
        width: 100%;
    }
    .bar {
        align-items: center;
        display: flex;
        gap: 1rem;
    }
</style>
