-- Studio 4 Hair Salon: booking schema (runs after 20261115000000_s4_archive_old,
-- which moved the previous s4_ tables into the private s4_archive schema).
-- Every object is prefixed s4_. The website uses only the publishable key,
-- which runs as the `anon` role (or `authenticated` once a client signs in
-- with Google / John signs in to /admin). Public access is limited to the
-- catalogue, opening hours, busy intervals and one booking function.

create extension if not exists citext with schema extensions;

-- ─────────────────────────────────────────────────────────────── types ──

create type public.s4_booking_status as enum ('confirmed', 'cancelled', 'completed', 'no_show');

-- ────────────────────────────────────────────────────────────── tables ──

create table public.s4_categories (
    id          smallint primary key,
    slug        text not null unique,
    name        text not null,
    description text,
    image       text,
    sort_order  smallint not null default 0,
    is_active   boolean not null default true
);

create table public.s4_services (
    id                     integer primary key,
    category_id            smallint not null references public.s4_categories (id),
    name                   text not null,
    description            text,
    price_cents            integer not null check (price_cents >= 0),
    gold_card_price_cents  integer check (gold_card_price_cents >= 0 and gold_card_price_cents < price_cents),
    duration_min           integer not null check (duration_min > 0),
    price_is_from          boolean not null default false,  -- "from $X": final price can vary
    is_addon               boolean not null default false,  -- only bookable with another service
    sort_order             smallint not null default 0,
    is_active              boolean not null default true,
    created_at             timestamptz not null default now(),
    updated_at             timestamptz not null default now()
);
create index s4_services_category_idx on public.s4_services (category_id, sort_order);

create table public.s4_business_hours (
    weekday    smallint primary key check (weekday between 0 and 6),  -- 0 = Sunday
    is_open    boolean not null default false,
    opens_at   time,
    closes_at  time,
    check (not is_open or (opens_at is not null and closes_at is not null and closes_at > opens_at))
);

create table public.s4_settings (
    id                           boolean primary key default true check (id),  -- single row
    timezone                     text not null default 'Pacific/Auckland',
    slot_step_min                integer not null default 30 check (slot_step_min > 0),
    min_notice_min               integer not null default 60 check (min_notice_min >= 0),
    horizon_days                 integer not null default 14 check (horizon_days > 0),
    online_booking_enabled       boolean not null default true,
    max_open_bookings_per_phone  integer not null default 3 check (max_open_bookings_per_phone > 0),
    updated_at                   timestamptz not null default now()
);

create table public.s4_staff (
    user_id       uuid primary key references auth.users (id) on delete cascade,
    display_name  text not null,
    role          text not null default 'admin' check (role in ('owner', 'admin')),
    created_at    timestamptz not null default now()
);

create table public.s4_time_off (
    id          uuid primary key default gen_random_uuid(),
    starts_at   timestamptz not null,
    ends_at     timestamptz not null,
    reason      text,
    created_by  uuid references public.s4_staff (user_id) on delete set null,
    created_at  timestamptz not null default now(),
    check (ends_at > starts_at)
);
create index s4_time_off_range_idx on public.s4_time_off using gist (tstzrange(starts_at, ends_at, '[)'));

create table public.s4_clients (
    id              uuid primary key default gen_random_uuid(),
    auth_user_id    uuid unique references auth.users (id) on delete set null,  -- set once signed in with Google
    first_name      text not null default '',
    last_name       text,
    phone_e164      text unique check (phone_e164 is null or phone_e164 ~ '^\+[1-9][0-9]{6,14}$'),
    email           extensions.citext,
    email_verified  boolean not null default false,  -- true only when the email came from Google
    has_gold_card   boolean not null default false,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);
-- A verified email belongs to exactly one client; unverified (typed) emails may repeat.
create unique index s4_clients_verified_email_key on public.s4_clients (email) where email_verified;
create index s4_clients_email_idx on public.s4_clients (email);

create table public.s4_bookings (
    id                  uuid primary key default gen_random_uuid(),
    reference           text not null unique,
    client_id           uuid not null references public.s4_clients (id) on delete restrict,
    starts_at           timestamptz not null,
    ends_at             timestamptz not null,
    status              public.s4_booking_status not null default 'confirmed',
    gold_card           boolean not null default false,
    total_cents         integer not null check (total_cents >= 0),
    has_variable_price  boolean not null default false,
    notes               text check (char_length(notes) <= 1000),
    source              text not null default 'online' check (source in ('online', 'admin', 'import')),
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    cancelled_at        timestamptz,
    cancel_reason       text,
    check (ends_at > starts_at),
    -- John is the only stylist: two confirmed bookings can never overlap.
    constraint s4_bookings_no_overlap
        exclude using gist (tstzrange(starts_at, ends_at, '[)') with &&) where (status = 'confirmed')
);
create index s4_bookings_client_idx on public.s4_bookings (client_id);
create index s4_bookings_starts_idx on public.s4_bookings (starts_at);

create table public.s4_booking_items (
    booking_id         uuid not null references public.s4_bookings (id) on delete cascade,
    service_id         integer not null references public.s4_services (id),
    -- Snapshot at booking time, so later price changes never rewrite history.
    name               text not null,
    price_cents        integer not null check (price_cents >= 0),
    gold_card_applied  boolean not null default false,
    duration_min       integer not null check (duration_min > 0),
    price_is_from      boolean not null default false,
    sort_order         smallint not null default 0,
    primary key (booking_id, service_id)
);

-- ──────────────────────────────────────────────────────────── triggers ──

create function public.s4_set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

create trigger s4_services_updated_at before update on public.s4_services
    for each row execute function public.s4_set_updated_at();
create trigger s4_settings_updated_at before update on public.s4_settings
    for each row execute function public.s4_set_updated_at();
create trigger s4_clients_updated_at before update on public.s4_clients
    for each row execute function public.s4_set_updated_at();
create trigger s4_bookings_updated_at before update on public.s4_bookings
    for each row execute function public.s4_set_updated_at();

-- ─────────────────────────────────────────────────────────── functions ──

create function public.s4_is_staff() returns boolean
language sql stable security definer set search_path = '' as $$
    select exists (select 1 from public.s4_staff where user_id = auth.uid());
$$;

-- NZ-friendly phone normalisation to E.164. Returns null when it can't be a number.
create function public.s4_normalize_phone(p_phone text) returns text
language plpgsql immutable set search_path = '' as $$
declare
    v text := regexp_replace(coalesce(p_phone, ''), '[^0-9+]', '', 'g');
begin
    if v like '+%' then
        v := '+' || regexp_replace(substr(v, 2), '[^0-9]', '', 'g');
    elsif v like '00%' then
        v := '+' || substr(v, 3);
    elsif v like '0%' then
        v := '+64' || substr(v, 2);          -- 022 188 5240 → +64221885240
    elsif v like '64%' then
        v := '+' || v;
    else
        v := '+64' || v;
    end if;
    if v !~ '^\+[1-9][0-9]{7,14}$' then
        return null;
    end if;
    return v;
end;
$$;

-- Busy intervals for the booking calendar. Times only: no names, ids or reasons.
create function public.s4_get_busy_times(p_from date, p_to date)
returns table (busy_start timestamptz, busy_end timestamptz)
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
        select b.starts_at, b.ends_at
          from public.s4_bookings b
         where b.status = 'confirmed' and b.ends_at > v_from and b.starts_at < v_to
        union all
        select t.starts_at, t.ends_at
          from public.s4_time_off t
         where t.ends_at > v_from and t.starts_at < v_to
        order by 1;
end;
$$;

-- Called after Google sign-in. Maps the verified Google email to s4_clients:
-- an existing linked row, else a guest row with the same email, else a new row.
create function public.s4_link_my_client() returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
    v_uid uuid := auth.uid();
    v_meta jsonb := coalesce(auth.jwt() -> 'user_metadata', '{}'::jsonb);
    v_email text := lower(nullif(auth.jwt() ->> 'email', ''));
    v_verified boolean := coalesce((v_meta ->> 'email_verified')::boolean, false);
    c public.s4_clients;
begin
    if v_uid is null then
        raise exception 'not_signed_in' using errcode = 'P0001';
    end if;

    select * into c from public.s4_clients where auth_user_id = v_uid;

    if not found and v_verified and v_email is not null
       and not exists (select 1 from public.s4_clients
                        where email = v_email and email_verified and auth_user_id is distinct from v_uid) then
        update public.s4_clients
           set auth_user_id = v_uid, email = v_email, email_verified = true
         where id = (select id from public.s4_clients
                      where email = v_email and auth_user_id is null
                      order by updated_at desc limit 1)
        returning * into c;
    end if;

    if c.id is null then
        insert into public.s4_clients (auth_user_id, first_name, last_name, email, email_verified)
        values (
            v_uid,
            coalesce(v_meta ->> 'given_name', split_part(coalesce(v_meta ->> 'full_name', v_meta ->> 'name', ''), ' ', 1), ''),
            nullif(coalesce(v_meta ->> 'family_name',
                            nullif(regexp_replace(coalesce(v_meta ->> 'full_name', v_meta ->> 'name', ''), '^\S+\s*', ''), '')), ''),
            v_email,
            v_verified and not exists (select 1 from public.s4_clients where email = v_email and email_verified)
        )
        returning * into c;
    end if;

    return jsonb_build_object(
        'first_name', c.first_name,
        'last_name', c.last_name,
        'phone', c.phone_e164,
        'email', coalesce(c.email::text, v_email),
        'has_gold_card', c.has_gold_card
    );
end;
$$;

-- The only way to create a booking from the website. Prices, duration and
-- availability are all decided here, never trusted from the browser.
create function public.s4_create_booking(
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
      from public.s4_services
     where id = any (v_ids) and is_active;
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

-- ───────────────────────────────────────────────────── row level security ──

alter table public.s4_categories     enable row level security;
alter table public.s4_services       enable row level security;
alter table public.s4_business_hours enable row level security;
alter table public.s4_settings       enable row level security;
alter table public.s4_staff          enable row level security;
alter table public.s4_time_off       enable row level security;
alter table public.s4_clients        enable row level security;
alter table public.s4_bookings       enable row level security;
alter table public.s4_booking_items  enable row level security;

-- Catalogue: anyone may read what's active; staff manage everything.
create policy "s4 public reads active categories" on public.s4_categories
    for select to anon, authenticated using (is_active or public.s4_is_staff());
create policy "s4 staff manage categories" on public.s4_categories
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());

create policy "s4 public reads active services" on public.s4_services
    for select to anon, authenticated using (is_active or public.s4_is_staff());
create policy "s4 staff manage services" on public.s4_services
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());

create policy "s4 public reads hours" on public.s4_business_hours
    for select to anon, authenticated using (true);
create policy "s4 staff manage hours" on public.s4_business_hours
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());

create policy "s4 public reads settings" on public.s4_settings
    for select to anon, authenticated using (true);
create policy "s4 staff manage settings" on public.s4_settings
    for update to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());

-- Staff list: staff see it; anyone signed in can see whether they are on it.
create policy "s4 staff read staff" on public.s4_staff
    for select to authenticated using (user_id = auth.uid() or public.s4_is_staff());

-- Private: staff only (no anon policies at all).
create policy "s4 staff manage time off" on public.s4_time_off
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());

create policy "s4 staff manage clients" on public.s4_clients
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());
create policy "s4 clients read own row" on public.s4_clients
    for select to authenticated using (auth_user_id = auth.uid());

create policy "s4 staff manage bookings" on public.s4_bookings
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());
create policy "s4 clients read own bookings" on public.s4_bookings
    for select to authenticated
    using (client_id in (select id from public.s4_clients where auth_user_id = auth.uid()));

create policy "s4 staff manage booking items" on public.s4_booking_items
    for all to authenticated using (public.s4_is_staff()) with check (public.s4_is_staff());
create policy "s4 clients read own booking items" on public.s4_booking_items
    for select to authenticated
    using (booking_id in (select b.id from public.s4_bookings b
                            join public.s4_clients c on c.id = b.client_id
                           where c.auth_user_id = auth.uid()));

-- ──────────────────────────────────────────────────────────────── grants ──
-- Supabase grants broad table privileges to anon/authenticated by default.
-- Narrow them: RLS is the second lock, grants are the first.

revoke all on public.s4_categories, public.s4_services, public.s4_business_hours, public.s4_settings,
              public.s4_staff, public.s4_time_off, public.s4_clients, public.s4_bookings, public.s4_booking_items
    from anon, authenticated;

grant select on public.s4_categories, public.s4_services, public.s4_business_hours, public.s4_settings
    to anon, authenticated;

-- authenticated covers both Google clients and John; RLS decides who may do what.
grant insert, update, delete on public.s4_categories, public.s4_services, public.s4_business_hours to authenticated;
grant update on public.s4_settings to authenticated;
grant select on public.s4_staff to authenticated;
grant select, insert, update, delete on public.s4_time_off, public.s4_clients, public.s4_bookings, public.s4_booking_items
    to authenticated;

revoke execute on function public.s4_is_staff(), public.s4_normalize_phone(text),
                           public.s4_get_busy_times(date, date), public.s4_link_my_client(),
                           public.s4_create_booking(integer[], timestamptz, boolean, text, text, text, text, text),
                           public.s4_set_updated_at()
    from public, anon, authenticated;

grant execute on function public.s4_is_staff() to anon, authenticated;  -- used inside RLS policies
grant execute on function public.s4_get_busy_times(date, date) to anon, authenticated;
grant execute on function public.s4_create_booking(integer[], timestamptz, boolean, text, text, text, text, text)
    to anon, authenticated;
grant execute on function public.s4_link_my_client() to authenticated;
