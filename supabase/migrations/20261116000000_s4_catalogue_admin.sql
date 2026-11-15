-- Admin catalogue management: add/remove categories and services.
--
-- "Disable" (is_active = false) hides a category or service from customers.
-- "Remove" deletes it when it has never been booked; when bookings reference
-- it, the admin page soft-removes it instead (deleted_at), so existing
-- appointments keep their link and John can still see them. Booking items
-- also keep a snapshot of the service name and price.

alter table public.s4_categories add column deleted_at timestamptz;
alter table public.s4_services   add column deleted_at timestamptz;

-- New rows get ids automatically (existing ids are kept).
create sequence public.s4_categories_id_seq as smallint owned by public.s4_categories.id;
select setval('public.s4_categories_id_seq', (select coalesce(max(id), 0) + 1 from public.s4_categories), false);
alter table public.s4_categories alter column id set default nextval('public.s4_categories_id_seq');

create sequence public.s4_services_id_seq as integer owned by public.s4_services.id;
select setval('public.s4_services_id_seq', (select coalesce(max(id), 0) + 1 from public.s4_services), false);
alter table public.s4_services alter column id set default nextval('public.s4_services_id_seq');

grant usage on sequence public.s4_categories_id_seq, public.s4_services_id_seq to authenticated;

-- Customers only see what is active, not removed, and in an active category.
drop policy "s4 public reads active categories" on public.s4_categories;
create policy "s4 public reads active categories" on public.s4_categories
    for select to anon, authenticated
    using ((is_active and deleted_at is null) or public.s4_is_staff());

drop policy "s4 public reads active services" on public.s4_services;
create policy "s4 public reads active services" on public.s4_services
    for select to anon, authenticated
    using (
        (is_active and deleted_at is null
         and exists (select 1 from public.s4_categories c
                      where c.id = category_id and c.is_active and c.deleted_at is null))
        or public.s4_is_staff()
    );

-- Online bookings refuse disabled/removed services and services in a
-- disabled/removed category (same function, stricter service check).
create or replace function public.s4_create_booking(
    p_service_ids  integer[],
    p_starts_at    timestamptz,
    p_gold_card    boolean default false,
    p_first_name   text default null,
    p_last_name    text default null,
    p_phone        text default null,
    p_email        text default null,
    p_notes        text default null
) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
    s public.s4_settings;
    h public.s4_business_hours;
    v_uid uuid := auth.uid();
    v_ids integer[];
    v_count integer;
    v_duration integer;
    v_total integer;
    v_variable boolean;
    v_all_addon boolean;
    v_local timestamp;
    v_start_min integer;
    v_open_min integer;
    v_close_min integer;
    v_end timestamptz;
    v_phone text;
    v_client uuid;
    v_other public.s4_clients;
    v_open_count integer;
    v_ref text;
    v_booking uuid;
begin
    select * into s from public.s4_settings where id;
    if not found or not s.online_booking_enabled then
        raise exception 'booking_disabled' using errcode = 'P0001';
    end if;

    -- Services: exist, active, not only add-ons. Priced server-side.
    v_ids := array(select distinct unnest(p_service_ids));
    if coalesce(cardinality(v_ids), 0) = 0 or cardinality(v_ids) > 10 then
        raise exception 'invalid_services' using errcode = 'P0001';
    end if;
    select count(*),
           sum(duration_min),
           sum(case when p_gold_card and gold_card_price_cents is not null then gold_card_price_cents else price_cents end),
           bool_or(price_is_from),
           bool_and(is_addon)
      into v_count, v_duration, v_total, v_variable, v_all_addon
      from public.s4_services sv
     where sv.id = any (v_ids)
       and sv.is_active and sv.deleted_at is null
       and exists (select 1 from public.s4_categories c
                    where c.id = sv.category_id and c.is_active and c.deleted_at is null);
    if v_count <> cardinality(v_ids) or v_all_addon then
        raise exception 'invalid_services' using errcode = 'P0001';
    end if;

    -- Contact details.
    if nullif(trim(coalesce(p_first_name, '')), '') is null then
        raise exception 'invalid_details' using errcode = 'P0001';
    end if;
    v_phone := public.s4_normalize_phone(p_phone);
    if v_phone is null then
        raise exception 'invalid_phone' using errcode = 'P0001';
    end if;

    -- Time: notice, horizon, opening hours and slot grid, in salon time.
    if p_starts_at < now() + make_interval(mins => s.min_notice_min) then
        raise exception 'too_soon' using errcode = 'P0001';
    end if;
    v_local := p_starts_at at time zone s.timezone;
    if v_local::date > (now() at time zone s.timezone)::date + s.horizon_days then
        raise exception 'too_far' using errcode = 'P0001';
    end if;
    select * into h from public.s4_business_hours where weekday = extract(dow from v_local);
    if not found or not h.is_open then
        raise exception 'outside_hours' using errcode = 'P0001';
    end if;
    v_start_min := extract(hour from v_local) * 60 + extract(minute from v_local);
    v_open_min := extract(hour from h.opens_at) * 60 + extract(minute from h.opens_at);
    v_close_min := extract(hour from h.closes_at) * 60 + extract(minute from h.closes_at);
    if extract(second from v_local) <> 0
       or v_start_min < v_open_min
       or v_start_min + v_duration > v_close_min
       or (v_start_min - v_open_min) % s.slot_step_min <> 0 then
        raise exception 'outside_hours' using errcode = 'P0001';
    end if;
    v_end := p_starts_at + make_interval(mins => v_duration);
    if exists (select 1 from public.s4_time_off t
                where tstzrange(t.starts_at, t.ends_at, '[)') && tstzrange(p_starts_at, v_end, '[)')) then
        raise exception 'slot_taken' using errcode = 'P0001';
    end if;

    -- Client.
    if v_uid is not null then
        -- Signed in with Google: use (or create) the linked row; email comes from the verified JWT.
        perform public.s4_link_my_client();
        select id into v_client from public.s4_clients where auth_user_id = v_uid;

        select * into v_other from public.s4_clients where phone_e164 = v_phone and id <> v_client;
        if found then
            if v_other.auth_user_id is not null then
                raise exception 'phone_in_use' using errcode = 'P0001';
            end if;
            -- An earlier guest row with this phone: fold it into the signed-in client.
            update public.s4_bookings set client_id = v_client where client_id = v_other.id;
            update public.s4_clients set has_gold_card = has_gold_card or v_other.has_gold_card where id = v_client;
            delete from public.s4_clients where id = v_other.id;
        end if;

        update public.s4_clients
           set first_name = trim(p_first_name),
               last_name = nullif(trim(coalesce(p_last_name, '')), ''),
               phone_e164 = v_phone,
               has_gold_card = has_gold_card or coalesce(p_gold_card, false)
         where id = v_client;
    else
        -- Guest: match by phone. Never overwrite details of a Google-linked client.
        insert into public.s4_clients (first_name, last_name, phone_e164, email, has_gold_card)
        values (trim(p_first_name), nullif(trim(coalesce(p_last_name, '')), ''), v_phone,
                nullif(lower(trim(coalesce(p_email, ''))), ''), coalesce(p_gold_card, false))
        on conflict (phone_e164) do update
           set first_name = case when public.s4_clients.auth_user_id is null then excluded.first_name else public.s4_clients.first_name end,
               last_name = case when public.s4_clients.auth_user_id is null then coalesce(excluded.last_name, public.s4_clients.last_name) else public.s4_clients.last_name end,
               email = case when public.s4_clients.email_verified then public.s4_clients.email else coalesce(excluded.email, public.s4_clients.email) end,
               has_gold_card = public.s4_clients.has_gold_card or excluded.has_gold_card
        returning id into v_client;
    end if;

    -- Basic spam protection.
    select count(*) into v_open_count
      from public.s4_bookings
     where client_id = v_client and status = 'confirmed' and starts_at > now();
    if v_open_count >= s.max_open_bookings_per_phone then
        raise exception 'too_many_bookings' using errcode = 'P0001';
    end if;

    -- Reference like S4-7KQ2MX (no 0/O/1/I to avoid misreading).
    loop
        v_ref := 'S4-' || (select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', (floor(random() * 32) + 1)::int, 1), '')
                             from generate_series(1, 6));
        exit when not exists (select 1 from public.s4_bookings where reference = v_ref);
    end loop;

    begin
        insert into public.s4_bookings (reference, client_id, starts_at, ends_at, gold_card, total_cents, has_variable_price, notes, source)
        values (v_ref, v_client, p_starts_at, v_end, coalesce(p_gold_card, false), v_total, coalesce(v_variable, false),
                nullif(left(trim(coalesce(p_notes, '')), 1000), ''), 'online')
        returning id into v_booking;
    exception when exclusion_violation then
        raise exception 'slot_taken' using errcode = 'P0001';
    end;

    insert into public.s4_booking_items (booking_id, service_id, name, price_cents, gold_card_applied, duration_min, price_is_from, sort_order)
    select v_booking, sv.id, sv.name,
           case when p_gold_card and sv.gold_card_price_cents is not null then sv.gold_card_price_cents else sv.price_cents end,
           coalesce(p_gold_card, false) and sv.gold_card_price_cents is not null,
           sv.duration_min, sv.price_is_from,
           array_position(v_ids, sv.id)
      from public.s4_services sv
     where sv.id = any (v_ids);

    return jsonb_build_object(
        'reference', v_ref,
        'starts_at', p_starts_at,
        'ends_at', v_end,
        'total_cents', v_total,
        'has_variable_price', coalesce(v_variable, false)
    );
end;
$$;
