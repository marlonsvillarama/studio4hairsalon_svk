<script>
    /**
     * Merge two client records. Staff choose which record to keep; the other's
     * bookings move to it, blank details are filled from it, and it's deleted
     * (s4_merge_clients). The preview below mirrors the database's rules.
     */
    import { getSupabase, errorCode } from '$lib/supabase';
    import { adminError, showPhone, showShortDay } from '$lib/admin';
    import Modal from './modal.svelte';

    /** clients: the two s4_clients rows (with bookingCount). */
    let { open = $bindable(false), clients = [], onmerged } = $props();

    const sb = getSupabase();
    let keepId = $state(null);
    let saving = $state(false);
    let error = $state('');

    // Default: the Google-linked record, else the one with more bookings.
    $effect(() => {
        if (!open || clients.length !== 2) return;
        const [a, z] = clients;
        keepId = (a.auth_user_id && !z.auth_user_id) ? a.id
            : (z.auth_user_id && !a.auth_user_id) ? z.id
            : (z.bookingCount > a.bookingCount ? z.id : a.id);
        error = '';
    });

    let keep = $derived(clients.find(c => c.id === keepId));
    let drop = $derived(clients.find(c => c.id !== keepId));
    const nameOf = (c) => `${c?.first_name ?? ''} ${c?.last_name ?? ''}`.trim() || 'Unnamed client';
    const blank = (v) => !(v ?? '').trim();
    let bothLinked = $derived(clients.length === 2 && clients.every(c => c.auth_user_id));

    let result = $derived.by(() => {
        if (!keep || !drop) return null;
        const verifiedFromDrop = drop.email_verified && !keep.email_verified;
        const r = {
            first_name: blank(keep.first_name) ? drop.first_name : keep.first_name,
            last_name: blank(keep.last_name) ? drop.last_name : keep.last_name,
            phone_e164: keep.phone_e164 ?? drop.phone_e164,
            email: verifiedFromDrop ? drop.email : (keep.email ?? drop.email),
            google: !!(keep.auth_user_id || drop.auth_user_id),
            gold: keep.has_gold_card || drop.has_gold_card,
            bookings: keep.bookingCount + drop.bookingCount
        };
        // Values from the other record that won't survive.
        const lost = [];
        if (drop.phone_e164 && r.phone_e164 !== drop.phone_e164) lost.push(`Phone ${showPhone(drop.phone_e164)}`);
        if (drop.email && r.email?.toLowerCase() !== drop.email.toLowerCase()) lost.push(`Email ${drop.email}`);
        if (keep.email && r.email?.toLowerCase() !== keep.email.toLowerCase()) lost.push(`Email ${keep.email}`);
        if (!blank(drop.first_name) && !blank(keep.first_name) && drop.first_name.trim() !== keep.first_name.trim()) lost.push(`First name “${drop.first_name}”`);
        if (!blank(drop.last_name) && !blank(keep.last_name) && drop.last_name.trim() !== keep.last_name.trim()) lost.push(`Last name “${drop.last_name}”`);
        return { ...r, lost };
    });

    const MESSAGES = {
        both_linked: 'Both clients sign in with Google, so they can’t be merged.',
        same_client: 'Choose two different clients.',
        client_not_found: 'One of these clients no longer exists. Close this and try again.',
        not_staff: "You don't have permission to do that."
    };

    async function merge() {
        saving = true;
        error = '';
        const kept = keep;
        const { data, error: err } = await sb.rpc('s4_merge_clients', { p_keep: keep.id, p_drop: drop.id });
        saving = false;
        if (err) { error = MESSAGES[errorCode(err)] || adminError(err); return; }
        open = false;
        onmerged?.({ kept: { ...kept, ...result }, moved: data?.bookings_moved ?? 0 });
    }
</script>

<Modal bind:open title="Merge clients" wide>
    {#if clients.length === 2}
        <fieldset class="choices">
            <legend>Which record do you want to keep?</legend>
            <div class="cards">
                {#each clients as c (c.id)}
                    <label class="card" class:chosen={keepId === c.id}>
                        <span class="radio">
                            <input type="radio" name="keep" value={c.id} bind:group={keepId} />
                            <span>Keep this record</span>
                        </span>
                        <strong class="name">{nameOf(c)}</strong>
                        <span>{c.phone_e164 ? showPhone(c.phone_e164) : 'No phone'}</span>
                        <span class="email">{c.email || 'No email'}</span>
                        <span class="tags">
                            {#if c.auth_user_id}<span class="badge"><i class="ph ph-google-logo" aria-hidden="true"></i> Google</span>{/if}
                            {#if c.has_gold_card}<span class="badge warn">Gold Card</span>{/if}
                        </span>
                        <span class="muted">{c.bookingCount} {c.bookingCount === 1 ? 'booking' : 'bookings'} · added {showShortDay(c.created_at)}</span>
                    </label>
                {/each}
            </div>
        </fieldset>

        {#if bothLinked}
            <p class="error" role="alert">{MESSAGES.both_linked}</p>
        {:else if result}
            <section class="result" aria-labelledby="merge-result">
                <h3 id="merge-result">After merging</h3>
                <p class="strong">{`${result.first_name ?? ''} ${result.last_name ?? ''}`.trim()}</p>
                <p>{result.phone_e164 ? showPhone(result.phone_e164) : 'No phone'} · {result.email || 'No email'}</p>
                <p class="muted">{result.bookings} {result.bookings === 1 ? 'booking' : 'bookings'}{result.gold ? ' · Gold Card' : ''}{result.google ? ' · signs in with Google' : ''}</p>
                {#if result.lost.length}
                    <ul class="lost">
                        {#each result.lost as l}<li>{l} won’t be kept.</li>{/each}
                    </ul>
                {/if}
            </section>
            <p class="warning"><i class="ph ph-warning" aria-hidden="true"></i>
                <span>{nameOf(drop)}’s record is deleted and their bookings move to this client. This can’t be undone.</span></p>
        {/if}
        {#if error}<p class="error" role="alert">{error}</p>{/if}
    {/if}
    {#snippet footer()}
        <button type="button" class="secondary" onclick={() => open = false}>Cancel</button>
        <button type="button" class="primary" disabled={saving || bothLinked || !result} onclick={merge}>{saving ? 'Merging…' : 'Merge clients'}</button>
    {/snippet}
</Modal>

<style>
    .choices {
        border: 0;
        margin: 0 0 1rem;
        padding: 0;
    }
    legend {
        color: var(--adm-text);
        font-weight: 600;
        margin-bottom: 0.625rem;
        padding: 0;
    }
    .cards {
        display: grid;
        gap: 0.75rem;
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
    .card {
        border: 1px solid var(--adm-border-strong);
        border-radius: 0.5rem;
        cursor: pointer;
        display: flex;
        flex-direction: column;
        gap: 0.125rem;
        min-width: 0;
        padding: 0.75rem 1rem 0.875rem;
    }
    .card.chosen {
        background-color: var(--adm-selected-bg);
        border-color: var(--adm-selected-border);
        box-shadow: 0 0 0 1px var(--adm-selected-border);
    }
    .radio {
        align-items: center;
        color: var(--adm-text);
        display: flex;
        font-size: 0.875rem;
        font-weight: 600;
        gap: 0.5rem;
        margin-bottom: 0.375rem;
        min-height: 2rem;
    }
    .radio input {
        height: 1.125rem;
        width: 1.125rem;
    }
    .name {
        color: var(--adm-text);
        font-size: 1.0625rem;
    }
    .email {
        overflow-wrap: anywhere;
    }
    .tags {
        display: flex;
        flex-wrap: wrap;
        gap: 0.25rem;
        min-height: 0.25rem;
    }
    .result {
        background-color: var(--adm-sunken);
        border: 1px solid var(--adm-border);
        border-radius: 0.5rem;
        display: flex;
        flex-direction: column;
        gap: 0.125rem;
        margin-bottom: 0.875rem;
        padding: 0.75rem 1rem;
    }
    .result h3 {
        color: var(--adm-text-muted);
        font: 600 0.75rem / 1.2 var(--font-default);
        letter-spacing: 0.06em;
        margin-bottom: 0.25rem;
        text-transform: uppercase;
    }
    .strong {
        color: var(--adm-text);
        font-weight: 600;
    }
    .lost {
        color: var(--adm-text);
        font-size: 0.875rem;
        margin: 0.375rem 0 0;
        padding-left: 1.125rem;
    }
    .warning {
        align-items: flex-start;
        color: var(--adm-text);
        display: flex;
        gap: 0.5rem;
    }
    .warning i {
        color: var(--adm-danger);
        font-size: 1.125rem;
        margin-top: 0.125rem;
    }
    @media (max-width: 40rem) {
        .cards {
            grid-template-columns: minmax(0, 1fr);
        }
    }
</style>
