-- Interleaved bookings (2026-11-28). Two confirmed bookings may now overlap
-- whenever John's hands-on time never does: e.g. Hair Colour at 10:00 and a
-- Toner at 10:30, each worked on during the other's waiting time. Still at
-- most two clients in the salon at once, and time off blocks any overlap.

-- A booking's hands-on time: its span minus its waiting periods.
create function public.s4_hands_on(p_start timestamptz, p_end timestamptz, p_gaps int4multirange)
returns tstzmultirange language sql immutable set search_path = '' as $$
    select tstzmultirange(tstzrange(p_start, p_end, '[)'))
         - coalesce((select range_agg(tstzrange(p_start + make_interval(mins => lower(g)),
                                                p_start + make_interval(mins => upper(g)), '[)'))
                       from unnest(p_gaps) g), '{}'::tstzmultirange);
$$;

create or replace function public.s4_bookings_check_overlap() returns trigger
language plpgsql volatile security definer set search_path = '' as $$
declare
    v_span tstzrange;
    v_hands tstzmultirange;
begin
    if new.status <> 'confirmed' then
        return new;
    end if;
    if not new.gaps <@ int4range(1, greatest(1, floor(extract(epoch from new.ends_at - new.starts_at) / 60)::integer)) then
        raise exception 'invalid_gaps' using errcode = '23514';
    end if;
    perform pg_advisory_xact_lock(hashtext('s4_bookings_overlap'));
    v_span := tstzrange(new.starts_at, new.ends_at, '[)');
    v_hands := public.s4_hands_on(new.starts_at, new.ends_at, new.gaps);

    -- John can't be hands-on with two clients at once.
    if exists (select 1 from public.s4_bookings o
                where o.status = 'confirmed' and o.id <> new.id
                  and o.starts_at < new.ends_at and o.ends_at > new.starts_at
                  and public.s4_hands_on(o.starts_at, o.ends_at, o.gaps) && v_hands) then
        raise exception 'booking_overlap' using errcode = '23P01';
    end if;

    -- At most two clients in the salon at any moment.
    if exists (select 1 from public.s4_bookings o1 join public.s4_bookings o2 on o1.id < o2.id
                where o1.status = 'confirmed' and o2.status = 'confirmed'
                  and new.id not in (o1.id, o2.id)
                  and o1.starts_at < new.ends_at and o1.ends_at > new.starts_at
                  and o2.starts_at < new.ends_at and o2.ends_at > new.starts_at
                  and not isempty(v_span * tstzrange(o1.starts_at, o1.ends_at, '[)') * tstzrange(o2.starts_at, o2.ends_at, '[)'))) then
        raise exception 'booking_overlap' using errcode = '23P01';
    end if;
    return new;
end;
$$;

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

    -- This visit's own waiting periods: services run one after another in the
    -- salon's order. (The booking form works them out the same way.)
    select coalesce(range_agg(int4range(q.at + q.wait_after_min, q.at + q.wait_after_min + q.wait_min)), '{}')
      into v_gaps
      from (select sv.wait_after_min, sv.wait_min,
                   (sum(sv.duration_min) over (order by c.sort_order, c.id, sv.sort_order, sv.id) - sv.duration_min)::integer as at
              from public.s4_services sv join public.s4_categories c on c.id = sv.category_id
             where sv.id = any (v_ids)) q
     where q.wait_min is not null;

    -- Waiting time John has kept to himself isn't bookable online: this
    -- visit's hands-on time can't fall in another booking's closed waiting time
    -- (just waiting there is fine).
    if exists (select 1 from public.s4_bookings b
                where b.status = 'confirmed' and not b.gaps_open
                  and b.starts_at < v_end and b.ends_at > p_starts_at
                  and (tstzmultirange(tstzrange(b.starts_at, b.ends_at, '[)')) - public.s4_hands_on(b.starts_at, b.ends_at, b.gaps))
                      && public.s4_hands_on(p_starts_at, v_end, v_gaps)) then
        raise exception 'slot_taken' using errcode = 'P0001';
    end if;

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
-- gaps: open waiting periods (closed ones count as busy for online visitors).
-- kind: 'booking' or 'time_off'. can_nest: kept for the previous site version.
drop function public.s4_get_busy_times(date, date);
create function public.s4_get_busy_times(p_from date, p_to date)
returns table (busy_start timestamptz, busy_end timestamptz, gaps jsonb, can_nest boolean, kind text)
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
               case when b.gaps_open then
                   coalesce((select jsonb_agg(jsonb_build_object(
                                 'start', b.starts_at + make_interval(mins => lower(g)),
                                 'end', b.starts_at + make_interval(mins => upper(g))) order by lower(g))
                               from unnest(b.gaps) g), '[]'::jsonb)
                   else '[]'::jsonb end,
               true, 'booking'::text
          from public.s4_bookings b
         where b.status = 'confirmed' and b.ends_at > v_from and b.starts_at < v_to
        union all
        select t.starts_at, t.ends_at, '[]'::jsonb, false, 'time_off'::text
          from public.s4_time_off t
         where t.ends_at > v_from and t.starts_at < v_to
        order by 1;
end;
$$;

revoke execute on function public.s4_get_busy_times(date, date), public.s4_hands_on(timestamptz, timestamptz, int4multirange)
    from public, anon, authenticated;
grant execute on function public.s4_get_busy_times(date, date) to anon, authenticated;
