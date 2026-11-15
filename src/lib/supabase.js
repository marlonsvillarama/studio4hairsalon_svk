import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY } from '$env/static/public';

// The website only ever uses the publishable key (sb_publishable_…). It is
// safe in the browser: requests run as the `anon` role, or `authenticated`
// once someone signs in, and row-level security decides what they can touch.

let client;

export function getSupabase() {
    if (client) return client;

    if (!PUBLIC_SUPABASE_URL || !PUBLIC_SUPABASE_PUBLISHABLE_KEY) {
        throw new Error(
            'Supabase is not configured. Set PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_PUBLISHABLE_KEY in .env (see .env.example).'
        );
    }
    if (!PUBLIC_SUPABASE_PUBLISHABLE_KEY.startsWith('sb_publishable_')) {
        throw new Error(
            'PUBLIC_SUPABASE_PUBLISHABLE_KEY must be the publishable key (sb_publishable_…). ' +
            'Never put the secret key or a legacy anon/service_role key in a PUBLIC_ variable.'
        );
    }

    const inBrowser = typeof window !== 'undefined';
    client = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
        auth: {
            flowType: 'pkce',
            persistSession: inBrowser,
            autoRefreshToken: inBrowser,
            detectSessionInUrl: inBrowser
        }
    });
    return client;
}

/** Turn a Supabase/PostgREST error into the short code our SQL functions raise. */
export const errorCode = (error) => (error?.message || '').trim().split(/\s/)[0];
