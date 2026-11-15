<script>
    import '../layout.css';
    import { onMount } from 'svelte';
    import { page } from '$app/state';
    import { getSupabase } from '$lib/supabase';
    import Logo from '$lib/components/shared/logo.svelte';

    let { children } = $props();

    const sb = getSupabase();
    let view = $state('loading');   // loading | signed-out | not-staff | ready
    let staff = $state(null);
    let email = $state('');
    let password = $state('');
    let signInError = $state('');
    let signingIn = $state(false);

    async function check() {
        const { data: { session } } = await sb.auth.getSession();
        if (!session) {
            view = 'signed-out';
            staff = null;
            return;
        }
        const { data } = await sb.from('s4_staff').select('display_name, role').eq('user_id', session.user.id).maybeSingle();
        staff = data;
        view = data ? 'ready' : 'not-staff';
    }

    onMount(() => {
        check();
        const { data: sub } = sb.auth.onAuthStateChange(() => setTimeout(check, 0));
        return () => sub.subscription.unsubscribe();
    });

    async function signIn(e) {
        e.preventDefault();
        signingIn = true;
        signInError = '';
        const { error } = await sb.auth.signInWithPassword({ email: email.trim(), password });
        signingIn = false;
        if (error) signInError = 'That email and password combination didn\'t work.';
    }

    const signOut = () => sb.auth.signOut();

    const nav = [
        { href: '/admin', label: 'Bookings' },
        { href: '/admin/time-off', label: 'Time off' },
        { href: '/admin/categories', label: 'Categories' },
        { href: '/admin/services', label: 'Services' },
        { href: '/admin/settings', label: 'Settings' }
    ];
</script>

<svelte:head>
    <title>Admin · Studio 4 Hair Salon</title>
    <meta name="robots" content="noindex" />
</svelte:head>

<div class="admin">
    <header class="bar">
        <a href="/admin" class="brand" aria-label="Studio 4 admin"><Logo /></a>
        {#if view === 'ready'}
            <nav aria-label="Admin">
                {#each nav as n}
                    <a href={n.href} aria-current={page.url.pathname === n.href ? 'page' : undefined}>{n.label}</a>
                {/each}
            </nav>
            <button type="button" class="signout" onclick={signOut}>Sign out</button>
        {/if}
    </header>

    <main class="content">
        {#if view === 'loading'}
            <p class="muted" role="status">Checking your sign-in…</p>
        {:else if view === 'signed-out'}
            <form class="signin panel" onsubmit={signIn}>
                <h1>Sign in</h1>
                <p class="muted">For John and salon staff only.</p>
                <label for="admin-email">Email</label>
                <input id="admin-email" type="email" autocomplete="username" required bind:value={email} />
                <label for="admin-password">Password</label>
                <input id="admin-password" type="password" autocomplete="current-password" required bind:value={password} />
                {#if signInError}<p class="error" role="alert">{signInError}</p>{/if}
                <button type="submit" class="primary" disabled={signingIn}>{signingIn ? 'Signing in…' : 'Sign in'}</button>
            </form>
        {:else if view === 'not-staff'}
            <div class="panel">
                <h1>Not authorised</h1>
                <p>This account isn't set up as salon staff.</p>
                <button type="button" class="secondary" onclick={signOut}>Sign out</button>
            </div>
        {:else}
            {@render children()}
        {/if}
    </main>
</div>

<style>
    .admin {
        background-color: var(--lighter);
        color: var(--charcoal);
        min-height: 100vh;
    }
    .bar {
        align-items: center;
        background-color: var(--darkest);
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem 1.5rem;
        padding: 0.5rem max(1rem, calc((100% - 64rem) / 2));
    }
    .brand :global(.logo) {
        font-size: 2.25rem;
    }
    nav {
        display: flex;
        flex-wrap: wrap;
        gap: 0.25rem;
    }
    nav a,
    .signout {
        border-radius: 0.25rem;
        color: var(--color-off-white);
        font-weight: 500;
        min-height: 2.75rem;
        display: inline-flex;
        align-items: center;
        padding: 0 0.75rem;
    }
    nav a:hover,
    .signout:hover {
        background-color: var(--dark);
    }
    nav a[aria-current="page"] {
        background-color: var(--color-accent-400);
        color: var(--darkest);
    }
    .signout {
        cursor: pointer;
        margin-left: auto;
    }
    .content {
        margin: 0 auto;
        max-width: 64rem;
        padding: 2rem 1rem 4rem;
    }
    .signin {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        margin: 2rem auto 0;
        max-width: 24rem;
    }
    .signin label {
        font-weight: 600;
        margin-top: 0.5rem;
    }
    .signin .primary {
        margin-top: 1rem;
    }

    /* Shared admin styles for the pages rendered inside this layout. */
    .admin :global(h1) {
        color: var(--darkest);
        font: 700 1.75rem / 1.2 var(--font-serif);
    }
    .admin :global(h2) {
        color: var(--darkest);
        font: 600 1.125rem / 1.3 var(--font-default);
    }
    .admin :global(.panel) {
        background-color: var(--white);
        border: 1px solid var(--light);
        border-radius: 0.375rem;
        padding: 1.25rem;
    }
    .admin :global(.muted) {
        color: var(--dark);
    }
    .admin :global(.error) {
        color: var(--error);
        font-weight: 500;
    }
    .admin :global(.ok) {
        color: #1d6b38;
        font-weight: 500;
    }
    .admin :global(input:not([type="checkbox"])),
    .admin :global(select),
    .admin :global(textarea) {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        border-radius: 0.25rem;
        color: var(--darkest);
        font: inherit;
        min-height: 2.75rem;
        padding: 0.5rem 0.625rem;
    }
    .admin :global(input[type="checkbox"]) {
        height: 1.25rem;
        width: 1.25rem;
    }
    .admin :global(button.primary),
    .admin :global(button.secondary),
    .admin :global(button.danger) {
        border-radius: 0.25rem;
        cursor: pointer;
        font-weight: 600;
        min-height: 2.75rem;
        padding: 0 1.125rem;
        transition: background-color 150ms ease, border-color 150ms ease;
    }
    .admin :global(button.primary) {
        background-color: var(--color-accent-400);
        color: var(--darkest);
    }
    .admin :global(button.primary:hover) {
        background-color: var(--color-accent-500);
    }
    .admin :global(button.secondary) {
        background-color: var(--white);
        border: 1px solid var(--input-border);
        color: var(--darkest);
    }
    .admin :global(button.secondary:hover) {
        border-color: var(--dark);
    }
    .admin :global(button.danger) {
        background-color: var(--white);
        border: 1px solid var(--error);
        color: var(--error);
    }
    .admin :global(button.danger:hover) {
        background-color: var(--error-bg);
    }
    .admin :global(button:disabled) {
        cursor: progress;
        opacity: 0.6;
    }
</style>
