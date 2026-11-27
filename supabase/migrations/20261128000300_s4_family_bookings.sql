-- Friends-and-family bookings (2026-11-28). John books close friends and
-- family over the phone, often several back to back and with no contact
-- details. Instead of filing them under someone else's email:
--   * a client can be "arranged by" another client, who is the contact, and
--     then needs no phone or email of their own (staff bookings only);
--   * several people can be booked in one go (s4_staff_create_bookings);
--   * time off can be a "hold": time kept free for someone not confirmed yet.

alter table public.s4_clients
    add column arranged_by uuid references public.s4_clients (id) on delete set null,
    add constraint s4_clients_arranged_by_not_self check (arranged_by is distinct from id);
create index s4_clients_arranged_by_idx on public.s4_clients (arranged_by);

alter table public.s4_time_off
    add column kind text not null default 'time_off' check (kind in ('time_off', 'hold'));

drop function public.s4_staff_create_booking(uuid, text, text, text, text, integer[], timestamptz, boolean, text);
create function public.s4_staff_create_booking(
    p_client_id    uuid,
    p_last_name    text,
    p_first_name   text,
    p_phone        text,
    p_email        text,
    p_service_ids  integer[],
    p_starts_at    timestamptz,
    p_gold_card    boolean default false,
    p_notes        text default null,
    p_arranged_by  uuid default null
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
    v_arranger uuid;
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

    -- Family and friends booked over the phone may have no contact details of
    -- their own: they're reached through the client who arranged the visit.
    if p_arranged_by is not null then
        select id into v_arranger from public.s4_clients where id = p_arranged_by;
        if v_arranger is null then
            raise exception 'client_not_found' using errcode = 'P0001';
        end if;
    end if;

    -- Client: the one picked from the list, else whoever has this phone, else
    -- a new one. A picked client may keep the phone or email already on file.
    if p_client_id is not null then
        select id into v_client from public.s4_clients where id = p_client_id;
        if v_client is null then
            raise exception 'client_not_found' using errcode = 'P0001';
        end if;
        if v_phone is null and v_email is null and v_arranger is null
           and not exists (select 1 from public.s4_clients
                            where id = v_client and (phone_e164 is not null or email is not null or arranged_by is not null)) then
            raise exception 'contact_required' using errcode = 'P0001';
        end if;
    elsif v_phone is null and v_email is null and v_arranger is null then
        raise exception 'contact_required' using errcode = 'P0001';
    elsif v_phone is not null then
        select id into v_client from public.s4_clients where phone_e164 = v_phone;
    end if;

    if v_client is null then
        insert into public.s4_clients (first_name, last_name, phone_e164, email, has_gold_card, arranged_by)
        values (v_first, v_last, v_phone, v_email, coalesce(p_gold_card, false), v_arranger)
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
               has_gold_card = c.has_gold_card or coalesce(p_gold_card, false),
               arranged_by = case when v_arranger is not null and v_arranger <> c.id then v_arranger else c.arranged_by end
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

    return jsonb_build_object('id', v_booking, 'client_id', v_client, 'reference', v_ref, 'starts_at', p_starts_at, 'ends_at', v_end);
end;
$$;


-- Several people in one go (e.g. a family, back to back). All or nothing.
-- Each element: { client_id, last_name, first_name, phone, email, service_ids,
-- starts_at, gold_card, notes, arranged_by, arranged_by_index } where
-- arranged_by_index points at an earlier element (the person who organised it).
create function public.s4_staff_create_bookings(p_bookings jsonb) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
    e jsonb;
    v_results jsonb := '[]'::jsonb;
    v_res jsonb;
    v_arranged uuid;
begin
    if not public.s4_is_staff() then
        raise exception 'not_staff' using errcode = 'P0001';
    end if;
    if jsonb_typeof(p_bookings) <> 'array' or jsonb_array_length(p_bookings) not between 1 and 10 then
        raise exception 'invalid_services' using errcode = 'P0001';
    end if;
    for e in select value from jsonb_array_elements(p_bookings)
    loop
        v_arranged := coalesce(nullif(e ->> 'arranged_by', '')::uuid,
                               case when e ? 'arranged_by_index' and e ->> 'arranged_by_index' is not null
                                    then (v_results -> (e ->> 'arranged_by_index')::integer ->> 'client_id')::uuid end);
        v_res := public.s4_staff_create_booking(
            nullif(e ->> 'client_id', '')::uuid,
            e ->> 'last_name', e ->> 'first_name', e ->> 'phone', e ->> 'email',
            array(select jsonb_array_elements_text(e -> 'service_ids')::integer),
            (e ->> 'starts_at')::timestamptz,
            coalesce((e ->> 'gold_card')::boolean, false),
            e ->> 'notes',
            v_arranged);
        v_results := v_results || jsonb_build_array(v_res);
    end loop;
    return v_results;
end;
$$;

create or replace function public.s4_merge_clients(p_keep uuid, p_drop uuid) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
    k public.s4_clients;
    d public.s4_clients;
    v_moved integer;
    v_email extensions.citext;
    v_verified boolean;
begin
    if not public.s4_is_staff() then
        raise exception 'not_staff' using errcode = 'P0001';
    end if;
    if p_keep is null or p_drop is null or p_keep = p_drop then
        raise exception 'same_client' using errcode = 'P0001';
    end if;

    -- Lock both rows (in a fixed order, so two merges can't deadlock).
    perform 1 from public.s4_clients where id in (p_keep, p_drop) order by id for update;
    select * into k from public.s4_clients where id = p_keep;
    select * into d from public.s4_clients where id = p_drop;
    if k.id is null or d.id is null then
        raise exception 'client_not_found' using errcode = 'P0001';
    end if;
    if k.auth_user_id is not null and d.auth_user_id is not null then
        raise exception 'both_linked' using errcode = 'P0001';
    end if;

    update public.s4_bookings set client_id = k.id where client_id = d.id;
    get diagnostics v_moved = row_count;

    -- A Google-verified email wins over a typed one.
    if d.email_verified and not k.email_verified then
        v_email := d.email;
        v_verified := true;
    else
        v_email := coalesce(k.email, d.email);
        v_verified := k.email_verified;
    end if;

    -- People arranged by the dropped record are now arranged by the kept one.
    update public.s4_clients set arranged_by = k.id where arranged_by = d.id and id <> k.id;

    -- Delete first: frees the unique phone, sign-in and verified email.
    delete from public.s4_clients where id = d.id;

    update public.s4_clients
       set first_name = coalesce(nullif(trim(k.first_name), ''), d.first_name, ''),
           last_name = coalesce(nullif(trim(coalesce(k.last_name, '')), ''), d.last_name),
           phone_e164 = coalesce(k.phone_e164, d.phone_e164),
           email = v_email,
           email_verified = v_verified,
           auth_user_id = coalesce(k.auth_user_id, d.auth_user_id),
           has_gold_card = k.has_gold_card or d.has_gold_card,
           created_at = least(k.created_at, d.created_at),
           arranged_by = case when coalesce(k.arranged_by, d.arranged_by) in (k.id, d.id) then null
                              else coalesce(k.arranged_by, d.arranged_by) end
     where id = k.id;

    return jsonb_build_object('kept', k.id, 'bookings_moved', v_moved);
end;
$$;


revoke execute on function public.s4_staff_create_booking(uuid, text, text, text, text, integer[], timestamptz, boolean, text, uuid),
    public.s4_staff_create_bookings(jsonb) from public, anon, authenticated;
grant execute on function public.s4_staff_create_booking(uuid, text, text, text, text, integer[], timestamptz, boolean, text, uuid),
    public.s4_staff_create_bookings(jsonb) to authenticated;
