-- Admin theme per staff account ("studio4" or "clean").
-- Staff may change only their own theme: a column-level grant keeps role and
-- display_name read-only, and RLS limits the update to their own row.

alter table public.s4_staff
    add column theme text not null default 'studio4'
    check (theme in ('studio4', 'clean'));

grant update (theme) on public.s4_staff to authenticated;

create policy "s4 staff update own theme" on public.s4_staff
    for update to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
