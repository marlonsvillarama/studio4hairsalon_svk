-- Waiting time (2026-11-24).
-- Some services leave John idle partway through. A service can have a waiting
-- period (hands-on first, then waiting, then finishing). Each booking keeps a
-- snapshot of its own, and another visit may be booked wholly inside it.

alter table public.s4_services
    add column wait_after_min integer,
    add column wait_min integer,
    add constraint s4_services_wait_check check (
        (wait_after_min is null and wait_min is null)
        or (wait_after_min is not null and wait_min is not null
            and wait_after_min > 0 and wait_min > 0 and wait_after_min + wait_min < duration_min));

alter table public.s4_bookings
    add column gaps int4multirange not null default '{}',   -- minutes from starts_at
    add column gaps_open boolean not null default true;     -- offered online?

-- Does [p_start, p_end) sit inside one waiting period of a booking?
create function public.s4_fits_gap(p_host_start timestamptz, p_gaps int4multirange, p_start timestamptz, p_end timestamptz)
returns boolean language sql immutable set search_path = '' as $$
    select case when p_start < p_host_start then false
                else p_gaps @> int4range(floor(extract(epoch from p_start - p_host_start) / 60)::integer,
                                         ceil(extract(epoch from p_end - p_host_start) / 60)::integer) end;
$$;

-- Confirmed bookings may overlap only when one sits inside a waiting period of
-- the other, one level deep (never more than two clients at once). The lock
-- makes concurrent bookings queue, so the check can't be raced.
-- gaps_open is ignored on purpose: staff may use a closed gap.
create function public.s4_bookings_check_overlap() returns trigger
language plpgsql volatile security definer set search_path = '' as $$
declare
    o record;
    v_inside integer := 0;
    v_around integer := 0;
begin
    if new.status <> 'confirmed' then
        return new;
    end if;
    if not new.gaps <@ int4range(1, greatest(1, floor(extract(epoch from new.ends_at - new.starts_at) / 60)::integer)) then
        raise exception 'invalid_gaps' using errcode = '23514';
    end if;
    perform pg_advisory_xact_lock(hashtext('s4_bookings_overlap'));
    for o in select id, starts_at, ends_at, gaps from public.s4_bookings
              where status = 'confirmed' and id <> new.id
                and starts_at < new.ends_at and ends_at > new.starts_at
    loop
        if public.s4_fits_gap(o.starts_at, o.gaps, new.starts_at, new.ends_at) then
            v_inside := v_inside + 1;
        elsif public.s4_fits_gap(new.starts_at, new.gaps, o.starts_at, o.ends_at)
              and not exists (select 1 from public.s4_bookings q
                               where q.status = 'confirmed' and q.id not in (o.id, new.id)
                                 and q.starts_at < o.ends_at and q.ends_at > o.starts_at) then
            v_around := v_around + 1;
        else
            raise exception 'booking_overlap' using errcode = '23P01';
        end if;
    end loop;
    if v_inside > 1 or (v_inside > 0 and v_around > 0) then
        raise exception 'booking_overlap' using errcode = '23P01';
    end if;
    return new;
end;
$$;

create trigger s4_bookings_check_overlap
    before insert or update of starts_at, ends_at, status, gaps on public.s4_bookings
    for each row execute function public.s4_bookings_check_overlap();
alter table public.s4_bookings drop constraint s4_bookings_no_overlap;

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
    v_email text;
    v_client uuid;
    v_other public.s4_clients;
    v_ref text;
    v_booking uuid;
    v_gaps int4multirange;
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
    -- Phone and email are both optional, but at least one is needed so John
    -- can reach the client. A phone that is given must be valid.
    if nullif(trim(coalesce(p_phone, '')), '') is not null then
        v_phone := public.s4_normalize_phone(p_phone);
        if v_phone is null then
            raise exception 'invalid_phone' using errcode = 'P0001';
        end if;
    end if;
    v_email := case when v_uid is not null then lower(nullif(auth.jwt() ->> 'email', ''))
                    else nullif(lower(trim(coalesce(p_email, ''))), '') end;
    if v_phone is null and v_email is null then
        raise exception 'contact_required' using errcode = 'P0001';
    end if;

    -- Time: from tomorrow (salon time) with no upper limit, within opening
    -- hours and on the slot grid. Same-day bookings are by phone only.
    v_local := p_starts_at at time zone s.timezone;
    if v_local::date <= (now() at time zone s.timezone)::date then
        raise exception 'too_soon' using errcode = 'P0001';
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

    -- Waiting time John has kept to himself isn't bookable online.
    if exists (select 1 from public.s4_bookings b
                where b.status = 'confirmed' and not b.gaps_open
                  and b.starts_at < v_end and b.ends_at > p_starts_at
                  and public.s4_fits_gap(b.starts_at, b.gaps, p_starts_at, v_end)) then
        raise exception 'slot_taken' using errcode = 'P0001';
    end if;

    -- This visit's own waiting periods: services run one after another in the
    -- salon's order. (The booking form works them out the same way.)
    select coalesce(range_agg(int4range(q.at + q.wait_after_min, q.at + q.wait_after_min + q.wait_min)), '{}')
      into v_gaps
      from (select sv.wait_after_min, sv.wait_min,
                   (sum(sv.duration_min) over (order by c.sort_order, c.id, sv.sort_order, sv.id) - sv.duration_min)::integer as at
              from public.s4_services sv join public.s4_categories c on c.id = sv.category_id
             where sv.id = any (v_ids)) q
     where q.wait_min is not null;

    -- Client.
    if v_uid is not null then
        -- Signed in with Google: use (or create) the linked row; email comes from the verified JWT.
        perform public.s4_link_my_client();
        select id into v_client from public.s4_clients where auth_user_id = v_uid;

        select * into v_other from public.s4_clients where v_phone is not null and phone_e164 = v_phone and id <> v_client;
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
               phone_e164 = coalesce(v_phone, phone_e164),
               has_gold_card = has_gold_card or coalesce(p_gold_card, false)
         where id = v_client;
    else
        -- Guest: match by phone, otherwise by email; never overwrite details
        -- of a Google-linked client or replace a verified email.
        if v_phone is not null then
            select id into v_client from public.s4_clients where phone_e164 = v_phone;
        end if;
        if v_client is null and v_email is not null then
            select id into v_client from public.s4_clients
             where lower(email) = v_email
             order by email_verified desc, updated_at desc
             limit 1;
        end if;

        if v_client is null then
            insert into public.s4_clients (first_name, last_name, phone_e164, email, has_gold_card)
            values (trim(p_first_name), nullif(trim(coalesce(p_last_name, '')), ''), v_phone, v_email, coalesce(p_gold_card, false))
            returning id into v_client;
        else
            update public.s4_clients c
               set first_name = case when c.auth_user_id is null then trim(p_first_name) else c.first_name end,
                   last_name = case when c.auth_user_id is null then coalesce(nullif(trim(coalesce(p_last_name, '')), ''), c.last_name) else c.last_name end,
                   phone_e164 = coalesce(c.phone_e164, v_phone),
                   email = case when c.email_verified then c.email else coalesce(v_email, c.email) end,
                   has_gold_card = c.has_gold_card or coalesce(p_gold_card, false)
             where c.id = v_client;
        end if;
    end if;

    -- Reference like S4-7KQ2MX (no 0/O/1/I to avoid misreading).
    loop
        v_ref := 'S4-' || (select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', (floor(random() * 32) + 1)::int, 1), '')
                             from generate_series(1, 6));
        exit when not exists (select 1 from public.s4_bookings where reference = v_ref);
    end loop;

    begin
        insert into public.s4_bookings (reference, client_id, starts_at, ends_at, gold_card, total_cents, has_variable_price, notes, source, gaps)
        values (v_ref, v_client, p_starts_at, v_end, coalesce(p_gold_card, false), v_total, coalesce(v_variable, false),
                nullif(left(trim(coalesce(p_notes, '')), 1000), ''), 'online', v_gaps)
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

-- Busy intervals for the booking calendar. Times only: no names, ids or reasons.
-- gaps: waiting periods bookable online. can_nest: a longer visit's waiting
-- period may be booked around this one.
drop function public.s4_get_busy_times(date, date);
create function public.s4_get_busy_times(p_from date, p_to date)
returns table (busy_start timestamptz, busy_end timestamptz, gaps jsonb, can_nest boolean)
language plpgsql stable security definer set search_path = '' as $$
declare
    v_tz text;
    v_from timestamptz;
    v_to timestamptz;
begin
    if p_from is null or p_to is null or p_to < p_from or p_to - p_from > 62 then
        raise exception 'invalid_range' using errcode = 'P0001';
    end if;
    select timezone into v_tz from public.s4_settings where id;
    v_from := p_from::timestamp at time zone v_tz;
    v_to := (p_to + 1)::timestamp at time zone v_tz;

    return query
        select b.starts_at, b.ends_at,
               case when b.gaps_open and not x.inside then
                   coalesce((select jsonb_agg(jsonb_build_object(
                                 'start', b.starts_at + make_interval(mins => lower(g)),
                                 'end', b.starts_at + make_interval(mins => upper(g))) order by lower(g))
                               from unnest(b.gaps) g), '[]'::jsonb)
                   else '[]'::jsonb end,
               not x.inside and not x.hosting
          from public.s4_bookings b
          cross join lateral (
              select coalesce(bool_or(public.s4_fits_gap(q.starts_at, q.gaps, b.starts_at, b.ends_at)), false) as inside,
                     coalesce(bool_or(public.s4_fits_gap(b.starts_at, b.gaps, q.starts_at, q.ends_at)), false) as hosting
                from public.s4_bookings q
               where q.status = 'confirmed' and q.id <> b.id
                 and q.starts_at < b.ends_at and q.ends_at > b.starts_at) x
         where b.status = 'confirmed' and b.ends_at > v_from and b.starts_at < v_to
        union all
        select t.starts_at, t.ends_at, '[]'::jsonb, false
          from public.s4_time_off t
         where t.ends_at > v_from and t.starts_at < v_to
        order by 1;
end;
$$;

revoke execute on function public.s4_get_busy_times(date, date), public.s4_bookings_check_overlap(),
    public.s4_fits_gap(timestamptz, int4multirange, timestamptz, timestamptz) from public, anon, authenticated;
grant execute on function public.s4_get_busy_times(date, date) to anon, authenticated;
