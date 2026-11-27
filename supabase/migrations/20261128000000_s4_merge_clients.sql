-- Merge two client records (2026-11-28), e.g. the same person booked once by
-- phone and once online. The dropped record's bookings move to the kept one,
-- blank details are filled from it, and it is then deleted. Staff only.

create function public.s4_merge_clients(p_keep uuid, p_drop uuid) returns jsonb
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
           created_at = least(k.created_at, d.created_at)
     where id = k.id;

    return jsonb_build_object('kept', k.id, 'bookings_moved', v_moved);
end;
$$;

revoke execute on function public.s4_merge_clients(uuid, uuid) from public, anon, authenticated;
grant execute on function public.s4_merge_clients(uuid, uuid) to authenticated;
