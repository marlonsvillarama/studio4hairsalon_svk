-- Staff notes on bookings (2026-11-27), e.g. "used colour 6.1" or "running late".
-- Kept apart from s4_bookings.notes (the client's own note), because clients
-- can read their own booking rows; these notes are for staff only.

create table public.s4_booking_notes (
    id          uuid primary key default gen_random_uuid(),
    booking_id  uuid not null references public.s4_bookings (id) on delete cascade,
    body        text not null check (char_length(trim(body)) between 1 and 1000),
    created_by  uuid default auth.uid() references public.s4_staff (user_id) on delete set null,
    created_at  timestamptz not null default now()
);
create index s4_booking_notes_booking_idx on public.s4_booking_notes (booking_id, created_at);

alter table public.s4_booking_notes enable row level security;
create policy "s4 staff manage booking notes" on public.s4_booking_notes
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());

revoke all on public.s4_booking_notes from public, anon, authenticated;
grant select, insert, delete on public.s4_booking_notes to authenticated;
