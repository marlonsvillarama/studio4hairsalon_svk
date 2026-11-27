<script>
    import { onMount, tick, untrack } from 'svelte';
    import { page } from '$app/state';
    import { goto } from '$app/navigation';
    import { getSupabase } from '$lib/supabase';
    import { adminError, showPhone, showShortDay, showTime, salonDay, dollars, STATUS_LABEL, loadHours, pageRange, urlPage, urlSize, savePageSize } from '$lib/admin';
    import Pager from '$lib/components/admin/pager.svelte';
    import Skeleton from '$lib/components/admin/skeleton.svelte';
    import { invoiceNumber } from '$lib/invoices';
    import BookingCreate from '$lib/components/admin/booking-create.svelte';
    import Modal from '$lib/components/admin/modal.svelte';
    import Switch from '$lib/components/admin/switch.svelte';
    import PhoneInput from '$lib/components/admin/phone-input.svelte';
    import { isValidPhone, toE164, fromE164, countryName } from '$lib/phone';

    const sb = getSupabase();
    let client = $state(null);
    let loading = $state(true);
    let loadError = $state('');
    let hours = $state({});
    let bookOpen = $state(false);

    const TABLE = 'clientBookings';
    const UP_TABLE = 'clientUpcoming';
    const BOOKING_COLS = `id, reference, starts_at, ends_at, status, total_cents, has_variable_price,
                          items:s4_booking_items ( name, sort_order ), invoices:s4_invoices ( id, number, status )`;
    const nowIso = new Date().toISOString();
    const now = Date.now();
    // Confirmed and still to come; everything else is past.
    const isUpcoming = (b) => b.status === 'confirmed' && new Date(b.ends_at).getTime() > now;

    let summary = $state([]);           // every booking, figures only (for the panels)
    let upcoming = $state([]);          // this page of upcoming bookings, soonest first
    let upTotal = $state(0);
    let upBusy = $state(false);
    let pastRows = $state([]);          // this page of past bookings
    let pastTotal = $state(0);
    let pastBusy = $state(false);

    async function load(id) {
        loading = !client || client.id !== id;
        const { data, error } = await sb.from('s4_clients')
            .select(`id, first_name, last_name, phone_e164, email, email_verified, auth_user_id, has_gold_card, is_family, created_at,
                     arranged:arranged_by ( id, first_name, last_name, phone_e164 )`)
            .eq('id', id)
            .maybeSingle();
        if (error) { loading = false; loadError = adminError(error); return; }
        loadError = '';
        if (!data) { client = null; loading = false; return; }
        const [sum, arr] = await Promise.all([
            sb.from('s4_bookings').select('id, status, total_cents, has_variable_price, starts_at, ends_at')
                .eq('client_id', id).order('starts_at', { ascending: false }),
            sb.from('s4_clients').select('id, first_name, last_name').eq('arranged_by', id).order('first_name')
        ]);
        loading = false;
        if (sum.error) { loadError = adminError(sum.error); return; }
        client = data;
        summary = sum.data;
        // People this client books for (family and friends without their own contact details).
        arranges = arr.data ?? [];
        loadUpcoming();
        loadPast();
    }

    // ─── two paged tables; each keeps its own page and size in the URL ───
    // Past: ?page= & ?size=   Upcoming: ?upage= & ?usize=
    function setParams(changes) {
        const params = new URLSearchParams(page.url.searchParams);
        for (const [k, v] of Object.entries(changes)) {
            if (v == null || ((k === 'page' || k === 'upage') && v === 1)) params.delete(k); else params.set(k, String(v));
        }
        const qs = params.toString();
        goto(qs ? `?${qs}` : page.url.pathname, { replaceState: true, keepFocus: true, noScroll: true });
    }

    let upPage = $derived(urlPage(page.url, 'upage'));
    let upSize = $derived(urlSize(page.url, UP_TABLE, 'usize'));
    const goUpPage = (n) => setParams({ upage: n });
    function setUpSize(n) {
        savePageSize(UP_TABLE, n);
        setParams({ usize: n, upage: Math.floor(((upPage - 1) * upSize) / n) + 1 });
    }
    let upSeq = 0;
    async function loadUpcoming() {
        if (!client) return;
        const mine = ++upSeq;
        upBusy = true;
        const [from, to] = pageRange(upPage, upSize);
        const { data, error, count } = await sb.from('s4_bookings').select(BOOKING_COLS, { count: 'exact' })
            .eq('client_id', client.id).eq('status', 'confirmed').gt('ends_at', nowIso)
            .order('starts_at').order('id')
            .range(from, to);
        if (mine !== upSeq) return;
        upBusy = false;
        if (error) {
            if (error.code === 'PGRST103' && upPage > 1) { goUpPage(Math.max(1, upPage - 1)); return; }
            loadError = adminError(error);
            return;
        }
        upTotal = count ?? 0;
        // The last row of the last page went (e.g. made into a hold): step back a page.
        if (!data.length && upPage > 1) { goUpPage(Math.max(1, Math.ceil(upTotal / upSize))); return; }
        upcoming = data;
    }

    let pageNo = $derived(urlPage(page.url));
    let size = $derived(urlSize(page.url, TABLE));
    const goPage = (n) => setParams({ page: n });
    function setSize(n) {
        savePageSize(TABLE, n);
        setParams({ size: n, page: Math.floor(((pageNo - 1) * size) / n) + 1 });
    }
    let pastSeq = 0;
    async function loadPast() {
        if (!client) return;
        const mine = ++pastSeq;
        pastBusy = true;
        const [from, to] = pageRange(pageNo, size);
        const { data, error, count } = await sb.from('s4_bookings').select(BOOKING_COLS, { count: 'exact' })
            .eq('client_id', client.id)
            .or(`status.neq.confirmed,ends_at.lte."${nowIso}"`)
            .order('starts_at', { ascending: false }).order('id')
            .range(from, to);
        if (mine !== pastSeq) return;
        pastBusy = false;
        if (error) {
            if (error.code === 'PGRST103' && pageNo > 1) { goPage(1); return; }
            loadError = adminError(error);
            return;
        }
        pastRows = data;
        pastTotal = count ?? 0;
    }
    onMount(() => { loadHours().then(h => hours = h).catch(() => {}); });
    $effect(() => { const id = page.params.id; untrack(() => load(id)); });
    $effect(() => { pageNo; size; untrack(loadPast); });
    $effect(() => { upPage; upSize; untrack(loadUpcoming); });

    const nameOf = (c) => `${c.first_name ?? ''} ${c.last_name ?? ''}`.trim() || 'Unnamed client';
    const services = (b) => b.items.toSorted((a, z) => a.sort_order - z.sort_order).map(i => i.name).join(', ');
    const invoiceOf = (b) => b.invoices?.find(i => i.status !== 'void') ?? null;
    const dayLink = (b) => `/admin?view=day&date=${salonDay(b.starts_at)}&open=${b.id}`;
    const showDate = (t) => new Date(t).toLocaleDateString('en-NZ', { timeZone: 'Pacific/Auckland', day: 'numeric', month: 'short', year: 'numeric' });

    // Figures for the summary panels, from the light list of every booking (newest first).
    let past = $derived(summary.filter(b => !isUpcoming(b)));
    let completed = $derived(past.filter(b => b.status === 'completed'));
    let spent = $derived(completed.reduce((n, b) => n + b.total_cents, 0));
    // Rounded to whole dollars: it's a guide, not an amount owed.
    let average = $derived(completed.length ? Math.round(spent / completed.length / 100) * 100 : 0);
    let missed = $derived(past.filter(b => b.status === 'cancelled' || b.status === 'no_show').length);
    let variable = $derived(completed.some(b => b.has_variable_price));
    // The soonest booking still to come, whichever Upcoming page is showing.
    let nextBooking = $derived(summary.filter(isUpcoming).at(-1) ?? null);
    let arranges = $state([]);

    // ─── tidying placeholder bookings (e.g. family booked under one name) ──
    let rowBusy = $state(null);
    let rowError = $state('');
    let renameOpen = $state(false);
    let renaming = $state(null);
    let renameForm = $state({ first: '', last: '' });
    let renameError = $state('');
    const bookingLabel = (b) => `${showShortDay(b.starts_at)}, ${showTime(b.starts_at)}`;

    function openRename(b) {
        renaming = b;
        renameForm = { first: '', last: client.last_name ?? '' };
        renameError = '';
        renameOpen = true;
    }
    // The booking becomes the real person's: a friends-and-family record, booked by
    // whoever is signed in (they're the contact).
    async function rename(e) {
        e.preventDefault();
        if (!renameForm.first.trim()) { renameError = 'Enter their first name.'; return; }
        rowBusy = renaming.id;
        const { data: { user } } = await sb.auth.getUser();
        const { data: person, error } = await sb.from('s4_clients')
            .insert({ first_name: renameForm.first.trim(), last_name: renameForm.last.trim() || null, is_family: true })
            .select('id').single();
        if (error) { rowBusy = null; renameError = adminError(error); return; }
        const { error: e2 } = await sb.from('s4_bookings')
            .update({ client_id: person.id, kind: 'staff', arranged_by_staff: user?.id ?? null }).eq('id', renaming.id);
        rowBusy = null;
        if (e2) { await sb.from('s4_clients').delete().eq('id', person.id); renameError = adminError(e2); return; }
        renameOpen = false;
        flash(`Booked for ${renameForm.first.trim()} now, as friends & family.`);
        load(client.id);
    }
    // A placeholder that's really "time kept free": becomes a hold, and the booking goes.
    async function makeHold(b) {
        rowBusy = b.id;
        rowError = '';
        const { data: { user } } = await sb.auth.getUser();
        const { data: hold, error } = await sb.from('s4_time_off')
            .insert({ starts_at: b.starts_at, ends_at: b.ends_at, kind: 'hold', reason: `Hold for ${client.first_name}`, created_by: user?.id })
            .select('id').single();
        if (error) { rowBusy = null; rowError = adminError(error); return; }
        const { error: e2 } = await sb.from('s4_bookings').delete().eq('id', b.id);
        rowBusy = null;
        if (e2) { await sb.from('s4_time_off').delete().eq('id', hold.id); rowError = adminError(e2); return; }
        flash(`${bookingLabel(b)} is now a hold.`);
        load(client.id);
    }
    async function cancelBooking(b) {
        rowBusy = b.id;
        rowError = '';
        const { error } = await sb.from('s4_bookings')
            .update({ status: 'cancelled', cancelled_at: new Date().toISOString(), cancel_reason: 'Placeholder removed' }).eq('id', b.id);
        rowBusy = null;
        if (error) { rowError = adminError(error); return; }
        flash(`${bookingLabel(b)} cancelled.`);
        load(client.id);
    }
    function flash(text) {
        notice = text;
        setTimeout(() => { if (notice === text) notice = ''; }, 4000);
    }

    const created = (id, day) => goto(`/admin?view=day&date=${day}&open=${id}`);

    // ─── edit contact details ───────────────────────────────────────────
    let editOpen = $state(false);
    let form = $state({});
    let errors = $state({});
    let saveError = $state('');
    let saving = $state(false);
    let notice = $state('');
    const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    function openEdit() {
        const p = fromE164(client.phone_e164);
        form = {
            last_name: client.last_name ?? '',
            first_name: client.first_name ?? '',
            email: client.email ?? '',
            country: p.country,
            phone: p.text,
            gold: !!client.has_gold_card,
            family: !!client.is_family
        };
        errors = {};
        saveError = '';
        editOpen = true;
    }

    function check() {
        const e = {};
        if (!form.first_name.trim()) e.first_name = 'Enter the client’s first name.';
        if (!client.email_verified && form.email.trim() && !EMAIL.test(form.email.trim())) e.email = 'That email doesn’t look right.';
        if (form.phone.trim() && !isValidPhone(form.country, form.phone)) {
            e.phone = form.country ? `That doesn’t look like a ${countryName(form.country)} number.` : 'Enter the full number, starting with + and the country code.';
        }
        // Friends & family are reached through staff, so contact details are optional for them.
        if (!form.family && !form.phone.trim() && !form.email.trim()) e.contact = 'Enter a phone number or an email so you can reach the client.';
        return e;
    }

    async function save(ev) {
        ev.preventDefault();
        errors = check();
        saveError = '';
        const first = ['first_name', 'email', 'contact', 'phone'].find(k => errors[k]);
        if (first) {
            await tick();
            document.getElementById(`edit-${first === 'contact' ? 'email' : first}`)?.focus();
            return;
        }
        const patch = {
            first_name: form.first_name.trim(),
            last_name: form.last_name.trim() || null,
            phone_e164: form.phone.trim() ? toE164(form.country, form.phone) : null,
            has_gold_card: form.gold,
            is_family: form.family
        };
        // A Google-verified email can't be changed here.
        if (!client.email_verified) patch.email = form.email.trim().toLowerCase() || null;
        saving = true;
        const { error } = await sb.from('s4_clients').update(patch).eq('id', client.id);
        saving = false;
        if (error) {
            saveError = error.code === '23505' ? 'duplicate' : adminError(error);
            return;
        }
        editOpen = false;
        await load(client.id);
        notice = 'Contact details saved.';
        setTimeout(() => { if (notice === 'Contact details saved.') notice = ''; }, 4000);
    }
</script>

<svelte:head><title>{client ? nameOf(client) : 'Client'} · Studio 4 admin</title></svelte:head>

<p class="back"><a href="/admin/clients"><i class="ph ph-arrow-left" aria-hidden="true"></i> Clients</a></p>

{#if loading && !client}
    <div class="loading-head" aria-hidden="true"><span></span></div>
    <Skeleton rows={4} columns={4} label="Loading client…" />
{:else if loadError}
    <p class="error">{loadError}</p>
{:else if !client}
    <div class="panel gone">
        <p>This client no longer exists. It may have been merged into another record.</p>
        <a href="/admin/clients">Back to Clients</a>
    </div>
{:else}
    <div class="page-head">
        <h1>{nameOf(client)}</h1>
        <button type="button" class="primary with-icon" onclick={() => bookOpen = true}>
            <i class="ph ph-calendar-plus" aria-hidden="true"></i> Book appointment
        </button>
    </div>

    <p class="notice" role="status">{#if notice}<i class="ph ph-check-circle" aria-hidden="true"></i> {notice}{/if}</p>

    <div class="summary">
        <section class="card" aria-labelledby="contact-title">
            <div class="card-head">
                <h2 id="contact-title">Contact details</h2>
                <button type="button" class="icon-btn edit" onclick={openEdit}
                    aria-label="Edit contact details for {nameOf(client)}" title="Edit contact details">
                    <i class="ph ph-pencil-simple" aria-hidden="true"></i>
                </button>
            </div>
            <p class="who">
                <strong>{nameOf(client)}</strong>
                {#if client.has_gold_card}<span class="badge warn">Gold Card</span>{/if}
                {#if client.is_family}<span class="badge">Friends &amp; family</span>{/if}
                {#if client.auth_user_id}<span class="badge"><i class="ph ph-google-logo" aria-hidden="true"></i> Google</span>{/if}
            </p>
            <dl>
                <div><dt>Phone</dt><dd>{#if client.phone_e164}<a href="tel:{client.phone_e164}">{showPhone(client.phone_e164)}</a>{:else}<span class="muted">None</span>{/if}</dd></div>
                <div><dt>Email</dt><dd class="email">{#if client.email}<a href="mailto:{client.email}">{client.email}</a>{:else}<span class="muted">None</span>{/if}</dd></div>
                <div><dt>Client since</dt><dd>{showDate(client.created_at)}</dd></div>
                <div><dt>Bookings</dt><dd>{summary.length}</dd></div>
                {#if client.arranged}
                    <div><dt>Arranged by</dt><dd><a href="/admin/clients/{client.arranged.id}">{client.arranged.first_name} {client.arranged.last_name ?? ''}</a>
                        {#if !client.phone_e164 && !client.email && client.arranged.phone_e164}<span class="via">Contact: <a href="tel:{client.arranged.phone_e164}">{showPhone(client.arranged.phone_e164)}</a></span>{/if}</dd></div>
                {/if}
                {#if arranges.length}
                    <div><dt>Books for</dt><dd class="arranges">{#each arranges as a, i (a.id)}{i ? ', ' : ''}<a href="/admin/clients/{a.id}">{a.first_name} {a.last_name ?? ''}</a>{/each}</dd></div>
                {/if}
            </dl>
        </section>

        <section class="card" aria-labelledby="money-title">
            <h2 id="money-title">Financial summary</h2>
            <p class="total"><span class="big">{dollars(spent)}</span> <span class="muted">total spent</span></p>
            <dl>
                <div><dt>Visits completed</dt><dd>{completed.length}</dd></div>
                <div><dt>Average per visit</dt><dd>{completed.length ? dollars(average) : '—'}</dd></div>
                <div><dt>Last visit</dt><dd>{completed[0] ? showDate(completed[0].starts_at) : '—'}</dd></div>
                <div><dt>Next booking</dt><dd>{#if nextBooking}<a href={dayLink(nextBooking)}>{showShortDay(nextBooking.starts_at)}, {showTime(nextBooking.starts_at)}</a>{:else}None{/if}</dd></div>
                <div><dt>Cancelled or no-show</dt><dd>{missed}</dd></div>
            </dl>
            {#if variable}<p class="note muted">Some visits had a “from” price; totals use the booked price.</p>{/if}
        </section>
    </div>

    {#if upTotal}
        <h2 class="table-title">Upcoming bookings</h2>
        <p class="muted table-hint">Booked a placeholder for someone else? <i class="ph ph-user-switch" aria-hidden="true"></i> <strong>Rename</strong> it to the real person (added as friends &amp; family), <i class="ph ph-hourglass-medium" aria-hidden="true"></i> turn it into a <strong>hold</strong>, or <i class="ph ph-x-circle" aria-hidden="true"></i> cancel it.</p>
        {#if rowError}<p class="error" role="alert">{rowError}</p>{/if}
        <table class="admin-table upcoming" class:busy={upBusy} aria-busy={upBusy}>
            <caption class="sr-only">Upcoming bookings, soonest first</caption>
            <thead>
                <tr>
                    <th scope="col">Date</th>
                    <th scope="col">Services</th>
                    <th scope="col" class="num">Total</th>
                    <th scope="col" class="actions-cell"><span class="sr-only">Actions</span></th>
                </tr>
            </thead>
            <tbody>
                {#each upcoming as b (b.id)}
                    <tr>
                        <td class="primary-cell"><a href={dayLink(b)}><strong>{showDate(b.starts_at)}</strong>, {showTime(b.starts_at)}</a></td>
                        <td data-label="Services">{services(b) || '—'}</td>
                        <td class="num" data-label="Total">{b.has_variable_price ? 'from ' : ''}{dollars(b.total_cents)}</td>
                        <td class="actions-cell">
                            <button type="button" class="icon-btn" disabled={rowBusy === b.id} onclick={() => openRename(b)}
                                aria-label="Rename the {bookingLabel(b)} booking to someone else" title="Rename to someone else">
                                <i class="ph ph-user-switch" aria-hidden="true"></i></button>
                            <button type="button" class="icon-btn" disabled={rowBusy === b.id} onclick={() => makeHold(b)}
                                aria-label="Turn the {bookingLabel(b)} booking into a hold" title="Make it a hold">
                                <i class="ph ph-hourglass-medium" aria-hidden="true"></i></button>
                            <button type="button" class="icon-btn danger-icon cancel-icon" disabled={rowBusy === b.id} onclick={() => cancelBooking(b)}
                                aria-label="Cancel the {bookingLabel(b)} booking" title="Cancel booking">
                                <i class="ph ph-x-circle" aria-hidden="true"></i></button>
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
        <Pager page={upPage} size={upSize} total={upTotal} label="upcoming bookings" onpage={goUpPage} onsize={setUpSize} />
    {/if}

    <h2 class="table-title">Past bookings</h2>
    <table class="admin-table" class:busy={pastBusy} aria-busy={pastBusy}>
        <caption class="sr-only">Past bookings, newest first</caption>
        <thead>
            <tr>
                <th scope="col">Date</th>
                <th scope="col">Services</th>
                <th scope="col" class="num">Total</th>
                <th scope="col">Status</th>
                <th scope="col">Invoice</th>
            </tr>
        </thead>
        <tbody>
            {#each pastRows as b (b.id)}
                {@const inv = invoiceOf(b)}
                <tr>
                    <td class="primary-cell"><a href={dayLink(b)}><strong>{showDate(b.starts_at)}</strong>, {showTime(b.starts_at)}</a></td>
                    <td data-label="Services">{services(b) || '—'}</td>
                    <td class="num" data-label="Total">{b.has_variable_price ? 'from ' : ''}{dollars(b.total_cents)}</td>
                    <td data-label="Status"><span class="badge s-{b.status}">{STATUS_LABEL[b.status]}</span></td>
                    <td data-label="Invoice">{#if inv}<a href="/admin/invoices/{inv.id}">{invoiceNumber(inv.number)}</a>{#if inv.status === 'draft'}{' '}<span class="muted">(draft)</span>{/if}{:else}<span class="muted">—</span>{/if}</td>
                </tr>
            {:else}
                <tr><td colspan="5" class="muted empty">No past bookings yet.</td></tr>
            {/each}
        </tbody>
    </table>
    <Pager page={pageNo} {size} total={pastTotal} label="past bookings" onpage={goPage} onsize={setSize} />

    <BookingCreate bind:open={bookOpen} client={client} day={salonDay(Date.now())} {hours} oncreated={created} />

    <Modal bind:open={renameOpen} title="Who is this booking for?">
        <form id="rename-form" class="edit-form" onsubmit={rename} novalidate>
            {#if renaming}<p class="muted">{bookingLabel(renaming)} · {services(renaming)}</p>{/if}
            <label>
                First name
                <input bind:value={renameForm.first} autocomplete="off" autocapitalize="words"
                    aria-invalid={!!renameError} aria-describedby={renameError ? 'rename-error' : undefined} />
            </label>
            <label>
                <span>Last name <span class="optional">(optional)</span></span>
                <input bind:value={renameForm.last} autocomplete="off" autocapitalize="words" />
            </label>
            <p class="hint">They're added as friends &amp; family, booked by you, so no phone or email is needed.</p>
            {#if renameError}<p class="error" id="rename-error" role="alert">{renameError}</p>{/if}
        </form>
        {#snippet footer()}
            <button type="button" class="secondary" onclick={() => renameOpen = false}>Cancel</button>
            <button type="submit" form="rename-form" class="primary" disabled={rowBusy}>Save</button>
        {/snippet}
    </Modal>

    <Modal bind:open={editOpen} title="Edit contact details">
        <form id="edit-form" class="edit-form" onsubmit={save} novalidate>
            <label>
                Last name
                <input id="edit-last_name" bind:value={form.last_name} autocomplete="off" autocapitalize="words" />
            </label>
            <label>
                First name
                <input id="edit-first_name" bind:value={form.first_name} autocomplete="off" autocapitalize="words"
                    aria-invalid={!!errors.first_name} aria-describedby={errors.first_name ? 'edit-e-first' : undefined} />
                {#if errors.first_name}<span class="field-error" id="edit-e-first">{errors.first_name}</span>{/if}
            </label>
            <label>
                Email
                <input id="edit-email" type="email" bind:value={form.email} autocomplete="off" disabled={client.email_verified}
                    aria-invalid={!!(errors.email || errors.contact)}
                    aria-describedby={client.email_verified ? 'edit-h-email' : errors.email ? 'edit-e-email' : errors.contact ? 'edit-e-contact' : undefined} />
                {#if client.email_verified}<span class="hint" id="edit-h-email">Comes from their Google sign-in, so it can’t be changed here.</span>{/if}
                {#if errors.email}<span class="field-error" id="edit-e-email">{errors.email}</span>{/if}
            </label>
            <div class="field">
                <label for="edit-phone">Phone <span class="optional">(or email)</span></label>
                <PhoneInput id="edit-phone" bind:country={form.country} bind:value={form.phone}
                    invalid={!!(errors.phone || errors.contact)}
                    describedby={errors.phone ? 'edit-e-phone' : errors.contact ? 'edit-e-contact' : undefined} />
                {#if errors.phone}<span class="field-error" id="edit-e-phone">{errors.phone}</span>{/if}
            </div>
            {#if errors.contact}<p class="field-error" id="edit-e-contact">{errors.contact}</p>{/if}
            <Switch bind:checked={form.gold} label="Gold Card" showLabel />
            <Switch bind:checked={form.family} label="Friends & family (no contact details needed)" showLabel />
            {#if saveError === 'duplicate'}
                <p class="error" role="alert">That phone number or email belongs to another client. If they’re the same person,
                    merge the two records on the <a href="/admin/clients">Clients page</a>.</p>
            {:else if saveError}
                <p class="error" role="alert">{saveError}</p>
            {/if}
        </form>
        {#snippet footer()}
            <button type="button" class="secondary" onclick={() => editOpen = false}>Cancel</button>
            <button type="submit" form="edit-form" class="primary" disabled={saving}>{saving ? 'Saving…' : 'Save'}</button>
        {/snippet}
    </Modal>
{/if}

<style>
    .back {
        margin-bottom: 0.5rem;
    }
    .back a {
        align-items: center;
        color: var(--adm-text-muted);
        display: inline-flex;
        gap: 0.375rem;
        min-height: 2.75rem;
        text-decoration: none;
    }
    .back a:hover {
        color: var(--adm-text);
    }
    a:not(.back a) {
        color: var(--adm-text);
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }

    .summary {
        display: grid;
        gap: 1rem;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        margin-bottom: 2rem;
    }
    .card {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border);
        border-radius: var(--adm-radius-lg);
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        padding: 1.125rem 1.25rem 1.25rem;
    }
    .card-head {
        align-items: center;
        display: flex;
        justify-content: space-between;
        margin: -0.5rem 0 -0.25rem;
    }
    .edit {
        margin-right: -0.5rem;
    }
    .loading-head {
        margin: 0.25rem 0 1.5rem;
    }
    .loading-head span {
        background-color: var(--adm-border);
        border-radius: 0.25rem;
        display: block;
        height: 1.75rem;
        width: min(18rem, 60%);
    }
    .notice {
        align-items: center;
        color: var(--adm-success-text);
        display: flex;
        font-weight: 600;
        gap: 0.375rem;
        margin: -0.5rem 0 0.75rem;
    }
    .notice:empty {
        margin: 0;
    }
    .edit-form {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    .edit-form label {
        color: var(--adm-text);
        display: flex;
        flex-direction: column;
        font-size: 0.9375rem;
        font-weight: 600;
        gap: 0.375rem;
    }
    .edit-form .field {
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
    }
    .edit-form .field > label {
        display: block;
    }
    .edit-form input {
        width: 100%;
    }
    .optional,
    .hint {
        color: var(--adm-text-muted);
        font-weight: 400;
    }
    .hint {
        font-size: 0.8125rem;
    }
    .field-error {
        color: var(--adm-danger);
        font-size: 0.875rem;
        font-weight: 600;
    }
    .error a {
        color: inherit;
        font-weight: 600;
    }
    .card h2 {
        color: var(--adm-text-muted);
        font: 600 0.75rem / 1.2 var(--font-default);
        letter-spacing: 0.06em;
        text-transform: uppercase;
    }
    .who {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.375rem;
    }
    .who strong {
        color: var(--adm-text);
        font-size: 1.125rem;
        margin-right: 0.25rem;
    }
    .total {
        align-items: baseline;
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
    }
    .big {
        color: var(--adm-text);
        font-size: 1.75rem;
        font-variant-numeric: tabular-nums;
        font-weight: 700;
        line-height: 1.1;
    }
    dl {
        display: flex;
        flex-direction: column;
    }
    dl div {
        border-top: 1px solid var(--adm-border);
        display: flex;
        gap: 1rem;
        justify-content: space-between;
        padding: 0.5rem 0;
    }
    dl div:last-child {
        padding-bottom: 0;
    }
    dt {
        color: var(--adm-text-muted);
    }
    dd {
        color: var(--adm-text);
        font-variant-numeric: tabular-nums;
        font-weight: 600;
        min-width: 0;
        text-align: right;
    }
    .email {
        overflow-wrap: anywhere;
    }
    .note {
        font-size: 0.8125rem;
    }

    .via {
        color: var(--adm-text-muted);
        display: block;
        font-size: 0.875rem;
        font-weight: 400;
    }
    .arranges {
        text-align: right;
    }
    table.busy {
        opacity: 0.6;
        transition: opacity 150ms ease;
    }
    .table-hint {
        margin: -0.25rem 0 0.75rem;
        max-width: 48rem;
    }
    .upcoming + :global(.pager) {
        margin-bottom: 2rem;
    }
    .cancel-icon {
        color: var(--adm-danger);
    }
    .table-title {
        font-size: 1.125rem;
        margin: 0 0 0.625rem;
    }
    .badge.s-completed {
        background-color: var(--adm-success-bg);
        border-color: var(--adm-success-border);
        color: var(--adm-success-text);
    }
    .badge.s-cancelled,
    .badge.s-no_show {
        background-color: var(--adm-danger-bg);
        border-color: transparent;
        color: var(--adm-danger);
    }
    .empty {
        padding: 0.875rem 0.75rem;
    }
    .gone {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        max-width: 36rem;
    }

    @media (max-width: 47.99rem) {
        .summary {
            grid-template-columns: minmax(0, 1fr);
        }
    }
</style>
