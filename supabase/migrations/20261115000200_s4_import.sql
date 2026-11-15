-- Rebuild Studio 4's catalogue and booking history from the archived
-- January 2026 tables (see 20261115000000_s4_archive_old.sql).
-- The original catalogue is the source of truth; ids are kept.

-- ─── categories ──────────────────────────────────────────────────────────

insert into public.s4_categories (id, slug, name, description, image, sort_order, is_active)
select id, link, name, description, image, id, coalesce(is_active, true)
  from s4_archive.s4_categories_20261115;

-- ─── services ────────────────────────────────────────────────────────────

insert into public.s4_services
    (id, category_id, name, description, price_cents, duration_min, price_is_from, sort_order, is_active, created_at)
select id, category, name, description, (price * 100)::int, coalesce(duration, 30), coalesce(is_range, false),
       id, coalesce(is_active, true), created_at
  from s4_archive.s4_services_20261115;

-- Gold Card becomes a price on the cut itself, chosen once with the
-- "I have a Gold Card" switch, instead of a separate service.
update public.s4_services set gold_card_price_cents = 3000 where id = 3;  -- Men's Haircut: $35 → $30
update public.s4_services set gold_card_price_cents = 3500 where id = 4;  -- Women's Haircut with Blow-dry: $40 → $35
update public.s4_services set is_active = false where id = 2;              -- old "Men/Women (Gold Card holder)" row

-- Extras that are only booked alongside another service.
update public.s4_services set is_addon = true where id in (5, 6);          -- Hair Wash (additional), Hair Iron (additional)

-- ─── opening hours and booking rules ─────────────────────────────────────

insert into public.s4_business_hours (weekday, is_open, opens_at, closes_at) values
    (0, false, null,    null),
    (1, true,  '09:30', '17:00'),
    (2, true,  '09:30', '17:00'),
    (3, true,  '09:30', '17:00'),
    (4, true,  '09:30', '17:00'),
    (5, true,  '09:30', '17:00'),
    (6, true,  '09:30', '17:00');

insert into public.s4_settings (id) values (true);

-- ─── clients ─────────────────────────────────────────────────────────────
-- One client per normalised phone number; appointments without a usable
-- phone are grouped by email. The most recent name and email win.

create temporary table s4_import_appts as
select a.id,
       a.date,
       lpad(regexp_replace(a.time::text, '\D', '', 'g'), 4, '0') as hhmm,
       nullif(trim(a.name), '') as name,
       nullif(lower(trim(a.email)), '') as email,
       public.s4_normalize_phone(nullif(regexp_replace(coalesce(a.phone::text, ''), '\D', '', 'g'), '')) as phone,
       nullif(regexp_replace(a.service::text, '\D', '', 'g'), '')::int as service_id,
       a.created_at
  from s4_archive.s4_appointments_20261115 a;

alter table s4_import_appts add column client_key text;
update s4_import_appts set client_key = coalesce('p:' || phone, 'e:' || email, 'a:' || id);

create temporary table s4_import_clients as
select distinct on (client_key)
       client_key,
       gen_random_uuid() as client_id,
       split_part(coalesce(name, ''), ' ', 1) as first_name,
       nullif(regexp_replace(coalesce(name, ''), '^\S+\s*', ''), '') as last_name,
       phone,
       email,
       min(created_at) over (partition by client_key) as first_seen
  from s4_import_appts
 order by client_key, date desc, hhmm desc;

insert into public.s4_clients (id, first_name, last_name, phone_e164, email, email_verified, created_at)
select client_id, first_name, last_name, phone, email, false, first_seen
  from s4_import_clients;

-- ─── bookings (all past, so they import as completed history) ────────────

create temporary table s4_import_bookings as
select a.id as old_id,
       gen_random_uuid() as booking_id,
       c.client_id,
       (a.date + (substr(a.hhmm, 1, 2) || ':' || substr(a.hhmm, 3, 2))::time) at time zone 'Pacific/Auckland' as starts_at,
       sv.id as service_id,
       sv.name as service_name,
       coalesce(sv.price_cents, 0) as price_cents,
       coalesce(sv.duration_min, 30) as duration_min,
       coalesce(sv.price_is_from, false) as price_is_from,
       a.created_at
  from s4_import_appts a
  join s4_import_clients c using (client_key)
  left join public.s4_services sv on sv.id = a.service_id;

insert into public.s4_bookings
    (id, reference, client_id, starts_at, ends_at, status, gold_card, total_cents, has_variable_price, source, created_at)
select booking_id,
       'S4-H' || lpad(old_id::text, 5, '0'),
       client_id,
       starts_at,
       starts_at + make_interval(mins => duration_min),
       case when starts_at < now() then 'completed' else 'confirmed' end::public.s4_booking_status,
       service_id = 2,                    -- booked as the old Gold Card haircut
       price_cents,                       -- today's catalogue price; the old table kept no price
       price_is_from,
       'import',
       created_at
  from s4_import_bookings;

insert into public.s4_booking_items
    (booking_id, service_id, name, price_cents, gold_card_applied, duration_min, price_is_from, sort_order)
select booking_id, service_id, service_name, price_cents, service_id = 2, duration_min, price_is_from, 1
  from s4_import_bookings
 where service_id is not null;

-- Done with the working tables.
drop table s4_import_bookings;
drop table s4_import_clients;
drop table s4_import_appts;
