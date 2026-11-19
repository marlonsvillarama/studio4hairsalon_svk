<script>
    import '../layout.css';
    import { onMount } from 'svelte';
    import { page } from '$app/state';
    import { afterNavigate } from '$app/navigation';
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

    // ─── Theme (saved per staff account; cached on this device so the right
    //     theme shows immediately on load) ───────────────────────────────
    const THEMES = [
        { id: 'studio4', label: 'Studio4' },
        { id: 'clean', label: 'Clean' }
    ];
    const THEME_KEY = 's4.admin.theme';
    const isTheme = (t) => THEMES.some(x => x.id === t);
    const cachedTheme = () => { try { const t = localStorage.getItem(THEME_KEY); return isTheme(t) ? t : null; } catch { return null; } };
    let theme = $state(cachedTheme() ?? 'studio4');
    let themeNote = $state('');

    function applyTheme(t) {
        theme = t;
        try { localStorage.setItem(THEME_KEY, t); } catch { /* private mode: this session only */ }
    }

    async function chooseTheme(t) {
        if (t === theme) return;
        applyTheme(t);
        themeNote = '';
        const { data: { session } } = await sb.auth.getSession();
        if (!session) return;
        const { error } = await sb.from('s4_staff').update({ theme: t }).eq('user_id', session.user.id);
        if (error) themeNote = "Couldn't save your theme. It will reset next time.";
    }

    // Arrow keys move between the theme options (radio group behaviour).
    function themeKeys(e) {
        const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
        if (!step) return;
        e.preventDefault();
        const i = THEMES.findIndex(x => x.id === theme);
        const next = THEMES[(i + step + THEMES.length) % THEMES.length].id;
        chooseTheme(next);
        e.currentTarget.querySelector(`[data-theme-option="${next}"]`)?.focus();
    }

    async function check() {
        const { data: { session } } = await sb.auth.getSession();
        if (!session) {
            view = 'signed-out';
            staff = null;
            return;
        }
        const { data } = await sb.from('s4_staff').select('display_name, role, theme').eq('user_id', session.user.id).maybeSingle();
        staff = data;
        if (isTheme(data?.theme) && data.theme !== theme) applyTheme(data.theme);
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
        { href: '/admin', label: 'Bookings', icon: 'calendar-dots' },
        { href: '/admin/time-off', label: 'Time off', icon: 'calendar-x' },
        { href: '/admin/categories', label: 'Categories', icon: 'squares-four' },
        { href: '/admin/services', label: 'Services', icon: 'scissors' },
        { href: '/admin/invoices', label: 'Tax invoices', icon: 'receipt' },
        { href: '/admin/settings', label: 'Settings', icon: 'gear-six' }
    ];
    // A section stays current on its sub-pages (e.g. one invoice).
    const isCurrent = (href, path) => href === '/admin' ? path === href : path === href || path.startsWith(`${href}/`);
    let currentLabel = $derived(nav.find(n => isCurrent(n.href, page.url.pathname))?.label ?? 'Admin');

    // On narrow screens the sidebar is a popover drawer; close it after navigating.
    let menu = $state();
    const closeMenu = () => {
        if (menu?.matches(':popover-open')) menu.hidePopover();
    };
    afterNavigate(closeMenu);
</script>

<svelte:head>
    <title>Admin · Studio 4 Hair Salon</title>
    <meta name="robots" content="noindex" />
</svelte:head>

<div class="admin" class:with-sidebar={view === 'ready'} data-theme={theme}>
    {#if view === 'ready'}
        <!-- Narrow screens: slim bar with a menu button. -->
        <header class="topbar">
            <a href="/admin" class="brand" aria-label="Studio 4 admin"><Logo /></a>
            <span class="current">{currentLabel}</span>
            <button type="button" class="menu-btn" aria-label="Open menu" popovertarget="admin-menu">
                <i class="ph ph-list" aria-hidden="true"></i>
            </button>
        </header>

        <!-- Wide screens: always-visible sidebar. Narrow screens: the same element as a drawer. -->
        <aside class="sidebar" id="admin-menu" popover bind:this={menu} aria-label="Admin menu">
            <div class="sidebar-head">
                <a href="/admin" class="brand" aria-label="Studio 4 admin" onclick={closeMenu}><Logo /></a>
                <button type="button" class="close-btn" aria-label="Close menu"
                    popovertarget="admin-menu" popovertargetaction="hide">
                    <i class="ph ph-x" aria-hidden="true"></i>
                </button>
            </div>
            <nav aria-label="Admin">
                {#each nav as n}
                    <a href={n.href} aria-current={isCurrent(n.href, page.url.pathname) ? 'page' : undefined} onclick={closeMenu}>
                        <i class="ph ph-{n.icon}" aria-hidden="true"></i>
                        <span>{n.label}</span>
                    </a>
                {/each}
            </nav>
            <div class="sidebar-foot">
                <div class="theme">
                    <span class="theme-label" id="theme-label">
                        <i class="ph ph-palette" aria-hidden="true"></i> Theme
                    </span>
                    <div class="theme-options" role="radiogroup" aria-labelledby="theme-label" tabindex="-1" onkeydown={themeKeys}>
                        {#each THEMES as t (t.id)}
                            <button type="button" role="radio" data-theme-option={t.id}
                                aria-checked={theme === t.id} tabindex={theme === t.id ? 0 : -1}
                                onclick={() => chooseTheme(t.id)}>{t.label}</button>
                        {/each}
                    </div>
                    {#if themeNote}<p class="theme-note" role="alert">{themeNote}</p>{/if}
                </div>
                <a href="/" target="_blank" rel="noopener" class="foot-link">
                    <i class="ph ph-arrow-square-out" aria-hidden="true"></i>
                    <span>View website</span>
                </a>
                <div class="who">
                    <i class="ph ph-user-circle" aria-hidden="true"></i>
                    <span>{staff?.display_name ?? 'Staff'}</span>
                </div>
                <button type="button" class="foot-link signout" onclick={signOut}>
                    <i class="ph ph-sign-out" aria-hidden="true"></i>
                    <span>Sign out</span>
                </button>
            </div>
        </aside>
    {:else}
        <header class="bar">
            <a href="/admin" class="brand" aria-label="Studio 4 admin"><Logo /></a>
        </header>
    {/if}

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
            <div class="panel narrow">
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
    /* ── Themes ───────────────────────────────────────────────────────────
       Every admin colour, font and shadow comes from these tokens.
       "studio4" reproduces the salon look; "clean" is a light, neutral UI
       (white canvas, navy text, blue actions). */
    .admin,
    .admin[data-theme="studio4"] {
        --adm-canvas: var(--lighter);
        --adm-surface: var(--white);
        --adm-sunken: var(--lighter);
        --adm-border: var(--light);
        --adm-border-strong: var(--input-border);
        --adm-text: var(--darkest);
        --adm-text-body: var(--charcoal);
        --adm-text-muted: var(--dark);
        --adm-text-subtle: var(--semi-dark);

        --adm-sidebar-bg: var(--darkest);
        --adm-sidebar-text: var(--color-off-white);
        --adm-sidebar-subtle: var(--semi-dark);
        --adm-sidebar-hover: var(--dark);
        --adm-sidebar-border: var(--dark);
        --adm-sidebar-edge: transparent;
        --adm-nav-active-bg: var(--color-accent-400);
        --adm-nav-active-text: var(--darkest);
        --adm-brand: var(--color-accent-500);

        --adm-primary-bg: var(--color-accent-400);
        --adm-primary-hover: var(--color-accent-500);
        --adm-primary-text: var(--darkest);
        --adm-inverse-bg: var(--darkest);
        --adm-inverse-text: var(--white);
        --adm-selected-bg: var(--color-accent-50);
        --adm-selected-border: var(--color-accent-700);
        --adm-accent-soft: var(--color-accent-100);
        --adm-accent-soft-hover: var(--color-accent-200);
        --adm-accent-border: var(--color-accent-300);
        --adm-accent-line: var(--color-accent-600);
        --adm-accent-text: var(--color-accent-800);
        --adm-focus: var(--color-accent-700);

        --adm-success-bg: #e3f4e8;
        --adm-success-border: #2f8a4c;
        --adm-success-text: #1d6b38;
        --adm-success-strong: #14482a;
        --adm-danger: var(--error);
        --adm-danger-bg: var(--error-bg);
        --adm-now: var(--error);
        --adm-hatch-a: var(--light);
        --adm-hatch-b: var(--lighter);
        --adm-backdrop: rgba(27, 27, 27, 0.55);

        --adm-heading-font: var(--font-serif);
        --adm-heading-weight: 700;
        --adm-heading-tracking: normal;
        --adm-radius-lg: 0.5rem;
        --adm-shadow-raised: 0 1px 2px rgba(27, 27, 27, 0.12);
        --adm-shadow-hover: 0 4px 12px -4px rgba(27, 27, 27, 0.35);
        --adm-shadow-overlay: 0 24px 48px -16px rgba(27, 27, 27, 0.45);
    }
    .admin[data-theme="clean"] {
        --adm-canvas: #f7f8f9;
        --adm-surface: #ffffff;
        --adm-sunken: #f7f8f9;
        --adm-border: #dcdfe4;
        --adm-border-strong: #8590a2;
        --adm-text: #172b4d;
        --adm-text-body: #172b4d;
        --adm-text-muted: #44546f;
        --adm-text-subtle: #626f86;

        --adm-sidebar-bg: #ffffff;
        --adm-sidebar-text: #44546f;
        --adm-sidebar-subtle: #626f86;
        --adm-sidebar-hover: #091e420f;
        --adm-sidebar-border: #dcdfe4;
        --adm-sidebar-edge: #dcdfe4;
        --adm-nav-active-bg: #e9f2ff;
        --adm-nav-active-text: #0c66e4;
        --adm-brand: #172b4d;

        --adm-primary-bg: #0c66e4;
        --adm-primary-hover: #0055cc;
        --adm-primary-text: #ffffff;
        --adm-inverse-bg: #0c66e4;
        --adm-inverse-text: #ffffff;
        --adm-selected-bg: #e9f2ff;
        --adm-selected-border: #0c66e4;
        --adm-accent-soft: #e9f2ff;
        --adm-accent-soft-hover: #cce0ff;
        --adm-accent-border: #85b8ff;
        --adm-accent-line: #0c66e4;
        --adm-accent-text: #0055cc;
        --adm-focus: #388bff;

        --adm-success-bg: #dcfff1;
        --adm-success-border: #1f845a;
        --adm-success-text: #216e4e;
        --adm-success-strong: #164b35;
        --adm-danger: #c9372c;
        --adm-danger-bg: #ffeceb;
        --adm-now: #c9372c;
        --adm-hatch-a: #f1f2f4;
        --adm-hatch-b: #ffffff;
        --adm-backdrop: rgba(9, 30, 66, 0.54);

        --adm-heading-font: var(--font-default);
        --adm-heading-weight: 600;
        --adm-heading-tracking: -0.01em;
        --adm-radius-lg: 0.25rem;
        --adm-shadow-raised: 0 1px 1px rgba(9, 30, 66, 0.25), 0 0 1px rgba(9, 30, 66, 0.31);
        --adm-shadow-hover: 0 4px 8px -2px rgba(9, 30, 66, 0.25), 0 0 1px rgba(9, 30, 66, 0.31);
        --adm-shadow-overlay: 0 8px 12px rgba(9, 30, 66, 0.15), 0 0 1px rgba(9, 30, 66, 0.31);
    }

    .admin {
        accent-color: var(--adm-selected-border);
        background-color: var(--adm-canvas);
        color: var(--adm-text-body);
        min-height: 100vh;
    }
    /* The salon wordmark takes the theme's brand colour (yellow on the dark
       sidebar, navy on a white one, so it stays legible). */
    .admin :global(.logo) {
        color: var(--adm-brand);
    }
    .admin :global(:focus-visible) {
        outline-color: var(--adm-focus);
    }
    /* Signed-out / not-authorised: simple dark bar, centred content. */
    .bar {
        align-items: center;
        background-color: var(--adm-sidebar-bg);
        display: flex;
        padding: 0.5rem clamp(1rem, 3vw, 2.5rem);
    }
    .brand {
        display: inline-flex;
    }
    .brand :global(.logo) {
        font-size: 2.25rem;
    }
    .content {
        min-width: 0;
        padding: 1.5rem clamp(1rem, 3vw, 2.5rem) 4rem;
    }
    .narrow {
        margin: 2rem auto 0;
        max-width: 28rem;
    }
    /* Printing (tax invoices): only the page content, on plain paper. */
    @media print {
        .admin {
            background: none;
            min-height: 0;
        }
        .admin.with-sidebar {
            display: block !important;
        }
        .topbar,
        .sidebar,
        .bar,
        .admin :global(.no-print) {
            display: none !important;
        }
        .content {
            padding: 0 !important;
        }
    }

    /* Narrow screens: top bar + drawer. */
    .topbar {
        align-items: center;
        background-color: var(--adm-sidebar-bg);
        box-shadow: inset 0 -1px 0 var(--adm-sidebar-edge);
        color: var(--adm-sidebar-text);
        display: flex;
        gap: 1rem;
        padding: 0.375rem 0.75rem 0.375rem 1rem;
        position: sticky;
        top: 0;
        z-index: 20;
    }
    .topbar .current {
        flex: 1;
        font-weight: 600;
    }
    .menu-btn,
    .close-btn {
        border-radius: 50%;
        color: var(--adm-sidebar-text);
        cursor: pointer;
        display: grid;
        font-size: 1.5rem;
        height: 2.75rem;
        place-items: center;
        width: 2.75rem;
    }
    .menu-btn:hover,
    .close-btn:hover {
        background-color: var(--adm-sidebar-hover);
    }

    .sidebar {
        background-color: var(--adm-sidebar-bg);
        box-shadow: inset -1px 0 0 var(--adm-sidebar-edge);
        border: 0;
        color: var(--adm-sidebar-text);
        flex-direction: column;
        gap: 1.5rem;
        height: 100dvh;
        inset: 0 auto 0 0;
        margin: 0;
        max-width: 85vw;
        padding: 0.75rem;
        width: 16rem;
        transform: translateX(-100%);
        transition:
            transform 300ms cubic-bezier(0.16, 1, 0.3, 1),
            display 300ms allow-discrete,
            overlay 300ms allow-discrete;
    }
    .sidebar:popover-open {
        display: flex;
        transform: none;
    }
    @starting-style {
        .sidebar:popover-open {
            transform: translateX(-100%);
        }
    }
    .sidebar::backdrop {
        background-color: var(--adm-backdrop);
    }
    .sidebar-head {
        align-items: center;
        display: flex;
        justify-content: space-between;
        padding: 0.25rem 0.25rem 0 0.5rem;
    }
    nav {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }
    nav a,
    .foot-link {
        align-items: center;
        border-radius: 0.375rem;
        color: var(--adm-sidebar-text);
        display: flex;
        font-weight: 500;
        gap: 0.75rem;
        min-height: 2.75rem;
        padding: 0 0.75rem;
        text-align: left;
        width: 100%;
        transition: background-color 150ms ease, color 150ms ease;
    }
    nav a > i,
    .foot-link > i,
    .who > i {
        font-size: 1.375rem;
        flex: none;
    }
    nav a:hover,
    .foot-link:hover {
        background-color: var(--adm-sidebar-hover);
    }
    nav a[aria-current="page"] {
        background-color: var(--adm-nav-active-bg);
        color: var(--adm-nav-active-text);
        font-weight: 600;
    }
    .sidebar-foot {
        border-top: 1px solid var(--adm-sidebar-border);
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        margin-top: auto;
        padding-top: 0.75rem;
    }
    .signout {
        cursor: pointer;
    }
    .theme {
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
        padding: 0 0.75rem 0.5rem;
    }
    .theme-label {
        align-items: center;
        color: var(--adm-sidebar-subtle);
        display: flex;
        font-size: 0.8125rem;
        font-weight: 600;
        gap: 0.5rem;
    }
    .theme-label > i {
        font-size: 1.125rem;
    }
    .theme-options {
        background-color: var(--adm-sidebar-hover);
        border-radius: 0.375rem;
        display: grid;
        gap: 0.125rem;
        grid-template-columns: 1fr 1fr;
        padding: 0.1875rem;
    }
    .theme-options > button {
        border-radius: 0.25rem;
        color: var(--adm-sidebar-text);
        cursor: pointer;
        font-size: 0.875rem;
        font-weight: 600;
        min-height: 2.25rem;
        transition: background-color 150ms ease, color 150ms ease;
    }
    .theme-options > button[aria-checked="true"] {
        background-color: var(--adm-nav-active-bg);
        color: var(--adm-nav-active-text);
    }
    .theme-note {
        color: var(--adm-sidebar-subtle);
        font-size: 0.75rem;
    }
    .who {
        align-items: center;
        color: var(--adm-sidebar-subtle);
        display: flex;
        font-size: 0.875rem;
        gap: 0.75rem;
        min-height: 2.5rem;
        padding: 0 0.75rem;
    }

    /* Wide screens: fixed sidebar beside full-width content. */
    @media (min-width: 56rem) {
        .admin.with-sidebar {
            display: grid;
            grid-template-columns: 15rem minmax(0, 1fr);
        }
        .topbar,
        .close-btn {
            display: none;
        }
        .sidebar {
            display: flex;
            height: 100vh;
            inset: auto;
            max-width: none;
            overflow-y: auto;
            position: sticky;
            top: 0;
            transform: none;
            transition: none;
            width: auto;
        }
    }
    @media (prefers-reduced-motion: reduce) {
        .sidebar {
            transition: none;
        }
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
        color: var(--adm-text);
        font: var(--adm-heading-weight) 1.75rem / 1.2 var(--adm-heading-font);
        letter-spacing: var(--adm-heading-tracking);
    }
    .admin :global(h2) {
        color: var(--adm-text);
        font: 600 1.125rem / 1.3 var(--font-default);
    }
    .admin :global(.panel) {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border);
        border-radius: 0.375rem;
        padding: 1.25rem;
    }
    .admin :global(.muted) {
        color: var(--adm-text-muted);
    }
    .admin :global(.error) {
        color: var(--adm-danger);
        font-weight: 500;
    }
    .admin :global(.ok) {
        color: var(--adm-success-text);
        font-weight: 500;
    }
    .admin :global(input:not([type="checkbox"])),
    .admin :global(select),
    .admin :global(textarea) {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border-strong);
        border-radius: 0.25rem;
        color: var(--adm-text);
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
        background-color: var(--adm-primary-bg);
        color: var(--adm-primary-text);
    }
    .admin :global(button.primary:hover) {
        background-color: var(--adm-primary-hover);
    }
    .admin :global(button.secondary) {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border-strong);
        color: var(--adm-text);
    }
    .admin :global(button.secondary:hover) {
        border-color: var(--adm-text-muted);
    }
    .admin :global(button.danger) {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-danger);
        color: var(--adm-danger);
    }
    .admin :global(button.danger:hover) {
        background-color: var(--adm-danger-bg);
    }
    .admin :global(button:disabled) {
        cursor: progress;
        opacity: 0.6;
    }

    /* ── Shared list-page pieces (Categories, Services) ─────────────────── */
    .admin :global(.page-head) {
        align-items: flex-end;
        display: flex;
        flex-wrap: wrap;
        gap: 1rem;
        justify-content: space-between;
        margin-bottom: 1.25rem;
    }
    .admin :global(.page-head p) {
        color: var(--adm-text-muted);
        margin-top: 0.375rem;
        max-width: 48rem;
    }
    .admin :global(button.primary.with-icon),
    .admin :global(button.secondary.with-icon) {
        align-items: center;
        display: inline-flex;
        gap: 0.5rem;
    }
    .admin :global(.icon-btn) {
        align-items: center;
        border-radius: 0.375rem;
        color: var(--adm-text-muted);
        cursor: pointer;
        display: inline-grid;
        font-size: 1.25rem;
        height: 2.75rem;
        justify-content: center;
        width: 2.75rem;
        transition: background-color 150ms ease, color 150ms ease;
    }
    .admin :global(.icon-btn:hover:not(:disabled)) {
        background-color: var(--adm-sunken);
        color: var(--adm-text);
    }
    .admin :global(.icon-btn.danger-icon:hover:not(:disabled)) {
        background-color: var(--adm-danger-bg);
        color: var(--adm-danger);
    }
    .admin :global(.icon-btn:disabled) {
        cursor: default;
        opacity: 0.3;
    }
    .admin :global(.badge) {
        align-items: center;
        background-color: var(--adm-sunken);
        border: 1px solid var(--adm-border);
        border-radius: 999px;
        color: var(--adm-text-muted);
        display: inline-flex;
        font-size: 0.75rem;
        font-weight: 600;
        gap: 0.25rem;
        padding: 0.0625rem 0.5rem;
        white-space: nowrap;
    }
    .admin :global(.badge.warn) {
        background-color: var(--adm-selected-bg);
        border-color: var(--adm-accent-border);
        color: var(--adm-accent-text);
    }
    .admin :global(.status-line) {
        align-items: center;
        border-radius: 0.375rem;
        display: flex;
        gap: 0.5rem;
        margin-bottom: 1rem;
        padding: 0.625rem 0.875rem;
    }
    .admin :global(.status-line.ok) {
        background-color: var(--adm-success-bg);
        color: var(--adm-success-strong);
    }
    .admin :global(.status-line.error) {
        background-color: var(--adm-danger-bg);
        color: var(--adm-danger);
    }

    /* Tables: a real table on wide screens, labelled cards on narrow ones. */
    .admin :global(.admin-table) {
        background-color: var(--adm-surface);
        border: 1px solid var(--adm-border);
        border-collapse: separate;
        border-radius: 0.375rem;
        border-spacing: 0;
        width: 100%;
    }
    .admin :global(.admin-table th),
    .admin :global(.admin-table td) {
        border-bottom: 1px solid var(--adm-border);
        padding: 0.375rem 0.75rem;
        text-align: left;
        vertical-align: middle;
    }
    .admin :global(.admin-table thead th) {
        background-color: var(--adm-surface);
        color: var(--adm-text-muted);
        font-size: 0.75rem;
        font-weight: 600;
        letter-spacing: 0.04em;
        padding-block: 0.75rem;
        position: sticky;
        text-transform: uppercase;
        top: 0;
        z-index: 1;
    }
    .admin :global(.admin-table tbody tr:last-child > *) {
        border-bottom: 0;
    }
    .admin :global(.admin-table tbody tr:not(.group-row):hover > td) {
        background-color: var(--adm-selected-bg);
    }
    .admin :global(.admin-table .num) {
        font-variant-numeric: tabular-nums;
        text-align: right;
        white-space: nowrap;
    }
    .admin :global(.admin-table .actions-cell) {
        text-align: right;
        white-space: nowrap;
        width: 1%;
    }
    .admin :global(.admin-table tr.off .primary-cell strong) {
        color: var(--adm-text-muted);
    }
    .admin :global(.admin-table .group-row th) {
        background-color: var(--adm-sunken);
        border-bottom: 1px solid var(--adm-border);
        color: var(--adm-text);
        font-size: 0.9375rem;
        padding-block: 0.5rem;
    }
    .admin :global(.admin-table .sub) {
        color: var(--adm-text-muted);
        display: block;
        font-size: 0.875rem;
        font-weight: 400;
        margin-top: 0.125rem;
    }
    @media (max-width: 55.99rem) {
        .admin :global(.admin-table),
        .admin :global(.admin-table tbody),
        .admin :global(.admin-table tr),
        .admin :global(.admin-table td),
        .admin :global(.admin-table th) {
            display: block;
        }
        .admin :global(.admin-table thead) {
            display: none;
        }
        .admin :global(.admin-table) {
            background: transparent;
            border: 0;
        }
        .admin :global(.admin-table tbody) {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
            margin-bottom: 0.75rem;
        }
        .admin :global(.admin-table tbody tr:not(.group-row)) {
            background-color: var(--adm-surface);
            border: 1px solid var(--adm-border);
            border-radius: 0.375rem;
            display: grid;
            gap: 0.125rem 1rem;
            grid-template-columns: 1fr auto;
            padding: 0.75rem 0.75rem 0.5rem 1rem;
        }
        .admin :global(.admin-table td) {
            border: 0;
            padding: 0;
        }
        .admin :global(.admin-table td[data-label]) {
            align-items: center;
            display: flex;
            gap: 0.5rem;
            grid-column: 1 / -1;
            justify-content: space-between;
            min-height: 1.75rem;
            text-align: right;
        }
        .admin :global(.admin-table td[data-label]::before) {
            color: var(--adm-text-muted);
            content: attr(data-label);
            font-size: 0.875rem;
        }
        .admin :global(.admin-table .primary-cell) {
            grid-column: 1;
            margin-bottom: 0.25rem;
        }
        .admin :global(.admin-table .lead-cell) {
            grid-column: 2;
            grid-row: 1;
        }
        .admin :global(.admin-table .actions-cell) {
            border-top: 1px solid var(--adm-border);
            display: flex;
            gap: 0.25rem;
            grid-column: 1 / -1;
            justify-content: flex-end;
            margin-top: 0.375rem;
            padding-top: 0.25rem;
            width: auto;
        }
        .admin :global(.admin-table .group-row th) {
            background: transparent;
            border: 0;
            padding: 0.75rem 0 0;
        }
    }
</style>
