-- Bookings made by staff from the admin (2026-11-26), e.g. phone or walk-in
-- clients. Unlike online bookings, staff may book today, past times, outside
-- opening hours, on time off and in waiting time closed to online bookings.
-- The overlap trigger (s4_bookings_check_overlap) still applies.

create function public.s4_staff_create_booking(
    p_client_id    uuid,
    p_last_name    text,
    p_first_name   text,
    p_phone        text,
    p_email        text,
    p_service_ids  integer[],
    p_starts_at    timestamptz,
    p_gold_card    boolean default false,
    p_notes        text default null
) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
    v_ids integer[];
    v_count integer;
    v_duration integer;
    v_total integer;
    v_variable boolean;
    v_all_addon boolean;
    v_end timestamptz;
    v_phone text;
    v_email text;
    v_first text := nullif(trim(coalesce(p_first_name, '')), '');
    v_last text := nullif(trim(coalesce(p_last_name, '')), '');
    v_client uuid;
    v_holder uuid;
    v_ref text;
    v_booking uuid;
    v_gaps int4multirange;
begin
    if not public.s4_is_staff() then
        raise exception 'not_staff' using errcode = 'P0001';
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
    if p_starts_at is null then
        raise exception 'invalid_time' using errcode = 'P0001';
    end if;
    v_end := p_starts_at + make_interval(mins => v_duration);

    -- Contact details: a first name, and a phone or an email.
    if v_first is null then
        raise exception 'invalid_details' using errcode = 'P0001';
    end if;
    if nullif(trim(coalesce(p_phone, '')), '') is not null then
        v_phone := public.s4_normalize_phone(p_phone);
        if v_phone is null then
            raise exception 'invalid_phone' using errcode = 'P0001';
        end if;
    end if;
    v_email := nullif(lower(trim(coalesce(p_email, ''))), '');

    -- Client: the one picked from the list, else whoever has this phone, else
    -- a new one. A picked client may keep the phone or email already on file.
    if p_client_id is not null then
        select id into v_client from public.s4_clients where id = p_client_id;
        if v_client is null then
            raise exception 'client_not_found' using errcode = 'P0001';
        end if;
        if v_phone is null and v_email is null
           and not exists (select 1 from public.s4_clients
                            where id = v_client and (phone_e164 is not null or email is not null)) then
            raise exception 'contact_required' using errcode = 'P0001';
        end if;
    elsif v_phone is null and v_email is null then
        raise exception 'contact_required' using errcode = 'P0001';
    elsif v_phone is not null then
        select id into v_client from public.s4_clients where phone_e164 = v_phone;
    end if;

    if v_client is null then
        insert into public.s4_clients (first_name, last_name, phone_e164, email, has_gold_card)
        values (v_first, v_last, v_phone, v_email, coalesce(p_gold_card, false))
        returning id into v_client;
    else
        if v_phone is not null then
            select id into v_holder from public.s4_clients where phone_e164 = v_phone and id <> v_client;
            if v_holder is not null then
                raise exception 'phone_in_use' using errcode = 'P0001';
            end if;
        end if;
        update public.s4_clients c
           set first_name = v_first,
               last_name = coalesce(v_last, c.last_name),
               phone_e164 = coalesce(v_phone, c.phone_e164),
               email = case when c.email_verified then c.email else coalesce(v_email, c.email) end,
               has_gold_card = c.has_gold_card or coalesce(p_gold_card, false)
         where c.id = v_client;
    end if;

    -- This visit's own waiting periods (same order as s4_create_booking).
    select coalesce(range_agg(int4range(q.at + q.wait_after_min, q.at + q.wait_after_min + q.wait_min)), '{}')
      into v_gaps
      from (select sv.wait_after_min, sv.wait_min,
                   (sum(sv.duration_min) over (order by c.sort_order, c.id, sv.sort_order, sv.id) - sv.duration_min)::integer as at
              from public.s4_services sv join public.s4_categories c on c.id = sv.category_id
             where sv.id = any (v_ids)) q
     where q.wait_min is not null;

    loop
        v_ref := 'S4-' || (select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', (floor(random() * 32) + 1)::int, 1), '')
                             from generate_series(1, 6));
        exit when not exists (select 1 from public.s4_bookings where reference = v_ref);
    end loop;

    begin
        insert into public.s4_bookings (reference, client_id, starts_at, ends_at, gold_card, total_cents, has_variable_price, notes, source, gaps)
        values (v_ref, v_client, p_starts_at, v_end, coalesce(p_gold_card, false), v_total, coalesce(v_variable, false),
                nullif(left(trim(coalesce(p_notes, '')), 1000), ''), 'admin', v_gaps)
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

    return jsonb_build_object('id', v_booking, 'reference', v_ref, 'starts_at', p_starts_at, 'ends_at', v_end);
end;
$$;

revoke execute on function public.s4_staff_create_booking(uuid, text, text, text, text, integer[], timestamptz, boolean, text)
    from public, anon, authenticated;
grant execute on function public.s4_staff_create_booking(uuid, text, text, text, text, integer[], timestamptz, boolean, text)
    to authenticated;
