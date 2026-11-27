<script>
    /**
     * "New booking" for staff (phone and walk-in clients), in four steps:
     * client → service → date & time → summary. Each step must be complete
     * before the next. The database (s4_staff_create_booking) prices the visit
     * and has the final say on clashes.
     */
    import { untrack, tick } from 'svelte';
    import { getSupabase, errorCode } from '$lib/supabase';
    import { salonInstant, clashes } from '$lib/data/availability';
    import { loadCatalogue, formatPrice, formatDuration, priceFor } from '$lib/data/services';
    import {
        SALON_TZ, salonDay, showDay, showPhone, adminError, addDays, weekdayOf, minutesToHHMM, bookingGaps
    } from '$lib/admin';
    import Modal from './modal.svelte';
    import Switch from './switch.svelte';
    import PhoneInput from './phone-input.svelte';
    import { isValidPhone, toE164, fromE164, showInternational, countryName } from '$lib/phone';

    /**
     * day: the day on screen ("YYYY-MM-DD"). hours: { [weekday]: { open, close } | null }.
     * client: optional s4_clients row to book for (skips to the Service step).
     */
    let { open = $bindable(false), day, hours = {}, client: preset = null, oncreated } = $props();

    const sb = getSupabase();
    const uid = `nb-${Math.random().toString(36).slice(2, 8)}`;
    const STEPS = ['Client', 'Service', 'Date & time', 'Summary'];
    const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

    // ─── form state ─────────────────────────────────────────────────────
    let step = $state(1);
    let lastName = $state('');
    let firstName = $state('');
    let phone = $state('');
    let phoneCountry = $state('NZ');
    let email = $state('');
    let client = $state(null);          // picked existing client, or null for a new one
    let goldCard = $state(false);
    let chosen = $state([]);            // service ids
    let date = $state('');
    let time = $state('');
    let notes = $state('');
    let mode = $state('client');        // 'client' | 'staff' (friends & family, booked by the signed-in staff member)
    let priceText = $state('');         // friends & family: the price to charge, in dollars ('' = the normal price)
    let showContact = $state(false);    // friends & family: contact details are optional and folded away
    let staffName = $state('');         // who's signed in ("Booked by John")
    let party = $state([]);             // people already added to this booking (a group booked in one go)
    let saving = $state(false);
    let errors = $state({});            // field → message, for the current step
    let stepError = $state('');         // a message for the whole step (e.g. from saving)

    let catalogue = $state(null);
    let catalogueError = $state('');
    let slotStep = $state(30);

    function reset() {
        const today = salonDay(Date.now());
        step = 1;
        lastName = firstName = phone = email = notes = time = stepError = '';
        errors = {};
        client = null;
        phoneCountry = 'NZ';
        goldCard = false;
        chosen = [];
        mode = 'client';
        priceText = '';
        showContact = false;
        party = [];
        date = day && day >= today ? day : today;
        lastSearch.clear();
        firstSearch.clear();
        lastVisit = null;
    }

    let firstEl = $state();

    // Load services and the start-time grid the first time the form opens.
    $effect(() => {
        if (!open) return;
        untrack(() => {
            reset();
            if (!staffName) {
                sb.auth.getUser().then(({ data: { user } }) => user && sb.from('s4_staff').select('display_name').eq('user_id', user.id).maybeSingle())
                    .then((res) => { if (res?.data?.display_name) staffName = res.data.display_name; });
            }
            // Booking for a known client (e.g. from Clients): start at Service.
            if (preset) { pick(preset); showStep(2); } else tick().then(() => firstEl?.focus());
            if (!catalogue) {
                loadCatalogue().then(c => catalogue = c).catch(e => catalogueError = e.message);
                sb.from('s4_settings').select('slot_step_min').single().then(({ data }) => { if (data) slotStep = data.slot_step_min; });
            }
        });
    });

    // ─── step 1: client search on Last name and First name ──────────────
    // Each name field has its own list; picking from either fills the form.
    const esc = (q) => q.replace(/[\\%_]/g, '\\$&');
    class NameSearch {
        matches = $state([]);
        open = $state(false);
        active = $state(-1);
        searching = $state(false);
        searched = $state('');
        timer;
        seq = 0;
        constructor(field) {
            this.field = field;                 // 'last_name' | 'first_name'
            this.listId = `${uid}-${field}-list`;
        }
        optionId = (i) => `${uid}-${this.field}-opt-${i}`;
        text = () => (this.field === 'last_name' ? lastName : firstName).trim();
        clear() {
            clearTimeout(this.timer);
            this.matches = [];
            this.open = false;
            this.searched = '';
        }
        input() {
            if (client) unpick(this.field);     // typing again means a new (or different) client
            clearTimeout(this.timer);
            const q = this.text();
            if (q.length < 3) { this.clear(); return; }
            this.timer = setTimeout(() => this.search(q), 200);
        }
        async search(q) {
            const mine = ++this.seq;
            this.searching = true;
            let query = sb.from('s4_clients')
                .select('id, first_name, last_name, phone_e164, email, email_verified, has_gold_card, arranged_by, is_family')
                .ilike(this.field, `${esc(q)}%`);
            // Friends & family mode only finds friends & family.
            if (mode === 'staff') query = query.eq('is_family', true);
            // First name narrows by any last name already typed.
            const last = lastName.trim();
            if (this.field === 'first_name' && last) query = query.ilike('last_name', `${esc(last)}%`);
            const { data, error } = await query.order('last_name').order('first_name').limit(8);
            if (mine !== this.seq) return;
            this.searching = false;
            this.matches = error ? [] : data;
            this.searched = q;
            this.active = -1;
            this.open = this.text() === q;
        }
        focus() {
            if (this.matches.length && !client && this.text() === this.searched) this.open = true;
        }
        blur() {
            setTimeout(() => this.open = false, 150);
        }
        keydown(e) {
            if (e.key === 'Escape' && this.open) { this.open = false; e.preventDefault(); e.stopPropagation(); return; }
            if (e.key === 'Enter' && this.open) {
                // Enter picks from the list; it never moves to the next step while the list is open.
                e.preventDefault();
                if (this.active >= 0) pick(this.matches[this.active]);
                return;
            }
            if (!this.open || !this.matches.length) {
                if (e.key === 'ArrowDown' && this.matches.length) { this.open = true; this.active = 0; e.preventDefault(); }
                return;
            }
            if (e.key === 'ArrowDown') { this.active = (this.active + 1) % this.matches.length; e.preventDefault(); }
            else if (e.key === 'ArrowUp') { this.active = (this.active - 1 + this.matches.length) % this.matches.length; e.preventDefault(); }
        }
    }
    const lastSearch = new NameSearch('last_name');
    const firstSearch = new NameSearch('first_name');
    let searchHint = $derived.by(() => {
        const s = [lastSearch, firstSearch].find(x => x.searching) ?? [lastSearch, firstSearch].find(x => x.text().length >= 3 && x.searched === x.text());
        if (!s) return '';
        if (s.searching) return 'Searching…';
        return s.matches.length
            ? `${s.matches.length} matching ${s.matches.length === 1 ? 'client' : 'clients'}. Choose one, or keep typing for a new client.`
            : 'New client.';
    });

    function pick(c) {
        client = c;
        if (c.is_family) mode = 'staff';
        if (mode === 'staff' && (c.phone_e164 || c.email)) showContact = true;
        lastName = c.last_name ?? '';
        firstName = c.first_name ?? '';
        ({ country: phoneCountry, text: phone } = fromE164(c.phone_e164));
        email = c.email ?? '';
        goldCard = !!c.has_gold_card;
        lastSearch.clear();
        firstSearch.clear();
        errors = {};
    }
    /** Forget the chosen client and what it filled in (except the name being typed). */
    function unpick(keep) {
        client = null;
        if (keep !== 'last_name') lastName = '';
        if (keep !== 'first_name') firstName = '';
        phone = email = '';
        phoneCountry = 'NZ';
        goldCard = false;
    }

    // Client ↔ Friends & family: start the person afresh, without the other mode's errors.
    function switchMode() {
        unpick();
        lastSearch.clear();
        firstSearch.clear();
        errors = {};
        stepError = '';
        showContact = false;
    }

    // ─── step 2: services ───────────────────────────────────────────────
    let groups = $derived(catalogue
        ? catalogue.categories.map(c => ({ ...c, services: catalogue.services.filter(s => s.category === c.id) })).filter(g => g.services.length)
        : []);
    let picked = $derived(catalogue ? catalogue.services.filter(s => chosen.includes(s.id)) : []);
    let duration = $derived(picked.reduce((n, s) => n + s.duration, 0));
    let normalTotal = $derived(picked.reduce((n, s) => n + priceFor(s, goldCard), 0));
    // Friends & family may pay a different price (e.g. a family discount).
    let priceCents = $derived(mode === 'staff' && String(priceText ?? '').trim() !== '' && Number.isFinite(Number(priceText)) ? Math.round(Number(priceText) * 100) : null);
    let total = $derived(priceCents != null ? priceCents / 100 : normalTotal);
    let onlyAddons = $derived(picked.length > 0 && picked.every(s => s.addon));
    // The visit's own waiting periods, in the salon's order (as the database does).
    let ownGaps = $derived.by(() => {
        if (!catalogue) return [];
        const rank = (s) => catalogue.categories.findIndex(c => c.id === s.category) * 10_000 + catalogue.services.indexOf(s);
        let at = 0;
        const gaps = [];
        for (const s of picked.toSorted((a, z) => rank(a) - rank(z))) {
            if (s.wait) gaps.push({ start: at + s.wait.after, end: at + s.wait.after + s.wait.length });
            at += s.duration;
        }
        return gaps;
    });
    let waiting = $derived(ownGaps.reduce((n, g) => n + g.end - g.start, 0));

    // An existing client's most recent booking, to book the same again.
    let lastVisit = $state(null);       // { starts_at, items: [{ service_id, name, offered }] } | null
    $effect(() => {
        const id = client?.id;
        lastVisit = null;
        if (!id) return;
        sb.from('s4_bookings')
            .select('starts_at, items:s4_booking_items(service_id, name, sort_order)')
            .eq('client_id', id).in('status', ['confirmed', 'completed'])
            .order('starts_at', { ascending: false }).limit(1)
            .then(({ data }) => {
                if (client?.id !== id || !data?.length || !data[0].items?.length) return;
                lastVisit = { starts_at: data[0].starts_at, items: data[0].items.toSorted((a, z) => a.sort_order - z.sort_order) };
            });
    });
    const offered = (serviceId) => !!catalogue?.services.some(s => s.id === serviceId);
    let lastOffered = $derived(lastVisit ? lastVisit.items.filter(i => offered(i.service_id)).map(i => i.service_id) : []);
    let sameAsLast = $derived(lastOffered.length > 0 && lastOffered.length === chosen.length && lastOffered.every(id => chosen.includes(id)));
    function bookSame() {
        chosen = [...lastOffered];
        errors = {};
    }

    // ─── step 3: that day's bookings, time off and free times ───────────
    let dayBusy = $state([]);
    let dayOff = $state([]);
    let dayLoaded = $state('');
    let dayRefresh = $state(0);
    $effect(() => {
        dayRefresh;
        if (!open || !ISO_DATE.test(date)) return;
        const iso = date;
        const from = salonInstant(iso, '00:00', SALON_TZ).toISOString();
        const to = salonInstant(addDays(iso, 1), '00:00', SALON_TZ).toISOString();
        Promise.all([
            sb.from('s4_bookings').select('id, starts_at, ends_at, status, gaps').eq('status', 'confirmed').lt('starts_at', to).gt('ends_at', from),
            sb.from('s4_time_off').select('starts_at, ends_at').lt('starts_at', to).gt('ends_at', from)
        ]).then(([b, t]) => {
            if (iso !== date) return;
            const rows = b.data ?? [];
            // Staff may use closed waiting time too, so every gap counts here.
            dayBusy = rows.map(r => ({
                start: new Date(r.starts_at).getTime(),
                end: new Date(r.ends_at).getTime(),
                gaps: bookingGaps(r),
                kind: 'booking'
            }));
            dayOff = (t.data ?? []).map(r => ({ start: new Date(r.starts_at).getTime(), end: new Date(r.ends_at).getTime() }));
            dayLoaded = iso;
        });
    });

    const visitAt = (hhmm) => {
        const start = salonInstant(date, hhmm, SALON_TZ).getTime();
        return {
            start,
            end: start + Math.max(duration, 1) * 60_000,
            gaps: ownGaps.map(g => ({ start: start + g.start * 60_000, end: start + g.end * 60_000 }))
        };
    };
    const overlapsOff = (v) => dayOff.some(t => t.start < v.end && t.end > v.start);
    // People already added to this booking (same day) count as busy too.
    let busyWithParty = $derived([...dayBusy, ...party.filter(m => m.date === date).map(m => ({ start: m.start, end: m.end, gaps: m.gaps, kind: 'booking' }))]);
    let dayHours = $derived(ISO_DATE.test(date) ? hours[weekdayOf(date)] ?? null : null);

    // Free start times on the grid, within opening hours, from now on.
    let freeTimes = $derived.by(() => {
        if (!dayHours || !duration || dayLoaded !== date) return [];
        const now = Date.now();
        const out = [];
        for (let m = dayHours.open; m + duration <= dayHours.close; m += slotStep) {
            const hhmm = minutesToHHMM(m);
            const v = visitAt(hhmm);
            if (v.start < now || overlapsOff(v) || clashes(v, busyWithParty)) continue;
            out.push(hhmm);
        }
        return out;
    });
    // A chosen time that's no longer free (new date or services) is cleared.
    $effect(() => {
        if (time && dayLoaded === date && !freeTimes.includes(time)) untrack(() => time = '');
    });
    $effect(() => {
        date;
        untrack(() => { if (dayLoaded !== date) time = ''; });
    });

    /** "14:30" → "2:30 PM" */
    const clock = (hhmm) => {
        const [h, m] = hhmm.split(':').map(Number);
        return new Date(2000, 0, 1, h, m).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    };
    const clockAt = (ms) => clock(new Intl.DateTimeFormat('en-NZ', { timeZone: SALON_TZ, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(ms));
    let endsAt = $derived(time && duration && ISO_DATE.test(date) ? visitAt(time).end : null);

    // ─── steps ──────────────────────────────────────────────────────────
    function validate(n) {
        const e = {};
        if (n === 1) {
            if (!firstName.trim()) e.firstName = 'Enter the client’s first name.';
            if (phone.trim() && !isValidPhone(phoneCountry, phone)) {
                e.phone = phoneCountry ? `That doesn’t look like a ${countryName(phoneCountry)} number.` : 'Enter the full number, starting with + and the country code.';
            }
            if (mode === 'client' && !phone.trim() && !email.trim() && !client?.arranged_by) {
                e.contact = 'Enter a phone number or an email so you can reach the client.';
            }
            else if (email.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) e.email = 'That email doesn’t look right.';
        }
        if (n === 2) {
            if (!catalogue) e.services = 'Services are still loading.';
            else if (!picked.length) e.services = 'Choose at least one service.';
            else if (onlyAddons) e.services = 'Add-ons need a main service.';
            if (mode === 'staff' && String(priceText ?? '').trim() !== '' && !(Number(priceText) >= 0)) e.price = 'Enter a price of $0 or more.';
        }
        if (n === 3) {
            if (!ISO_DATE.test(date)) e.date = 'Choose a date.';
            if (!time) e.time = 'Choose a time.';
        }
        return e;
    }
    const FIELD_ORDER = ['firstName', 'email', 'contact', 'phone', 'services', 'price', 'date', 'time'];

    async function showStep(n, err = {}, msg = '') {
        step = n;
        errors = err;
        stepError = msg;
        await tick();
        const first = FIELD_ORDER.find(k => err[k]);
        const target = first && document.getElementById(`${uid}-f-${first === 'contact' ? 'email' : first}`);
        (target || document.getElementById(`${uid}-h${n}`))?.focus();
    }

    function next(e) {
        e?.preventDefault();
        if (step === 4) return save();
        const err = validate(step);
        if (Object.keys(err).length) { showStep(step, err); return; }
        showStep(step + 1);
    }
    const back = () => showStep(step - 1);

    /** Earlier steps are always open; later ones only when every step before them is complete. */
    const canReach = (n) => n < step || (n > step && [...Array(n - 1).keys()].every(i => !Object.keys(validate(i + 1)).length));

    // ─── save ───────────────────────────────────────────────────────────
    const SERVER = {
        not_staff: [4, "You don't have permission to do that."],
        invalid_services: [2, 'Choose at least one service (add-ons need a main service).'],
        invalid_details: [1, 'Enter the client’s first name.'],
        invalid_phone: [1, 'That phone number doesn’t look right.'],
        contact_required: [1, 'Enter a phone number or an email so you can reach the client.'],
        phone_in_use: [1, 'That phone number belongs to another client. Choose them from the last name list, or use a different number.'],
        client_not_found: [1, 'That client no longer exists. Clear the selection and try again.'],
        slot_taken: [3, 'That time was just taken. Choose another time.'],
        invalid_price: [2, 'Enter a price of $0 or more.'],
        invalid_kind: [1, 'Choose Client or Friends & family.'],
        invalid_time: [3, 'Choose a date and time.']
    };

    /** The person currently in the form, as one entry of the booking. */
    function current() {
        const v = visitAt(time);
        return {
            client, lastName: lastName.trim(), firstName: firstName.trim(),
            phoneE164: phone.trim() ? toE164(phoneCountry, phone) : null, email: email.trim() || null,
            goldCard, chosen: [...chosen], services: picked.map(x => x.name), total, ranged: picked.some(x => x.range),
            date, time, start: v.start, end: v.end, gaps: v.gaps, notes: notes.trim() || null,
            kind: mode, priceCents, priceText
        };
    }

    /** Add this person to the booking and start on the next one: same services and day, straight after. */
    function addPerson() {
        for (const n of [1, 2, 3]) {
            const err = validate(n);
            if (Object.keys(err).length) { showStep(n, err); return; }
        }
        const me = current();
        party = [...party, me];
        const kept = { chosen: me.chosen, date: me.date, nextAt: me.end };
        lastName = firstName = phone = email = notes = time = stepError = '';
        client = null; phoneCountry = 'NZ'; goldCard = false;
        lastSearch.clear(); firstSearch.clear();
        chosen = kept.chosen; date = kept.date;
        // Same kind of booking and price rule for the next person.
        mode = me.kind; priceText = me.priceText; showContact = false;
        nextStart = kept.nextAt;
        showStep(1);
    }
    // Suggest the time straight after the previous person, once it's known to be free.
    let nextStart = $state(null);
    $effect(() => {
        if (nextStart == null || dayLoaded !== date || !freeTimes.length) return;
        const hhmm = new Intl.DateTimeFormat('en-NZ', { timeZone: SALON_TZ, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(nextStart);
        untrack(() => {
            time = freeTimes.includes(hhmm) ? hhmm : (freeTimes.find(t => t > hhmm) ?? '');
            nextStart = null;
        });
    });
    const removePerson = (i) => { party = party.filter((_, j) => j !== i); };

    async function save() {
        for (const n of [1, 2, 3]) {
            const err = validate(n);
            if (Object.keys(err).length) { showStep(n, err); return; }
        }
        const everyone = [...party, current()];
        saving = true;
        stepError = '';
        const { data, error } = await sb.rpc('s4_staff_create_bookings', {
            p_bookings: everyone.map(m => ({
                client_id: m.client?.id ?? null,
                last_name: m.lastName,
                first_name: m.firstName,
                phone: m.phoneE164,
                email: m.email,
                service_ids: m.chosen,
                starts_at: new Date(m.start).toISOString(),
                gold_card: m.goldCard,
                notes: m.notes,
                kind: m.kind,
                price_cents: m.priceCents
            }))
        });
        saving = false;
        if (error) {
            const [n, msg] = SERVER[errorCode(error)] ?? [4, adminError(error)];
            const who = party.length ? ' (one of the people in this booking)' : '';
            if (n === 3) dayRefresh += 1;
            showStep(party.length ? 4 : n, {}, msg + who);
            return;
        }
        const iso = everyone[0].date;
        open = false;
        oncreated?.(data[0].id, iso);
    }
</script>

{#snippet clientList(search)}
    {#if search.open}
        <ul class="options" id={search.listId} role="listbox" aria-label="Matching clients">
            {#each search.matches as c, i (c.id)}
                <li id={search.optionId(i)} role="option" aria-selected={i === search.active} class:active={i === search.active}
                    onpointerdown={(e) => { e.preventDefault(); pick(c); }}
                    onpointermove={() => search.active = i}>
                    <span class="who"><strong>{c.last_name}</strong>, {c.first_name}</span>
                    <span class="how">{c.phone_e164 ? showPhone(c.phone_e164) : c.email || 'No contact details'}</span>
                    {#if c.has_gold_card}<span class="tag">Gold Card</span>{/if}
                </li>
            {:else}
                <li class="none" role="presentation">No match: a new client will be added.</li>
            {/each}
        </ul>
    {/if}
{/snippet}

<Modal bind:open title="New booking" wide>
    <ol class="steps" aria-label="Steps">
        {#each STEPS as label, i}
            {@const n = i + 1}
            <li class:current={n === step} class:done={n < step}>
                <button type="button" aria-current={n === step ? 'step' : undefined}
                    disabled={n === step || !canReach(n)} onclick={() => showStep(n)}>
                    <span class="num" aria-hidden="true">{#if n < step}<i class="ph ph-check"></i>{:else}{n}{/if}</span>
                    <span class="name">{label}</span>
                    {#if n < step}<span class="sr-only">(done)</span>{/if}
                </button>
            </li>
        {/each}
    </ol>

    <form id="{uid}-form" class="modal-form" onsubmit={next} novalidate>
        {#if step === 1}
            <h3 id="{uid}-h1" class="wide step-title" tabindex="-1">Client</h3>
            <div class="wide mode" role="radiogroup" aria-label="Type of booking">
                <label class:on={mode === 'client'}><input type="radio" name="{uid}-mode" value="client" bind:group={mode} onchange={switchMode} /> Client</label>
                <label class:on={mode === 'staff'}><input type="radio" name="{uid}-mode" value="staff" bind:group={mode} onchange={switchMode} /> Friends &amp; family</label>
            </div>
            {#if mode === 'staff'}
                <p class="wide mode-note"><i class="ph ph-heart" aria-hidden="true"></i>
                    <span>Booked by <strong>{staffName || 'you'}</strong>. No phone or email needed: you're their contact.</span></p>
            {/if}
            <div class="combo name-field">
                <label for="{uid}-f-firstName">First name</label>
                <div class="combo-field">
                    <input id="{uid}-f-firstName" bind:this={firstEl} bind:value={firstName}
                        oninput={() => firstSearch.input()} onkeydown={(e) => firstSearch.keydown(e)}
                        onfocus={() => firstSearch.focus()} onblur={() => firstSearch.blur()}
                        role="combobox" aria-autocomplete="list" aria-controls={firstSearch.listId} aria-expanded={firstSearch.open}
                        aria-activedescendant={firstSearch.open && firstSearch.active >= 0 ? firstSearch.optionId(firstSearch.active) : undefined}
                        aria-invalid={!!errors.firstName}
                        aria-describedby={errors.firstName ? `${uid}-e-firstName ${uid}-search-hint` : `${uid}-search-hint`}
                        autocomplete="off" autocapitalize="words" spellcheck="false" />
                    {@render clientList(firstSearch)}
                </div>
                {#if errors.firstName}<span class="field-error" id="{uid}-e-firstName">{errors.firstName}</span>{/if}
            </div>

            <div class="combo name-field">
                <label for="{uid}-last">Last name</label>
                <div class="combo-field">
                    <input id="{uid}-last" bind:value={lastName}
                        oninput={() => lastSearch.input()} onkeydown={(e) => lastSearch.keydown(e)}
                        onfocus={() => lastSearch.focus()} onblur={() => lastSearch.blur()}
                        role="combobox" aria-autocomplete="list" aria-controls={lastSearch.listId} aria-expanded={lastSearch.open}
                        aria-activedescendant={lastSearch.open && lastSearch.active >= 0 ? lastSearch.optionId(lastSearch.active) : undefined}
                        aria-describedby="{uid}-search-hint" autocomplete="off" autocapitalize="words" spellcheck="false" />
                    {@render clientList(lastSearch)}
                </div>
            </div>

            <p id="{uid}-search-hint" class="wide hint search-hint" aria-live="polite">
                {#if client}
                    <span class="chip"><i class="ph ph-user-check" aria-hidden="true"></i> Existing client
                        <button type="button" aria-label="Clear the chosen client" onclick={() => unpick()}><i class="ph ph-x" aria-hidden="true"></i></button></span>
                {:else if searchHint}{searchHint}
                {:else if mode === 'staff'}Type three letters to find someone you've booked before.
                {:else}Type three letters of either name to find an existing client.{/if}
            </p>

            {#if mode === 'client' || showContact}
            <label>
                Email
                <input id="{uid}-f-email" type="email" bind:value={email} autocomplete="off" disabled={!!client?.email_verified}
                    aria-invalid={!!(errors.email || errors.contact)}
                    aria-describedby={errors.email ? `${uid}-e-email` : errors.contact ? `${uid}-e-contact` : undefined} />
                {#if errors.email}<span class="field-error" id="{uid}-e-email">{errors.email}</span>{/if}
            </label>
            <div class="field">
                <label for="{uid}-f-phone">Phone <span class="optional">{mode === 'staff' ? '(optional)' : '(or email)'}</span></label>
                <PhoneInput id="{uid}-f-phone" bind:country={phoneCountry} bind:value={phone}
                    invalid={!!(errors.phone || errors.contact)}
                    describedby={errors.phone ? `${uid}-e-phone` : errors.contact ? `${uid}-e-contact` : undefined} />
                {#if errors.phone}<span class="field-error" id="{uid}-e-phone">{errors.phone}</span>{/if}
            </div>
            {:else}
                <div class="wide"><button type="button" class="link-btn" onclick={() => showContact = true}><i class="ph ph-plus" aria-hidden="true"></i> Add contact details (optional)</button></div>
            {/if}
            {#if errors.contact}<p class="wide field-error" id="{uid}-e-contact">{errors.contact}</p>{/if}

        {:else if step === 2}
            <h3 id="{uid}-h2" class="wide step-title" tabindex="-1">Service</h3>
            {#if lastVisit}
                <section class="wide last-visit" aria-labelledby="{uid}-lv">
                    <div>
                        <p class="label" id="{uid}-lv">Last visit · {showDay(lastVisit.starts_at)}</p>
                        <p class="lv-items">
                            {#each lastVisit.items as item, i}{i ? ' + ' : ''}{item.name}{#if !offered(item.service_id)} <span class="tag retired">No longer offered</span>{/if}{/each}
                        </p>
                    </div>
                    {#if lastOffered.length}
                        <button type="button" class="secondary with-icon" aria-pressed={sameAsLast} onclick={bookSame}>
                            <i class="ph {sameAsLast ? 'ph-check' : 'ph-arrow-counter-clockwise'}" aria-hidden="true"></i>
                            {sameAsLast ? 'Chosen' : 'Book the same'}
                        </button>
                    {/if}
                </section>
            {/if}

            <fieldset class="wide services" aria-describedby={errors.services ? `${uid}-e-services` : undefined}>
                <legend>{lastVisit ? 'Or choose services' : 'Services'}</legend>
                {#if catalogueError}
                    <p class="error">{catalogueError}</p>
                {:else if !catalogue}
                    <p class="muted" role="status">Loading services…</p>
                {:else}
                    <div class="service-list" id="{uid}-f-services" tabindex="-1">
                        {#each groups as g (g.id)}
                            <p class="group">{g.name}</p>
                            {#each g.services as s (s.id)}
                                <label class="check service">
                                    <input type="checkbox" value={s.id} bind:group={chosen} />
                                    <span class="name">{s.name}{#if s.addon} <span class="tag">Add-on</span>{/if}</span>
                                    <span class="meta">{formatDuration(s.duration)} · {formatPrice(priceFor(s, goldCard), s.range)}</span>
                                </label>
                            {/each}
                        {/each}
                    </div>
                {/if}
                {#if errors.services}<p class="field-error" id="{uid}-e-services">{errors.services}</p>{/if}
                <p class="summary-line" aria-live="polite">
                    {#if picked.length}
                        {picked.length} {picked.length === 1 ? 'service' : 'services'} · {formatDuration(duration)}{#if waiting}{' '}({waiting} min waiting){/if}
                        · {formatPrice(total, picked.some(s => s.range))}
                    {:else}No services chosen.{/if}
                </p>
            </fieldset>
            <div class="wide"><Switch bind:checked={goldCard} label="Gold Card prices" showLabel /></div>
            {#if mode === 'staff' && picked.length}
                <label class="price">
                    <span>Price <span class="optional">(friends &amp; family)</span></span>
                    <span class="money"><span aria-hidden="true">$</span>
                        <input id="{uid}-f-price" type="number" inputmode="decimal" min="0" step="0.5" bind:value={priceText}
                            placeholder={String(normalTotal)} aria-invalid={!!errors.price}
                            aria-describedby="{uid}-price-hint" /></span>
                    <span class="hint" id="{uid}-price-hint">{#if errors.price}<span class="field-error">{errors.price}</span>{:else if priceCents != null && priceCents !== Math.round(normalTotal * 100)}Was {formatPrice(normalTotal)}{:else}Leave empty to charge the normal {formatPrice(normalTotal)}.{/if}</span>
                </label>
            {/if}

        {:else if step === 3}
            <h3 id="{uid}-h3" class="wide step-title" tabindex="-1">Date &amp; time</h3>
            <p class="wide muted">{formatDuration(duration)} visit{#if waiting}, with {waiting} min waiting{/if}.</p>
            <label>
                Date
                <input id="{uid}-f-date" type="date" bind:value={date} required
                    aria-invalid={!!errors.date} aria-describedby={errors.date ? `${uid}-e-date` : undefined} />
                {#if errors.date}<span class="field-error" id="{uid}-e-date">{errors.date}</span>{/if}
            </label>
            <label>
                Time
                <select id="{uid}-f-time" bind:value={time} required disabled={dayLoaded !== date || !freeTimes.length}
                    aria-invalid={!!errors.time} aria-describedby={errors.time ? `${uid}-e-time` : endsAt ? `${uid}-ends` : undefined}>
                    {#if dayLoaded !== date}
                        <option value="">Checking…</option>
                    {:else if !freeTimes.length}
                        <option value="">No free times on this day</option>
                    {:else}
                        <option value="" disabled>Choose a time</option>
                        {#each freeTimes as t}<option value={t}>{clock(t)}</option>{/each}
                    {/if}
                </select>
                {#if errors.time}<span class="field-error" id="{uid}-e-time">{errors.time}</span>{/if}
                {#if endsAt}<span class="ends" id="{uid}-ends">Ends {clockAt(endsAt)}</span>{/if}
            </label>

        {:else}
            <h3 id="{uid}-h4" class="wide step-title" tabindex="-1">Summary{#if party.length}{' · '}{party.length + 1} people{/if}</h3>
            {#if party.length}
                <section class="wide review" aria-labelledby="{uid}-party">
                    <header><h4 id="{uid}-party">Also in this booking</h4></header>
                    <ul class="lines party">
                        {#each party as m, i}
                            <li>
                                <span><strong>{m.firstName} {m.lastName}</strong> · {m.services.join(', ')} · {clockAt(m.start)}–{clockAt(m.end)}{#if m.kind === 'staff'}<span class="muted"> · friends &amp; family</span>{/if}</span>
                                <button type="button" class="remove-person" aria-label="Remove {m.firstName} from this booking" onclick={() => removePerson(i)}><i class="ph ph-x" aria-hidden="true"></i></button>
                            </li>
                        {/each}
                    </ul>
                </section>
                <p class="wide muted">This person:</p>
            {/if}
            <section class="wide review" aria-labelledby="{uid}-s1">
                <header><h4 id="{uid}-s1">Client</h4><button type="button" class="edit" onclick={() => showStep(1)}>Edit<span class="sr-only"> client</span></button></header>
                <p class="strong">{firstName.trim()} {lastName.trim()} <span class="tag" class:retired={!client}>{client ? 'Existing client' : 'New client'}</span></p>
                {#if email.trim()}<p>{email.trim()}</p>{/if}
                {#if phone.trim()}<p>{showInternational(phoneCountry, phone)}</p>{/if}
                {#if mode === 'staff'}<p><span class="tag">Friends &amp; family</span> <span class="muted">booked by {staffName || 'you'}</span></p>{/if}
            </section>
            <section class="wide review" aria-labelledby="{uid}-s2">
                <header><h4 id="{uid}-s2">Services</h4><button type="button" class="edit" onclick={() => showStep(2)}>Edit<span class="sr-only"> services</span></button></header>
                <ul class="lines">
                    {#each picked as s (s.id)}
                        <li><span>{s.name}</span><span>{formatPrice(priceFor(s, goldCard), s.range)}</span></li>
                    {/each}
                    <li class="total"><span>{formatDuration(duration)}{#if waiting} · {waiting} min waiting{/if}{#if goldCard} · Gold Card{/if}</span><span>{#if priceCents != null && priceCents !== Math.round(normalTotal * 100)}<s class="muted was">{formatPrice(normalTotal)}</s> {/if}{formatPrice(total, priceCents == null && picked.some(s => s.range))}</span></li>
                </ul>
            </section>
            <section class="wide review" aria-labelledby="{uid}-s3">
                <header><h4 id="{uid}-s3">Date &amp; time</h4><button type="button" class="edit" onclick={() => showStep(3)}>Edit<span class="sr-only"> date and time</span></button></header>
                <p class="strong">{showDay(salonInstant(date, time, SALON_TZ))}, {clock(time)} – {clockAt(endsAt)}</p>
            </section>
            <label class="wide">
                <span>Notes <span class="optional">(optional)</span></span>
                <textarea bind:value={notes} rows="2" maxlength="1000"></textarea>
            </label>
            <div class="wide add-person">
                <button type="button" class="secondary with-icon" onclick={addPerson} disabled={party.length >= 9}>
                    <i class="ph ph-user-plus" aria-hidden="true"></i> Add another person
                </button>
                <span class="muted">Book family or friends straight after, in one go.</span>
            </div>
        {/if}

        {#if stepError}<p class="error wide" role="alert">{stepError}</p>{/if}
    </form>

    {#snippet footer()}
        {#if step === 1}
            <button type="button" class="secondary" onclick={() => open = false}>Cancel</button>
        {:else}
            <button type="button" class="secondary with-icon" onclick={back}><i class="ph ph-arrow-left" aria-hidden="true"></i> Back</button>
        {/if}
        <button type="submit" form="{uid}-form" class="primary" disabled={saving}>
            {step === 4 ? (saving ? 'Booking…' : 'Book') : 'Next'}
        </button>
    {/snippet}
</Modal>

<style>
    /* Step bar */
    .steps {
        counter-reset: none;
        display: flex;
        gap: 0.25rem;
        list-style: none;
        margin: 0 0 1.25rem;
        padding: 0;
    }
    .steps li {
        flex: 1;
        min-width: 0;
    }
    .steps button {
        align-items: center;
        border-bottom: 3px solid var(--adm-border);
        color: var(--adm-text-muted);
        cursor: pointer;
        display: flex;
        font-size: 0.875rem;
        font-weight: 600;
        gap: 0.5rem;
        min-height: 2.75rem;
        padding: 0.25rem 0.125rem 0.5rem;
        text-align: left;
        width: 100%;
    }
    .steps button:disabled {
        cursor: default;
    }
    .steps li:not(.current) button:disabled {
        opacity: 0.7;
    }
    .steps li.done button {
        border-bottom-color: var(--adm-accent-line);
        color: var(--adm-text);
    }
    .steps li.done button:hover .name {
        text-decoration: underline;
    }
    .steps li.current button {
        border-bottom-color: var(--adm-selected-border);
        color: var(--adm-text);
        opacity: 1;
    }
    .num {
        align-items: center;
        border: 1.5px solid currentColor;
        border-radius: 50%;
        display: inline-flex;
        flex: none;
        font-variant-numeric: tabular-nums;
        height: 1.625rem;
        justify-content: center;
        width: 1.625rem;
    }
    .current .num {
        background-color: var(--adm-inverse-bg);
        border-color: var(--adm-inverse-bg);
        color: var(--adm-inverse-text);
    }
    .done .num {
        background-color: var(--adm-accent-soft);
        border-color: var(--adm-accent-line);
        color: var(--adm-accent-text);
    }
    .name {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .modal-form {
        display: grid;
        gap: 1rem;
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
    .wide {
        grid-column: 1 / -1;
    }
    .step-title {
        color: var(--adm-text);
        font: 600 1rem / 1.3 var(--font-default);
        outline-offset: 4px;
    }
    .modal-form label:not(.check),
    .combo > label,
    legend,
    .label {
        color: var(--adm-text);
        display: flex;
        flex-direction: column;
        font-size: 0.9375rem;
        font-weight: 600;
        gap: 0.375rem;
    }
    .label {
        display: block;
    }
    .modal-form input:not([type="checkbox"]),
    .modal-form select,
    .modal-form textarea {
        width: 100%;
    }
    .optional {
        color: var(--adm-text-muted);
        font-weight: 400;
    }
    .field-error {
        color: var(--adm-danger);
        font-size: 0.875rem;
        font-weight: 600;
    }
    .ends {
        color: var(--adm-text-muted);
        font-size: 0.875rem;
        font-weight: 400;
    }

    /* Last name with its list of matching clients */
    .field {
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
        min-width: 0;
    }
    .modal-form .field > label {
        color: var(--adm-text);
        display: block;
        font-size: 0.9375rem;
        font-weight: 600;
    }
    .combo.name-field {
        align-self: start;
    }
    .search-hint {
        margin-top: -0.625rem;
    }
    .combo {
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
    }
    .combo-field {
        position: relative;
    }
    .options {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border-strong);
        border-radius: 0.375rem;
        box-shadow: var(--adm-shadow-hover);
        left: 0;
        list-style: none;
        margin: 0.25rem 0 0;
        max-height: 18rem;
        overflow-y: auto;
        padding: 0.25rem;
        position: absolute;
        right: 0;
        top: 100%;
        z-index: 5;
    }
    .options li {
        align-items: baseline;
        border-radius: 0.25rem;
        cursor: pointer;
        display: flex;
        flex-wrap: wrap;
        gap: 0.25rem 0.75rem;
        min-height: 2.75rem;
        padding: 0.625rem 0.75rem;
    }
    .options li.active {
        background-color: var(--adm-selected-bg);
        box-shadow: inset 3px 0 0 var(--adm-selected-border);
    }
    .options li.none {
        color: var(--adm-text-muted);
        cursor: default;
    }
    .who {
        color: var(--adm-text);
    }
    .how {
        color: var(--adm-text-muted);
        font-variant-numeric: tabular-nums;
    }
    .hint {
        color: var(--adm-text-muted);
        font-size: 0.875rem;
        min-height: 1.5rem;
    }
    .chip {
        align-items: center;
        background-color: var(--adm-success-bg);
        border: 1px solid var(--adm-success-border);
        border-radius: 999px;
        color: var(--adm-success-text);
        display: inline-flex;
        font-weight: 600;
        gap: 0.375rem;
        padding: 0 0.25rem 0 0.625rem;
    }
    .chip button {
        border-radius: 50%;
        color: inherit;
        cursor: pointer;
        display: grid;
        height: 2rem;
        place-items: center;
        width: 2rem;
    }
    .chip button:hover {
        background-color: var(--adm-surface);
    }
    .tag {
        background-color: var(--adm-accent-soft);
        border-radius: 0.25rem;
        color: var(--adm-accent-text);
        font-size: 0.75rem;
        font-weight: 600;
        padding: 0.0625rem 0.375rem;
        white-space: nowrap;
    }
    .tag.retired {
        background-color: var(--adm-border);
        color: var(--adm-text-muted);
    }

    /* Services */
    .last-visit {
        align-items: center;
        background-color: var(--adm-sunken);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem 1rem;
        justify-content: space-between;
        padding: 0.875rem 1rem;
    }
    .last-visit .label {
        color: var(--adm-text-muted);
        font-size: 0.8125rem;
    }
    .lv-items {
        color: var(--adm-text);
        font-weight: 600;
        margin-top: 0.125rem;
    }
    .last-visit button[aria-pressed="true"] {
        border-color: var(--adm-success-border);
        color: var(--adm-success-text);
    }
    .services {
        border: 0;
        margin: 0;
        min-width: 0;
        padding: 0;
    }
    legend {
        margin-bottom: 0.375rem;
        padding: 0;
    }
    .service-list {
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        max-height: 18rem;
        overflow-y: auto;
        padding: 0.25rem 0.75rem 0.5rem;
    }
    .group {
        color: var(--adm-text-muted);
        font-size: 0.75rem;
        font-weight: 600;
        letter-spacing: 0.06em;
        padding: 0.75rem 0 0.125rem;
        text-transform: uppercase;
    }
    .check.service {
        align-items: center;
        cursor: pointer;
        display: flex;
        gap: 0.625rem;
        min-height: 2.75rem;
    }
    .service .name {
        color: var(--adm-text);
        flex: 1;
        white-space: normal;
    }
    .service .meta {
        color: var(--adm-text-muted);
        font-size: 0.875rem;
        font-variant-numeric: tabular-nums;
        text-align: right;
    }
    .mode {
        background-color: var(--adm-sunken);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        display: flex;
        padding: 0.1875rem;
    }
    .modal-form .mode label {
        align-items: center;
        border-radius: 0.25rem;
        color: var(--adm-text-muted);
        cursor: pointer;
        flex: 1;
        flex-direction: row;
        font-weight: 600;
        gap: 0.375rem;
        justify-content: center;
        min-height: 2.5rem;
        position: relative;
    }
    .modal-form .mode label.on {
        background-color: var(--adm-inverse-bg);
        color: var(--adm-inverse-text);
    }
    .mode input {
        height: 1px;
        opacity: 0;
        position: absolute;
        width: 1px;
    }
    .mode label:has(input:focus-visible) {
        outline: 2px solid var(--adm-focus);
        outline-offset: 2px;
    }
    .mode-note {
        align-items: flex-start;
        color: var(--adm-text);
        display: flex;
        gap: 0.5rem;
        margin-top: -0.25rem;
    }
    .mode-note i {
        color: var(--adm-accent-line);
        margin-top: 0.1875rem;
    }
    .link-btn {
        align-items: center;
        color: var(--adm-text);
        cursor: pointer;
        display: inline-flex;
        font-weight: 600;
        gap: 0.375rem;
        min-height: 2.75rem;
        text-decoration: underline;
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    .money {
        align-items: center;
        display: flex;
        gap: 0.375rem;
        max-width: 12rem;
    }
    .price .hint {
        font-weight: 400;
    }
    .was {
        margin-right: 0.25rem;
    }
    .add-person {
        align-items: center;
        border-top: 1px dashed var(--adm-border);
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 0.75rem;
        padding-top: 0.875rem;
    }
    .party li {
        align-items: center;
    }
    .remove-person {
        border-radius: 50%;
        color: var(--adm-text-muted);
        cursor: pointer;
        display: grid;
        flex: none;
        height: 2.75rem;
        place-items: center;
        width: 2.75rem;
    }
    .remove-person:hover {
        background-color: var(--adm-danger-bg);
        color: var(--adm-danger);
    }
    .summary-line {
        color: var(--adm-text);
        font-weight: 600;
        margin-top: 0.5rem;
    }

    /* Summary */
    .review {
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        color: var(--adm-text-body);
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        padding: 0.75rem 1rem 0.875rem;
    }
    .review header {
        align-items: center;
        display: flex;
        justify-content: space-between;
    }
    .review h4 {
        color: var(--adm-text-muted);
        font: 600 0.75rem / 1.2 var(--font-default);
        letter-spacing: 0.06em;
        text-transform: uppercase;
    }
    .edit {
        color: var(--adm-text);
        cursor: pointer;
        font-size: 0.875rem;
        font-weight: 600;
        min-height: 2.25rem;
        padding: 0 0.25rem;
        text-decoration: underline;
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    .strong {
        color: var(--adm-text);
        font-weight: 600;
    }
    .lines {
        list-style: none;
        margin: 0;
        padding: 0;
    }
    .lines li {
        display: flex;
        gap: 1rem;
        justify-content: space-between;
        padding: 0.125rem 0;
    }
    .lines li span:last-child {
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }
    .lines .total {
        border-top: 1px solid var(--adm-border);
        color: var(--adm-text);
        font-weight: 600;
        margin-top: 0.25rem;
        padding-top: 0.375rem;
    }

    @media (max-width: 40rem) {
        .modal-form {
            grid-template-columns: minmax(0, 1fr);
        }
        /* Phones: numbers only, plus the current step's name. */
        .steps li:not(.current) .name {
            border: 0;
            clip: rect(0 0 0 0);
            height: 1px;
            margin: -1px;
            overflow: hidden;
            position: absolute;
            width: 1px;
        }
        .steps li {
            flex: 0 0 auto;
        }
        .steps li.current {
            flex: 1;
        }
    }
</style>
