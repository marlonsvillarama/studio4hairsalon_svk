<script>
    import { onMount } from 'svelte';
    import { getSupabase } from '$lib/supabase';
    import { salonInstant } from '$lib/data/availability';
    import { formatDuration } from '$lib/data/services';
    import { SALON_TZ, salonDay, salonTime, showShortDay, showTime, adminError, addDays } from '$lib/admin';
    import Modal from '$lib/components/admin/modal.svelte';
    import Switch from '$lib/components/admin/switch.svelte';
    import Skeleton from '$lib/components/admin/skeleton.svelte';

    const sb = getSupabase();
    let items = $state([]);
    let loading = $state(true);
    let loadError = $state('');
    let status = $state(null);      // { kind: 'ok' | 'error', text }
    let busyId = $state(null);

    // Past time off (loaded when the section is opened)
    let showPast = $state(false);
    let past = $state([]);
    let pastLoaded = $state(false);

    // Add/Edit modal
    let formOpen = $state(false);
    let form = $state(blankForm());
    let formError = $state('');
    let saving = $state(false);

    // Remove confirmation
    let confirmOpen = $state(false);
    let toRemove = $state(null);

    function blankForm() {
        const today = salonDay(Date.now());
        return { id: null, allDay: true, fromDate: today, toDate: today, fromTime: '12:00', toTime: '13:00', reason: '', kind: 'time_off' };
    }

    async function load() {
        loading = true;
        const { data, error: e } = await sb.from('s4_time_off')
            .select('id, starts_at, ends_at, reason, kind')
            .gte('ends_at', new Date().toISOString())
            .order('starts_at');
        loading = false;
        if (e) { loadError = adminError(e); return; }
        items = data;
    }
    onMount(load);

    async function loadPast() {
        const yearAgo = new Date(Date.now() - 365 * 86_400_000).toISOString();
        const { data, error: e } = await sb.from('s4_time_off')
            .select('id, starts_at, ends_at, reason, kind')
            .lt('ends_at', new Date().toISOString())
            .gte('ends_at', yearAgo)
            .order('starts_at', { ascending: false });
        if (e) { announce('error', adminError(e)); return; }
        past = data;
        pastLoaded = true;
    }
    function togglePast() {
        showPast = !showPast;
        if (showPast) loadPast();
    }

    function announce(kind, text) {
        status = { kind, text };
        if (kind === 'ok') setTimeout(() => { if (status?.text === text) status = null; }, 3000);
    }

    // ─── How a block reads ──────────────────────────────────────────────
    const lastMoment = (t) => new Date(new Date(t.ends_at).getTime() - 1);
    const isAllDay = (t) => salonTime(t.starts_at) === '00:00' && salonTime(t.ends_at) === '00:00';
    const isNow = (t) => new Date(t.starts_at) <= new Date() && new Date(t.ends_at) > new Date();
    function whenText(t) {
        const first = showShortDay(t.starts_at);
        const last = showShortDay(isAllDay(t) ? lastMoment(t) : t.ends_at);
        return first === last ? first : `${first} – ${last}`;
    }
    const timeText = (t) => isAllDay(t) ? 'All day' : `${showTime(t.starts_at)} – ${showTime(t.ends_at)}`;
    function lengthText(t) {
        if (isAllDay(t)) {
            const days = Math.round((new Date(t.ends_at) - new Date(t.starts_at)) / 86_400_000);
            return `${days} ${days === 1 ? 'day' : 'days'}`;
        }
        return formatDuration(Math.round((new Date(t.ends_at) - new Date(t.starts_at)) / 60_000));
    }
    const describe = (t) => `${whenText(t)}${isAllDay(t) ? '' : `, ${timeText(t)}`}`;

    // ─── Add / Edit ─────────────────────────────────────────────────────
    function openAdd() {
        form = blankForm();
        formError = '';
        formOpen = true;
    }
    function openEdit(t) {
        const allDay = isAllDay(t);
        form = {
            id: t.id,
            allDay,
            fromDate: salonDay(t.starts_at),
            toDate: allDay ? salonDay(lastMoment(t)) : salonDay(t.starts_at),
            fromTime: allDay ? '12:00' : salonTime(t.starts_at),
            toTime: allDay ? '13:00' : salonTime(t.ends_at),
            reason: t.reason ?? '',
            kind: t.kind ?? 'time_off'
        };
        formError = '';
        formOpen = true;
    }

    async function submitForm(e) {
        e.preventDefault();
        formError = '';
        const f = form;
        if (!f.fromDate || (f.allDay && !f.toDate)) { formError = 'Choose the dates.'; return; }
        // Whole days run from salon midnight to the midnight after the last day.
        const start = f.allDay ? salonInstant(f.fromDate, '00:00', SALON_TZ) : salonInstant(f.fromDate, f.fromTime, SALON_TZ);
        const end = f.allDay ? salonInstant(addDays(f.toDate || f.fromDate, 1), '00:00', SALON_TZ) : salonInstant(f.fromDate, f.toTime, SALON_TZ);
        if (end <= start) { formError = 'The end must be after the start.'; return; }
        if (f.kind === 'hold' && !f.reason.trim()) { formError = 'Say who the hold is for, e.g. "Family, maybe 3 people".'; return; }
        saving = true;
        const fields = { starts_at: start.toISOString(), ends_at: end.toISOString(), reason: f.reason.trim() || null, kind: f.kind };
        let err;
        if (f.id) {
            ({ error: err } = await sb.from('s4_time_off').update(fields).eq('id', f.id));
        } else {
            const { data: { user } } = await sb.auth.getUser();
            ({ error: err } = await sb.from('s4_time_off').insert({ ...fields, created_by: user?.id }));
        }
        saving = false;
        if (err) { formError = adminError(err); return; }
        formOpen = false;
        announce('ok', f.id ? 'Saved. The booking calendar uses the new times.' : f.kind === 'hold' ? 'Hold added. Those times are kept free until you book or release them.' : 'Added. Those times are no longer bookable online.');
        load();
        if (pastLoaded) loadPast();
    }

    // ─── Remove ─────────────────────────────────────────────────────────
    function askRemove(t) {
        toRemove = t;
        confirmOpen = true;
    }
    async function remove(t) {
        busyId = t.id;
        const { error: e } = await sb.from('s4_time_off').delete().eq('id', t.id);
        busyId = null;
        confirmOpen = false;
        if (e) { announce('error', adminError(e)); return; }
        announce('ok', `Removed time off on ${describe(t)}.`);
        load();
        if (pastLoaded) loadPast();
    }
</script>

<div class="page-head">
    <div>
        <h1>Time off</h1>
    </div>
    <button type="button" class="primary with-icon" onclick={openAdd}>
        <i class="ph ph-plus" aria-hidden="true"></i> Add time off
    </button>
</div>

{#if status}
    <p class="status-line {status.kind}" role={status.kind === 'error' ? 'alert' : 'status'}>
        <i class="ph ph-{status.kind === 'ok' ? 'check-circle' : 'warning-circle'}" aria-hidden="true"></i>{status.text}
    </p>
{/if}

{#snippet row(t, editable)}
    <tr>
        <td class="primary-cell">
            <a class="day-link" href="/admin?view=day&date={salonDay(t.starts_at)}"
                aria-label="{whenText(t)}: open in the booking calendar">{whenText(t)}</a>
            {#if isNow(t)}<span class="badge warn">Now</span>{/if}
        </td>
        <td data-label="Time">
            {#if isAllDay(t)}<span class="badge">All day</span>{:else}<span class="time">{timeText(t)}</span>{/if}
        </td>
        <td class="num" data-label="Length">{lengthText(t)}</td>
        <td data-label="Reason">{#if t.kind === 'hold'}<span class="badge hold">Hold</span> {/if}{#if t.reason}{t.reason}{:else}<span class="muted">—</span>{/if}</td>
        <td class="actions-cell">
            {#if editable}
                <button type="button" class="icon-btn" aria-label="Edit time off on {describe(t)}" title="Edit" onclick={() => openEdit(t)}>
                    <i class="ph ph-pencil-simple" aria-hidden="true"></i>
                </button>
            {/if}
            <button type="button" class="icon-btn danger-icon" aria-label="Remove time off on {describe(t)}" title="Remove"
                disabled={busyId === t.id} onclick={() => askRemove(t)}>
                <i class="ph ph-trash" aria-hidden="true"></i>
            </button>
        </td>
    </tr>
{/snippet}

{#if loading && !items.length}
    <Skeleton rows={4} columns={5} label="Loading time off…" />
{:else if loadError}
    <p class="error">{loadError}</p>
{:else}
    <table class="admin-table">
        <caption class="sr-only">Time off coming up</caption>
        <thead>
            <tr>
                <th scope="col">When</th>
                <th scope="col">Time</th>
                <th scope="col" class="num">Length</th>
                <th scope="col">Reason</th>
                <th scope="col" class="actions-cell"><span class="sr-only">Actions</span></th>
            </tr>
        </thead>
        <tbody>
            {#each items as t (t.id)}
                {@render row(t, true)}
            {:else}
                <tr><td colspan="5" class="muted empty">No time off coming up. Add a holiday or a break.</td></tr>
            {/each}
        </tbody>
    </table>
{/if}

<section class="past">
    <button type="button" class="toggle" aria-expanded={showPast} onclick={togglePast}>
        <i class="ph ph-caret-{showPast ? 'down' : 'right'}" aria-hidden="true"></i>
        Past time off (last 12 months)
    </button>
    {#if showPast}
        {#if !pastLoaded}
            <Skeleton rows={3} columns={5} label="Loading past time off…" />
        {:else if !past.length}
            <p class="muted">No time off in the last 12 months.</p>
        {:else}
            <table class="admin-table">
                <caption class="sr-only">Past time off</caption>
                <thead>
                    <tr>
                        <th scope="col">When</th>
                        <th scope="col">Time</th>
                        <th scope="col" class="num">Length</th>
                        <th scope="col">Reason</th>
                        <th scope="col" class="actions-cell"><span class="sr-only">Actions</span></th>
                    </tr>
                </thead>
                <tbody>
                    {#each past as t (t.id)}
                        {@render row(t, false)}
                    {/each}
                </tbody>
            </table>
        {/if}
    {/if}
</section>

<!-- Add / Edit -->
<Modal bind:open={formOpen} title={form.id ? (form.kind === 'hold' ? 'Edit hold' : 'Edit time off') : 'Add time off'}>
    <form id="timeoff-form" class="modal-form" onsubmit={submitForm} novalidate>
        <Switch bind:checked={form.allDay} label="Whole day(s)" showLabel />
        {#if form.allDay}
            <div class="pair">
                <label>From <input type="date" required bind:value={form.fromDate} /></label>
                <label>To <input type="date" required bind:value={form.toDate} min={form.fromDate} /></label>
            </div>
        {:else}
            <label>Date <input type="date" required bind:value={form.fromDate} /></label>
            <div class="pair">
                <label>From <input type="time" step="900" required bind:value={form.fromTime} /></label>
                <label>To <input type="time" step="900" required bind:value={form.toTime} /></label>
            </div>
        {/if}
        <label>
            <span>Reason <span class="optional">(only staff see this)</span></span>
            <input bind:value={form.reason} placeholder={form.kind === 'hold' ? 'e.g. Family, maybe 3 people' : 'e.g. Christmas, dentist'} autocomplete="off" />
        </label>
        {#if formError}<p class="error" role="alert">{formError}</p>{/if}
    </form>
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => formOpen = false}>Cancel</button>
        <button type="submit" form="timeoff-form" class="primary" disabled={saving}>
            {saving ? 'Saving…' : form.id ? 'Save changes' : form.kind === 'hold' ? 'Add hold' : 'Add time off'}
        </button>
    {/snippet}
</Modal>

<!-- Remove confirmation -->
<Modal bind:open={confirmOpen} title="Remove time off?">
    {#if toRemove}
        <p>
            Remove time off on <strong>{describe(toRemove)}</strong>{#if toRemove.reason}{' '}({toRemove.reason}){/if}?
            Those times become bookable online again.
        </p>
    {/if}
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => confirmOpen = false}>Keep it</button>
        <button type="button" class="danger" disabled={busyId === toRemove?.id} onclick={() => remove(toRemove)}>Remove time off</button>
    {/snippet}
</Modal>

<style>
    .badge.hold {
        border-style: dashed;
    }
    .day-link {
        color: var(--adm-text);
        font-weight: 600;
        margin-right: 0.375rem;
        text-decoration: underline;
        text-decoration-color: var(--adm-accent-line);
        text-underline-offset: 3px;
    }
    .time {
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }
    .empty {
        padding: 0.875rem 0.75rem;
    }
    .past {
        margin-top: 2rem;
    }
    .toggle {
        align-items: center;
        color: var(--adm-text);
        cursor: pointer;
        display: inline-flex;
        font-weight: 600;
        gap: 0.375rem;
        margin-bottom: 0.75rem;
        min-height: 2.75rem;
    }
    .modal-form {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    .modal-form label {
        color: var(--adm-text);
        display: flex;
        flex-direction: column;
        font-weight: 600;
        gap: 0.375rem;
    }
    .modal-form input {
        width: 100%;
    }
    .pair {
        display: grid;
        gap: 0.75rem;
        grid-template-columns: 1fr 1fr;
    }
    .optional {
        color: var(--adm-text-muted);
        font-weight: 400;
    }
</style>
