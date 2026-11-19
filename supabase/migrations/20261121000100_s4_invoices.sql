-- Tax invoices (2026-11-21).
-- John is GST-registered. A completed booking can get a tax invoice: a draft
-- prefilled from the booked services, which John adjusts and then issues.
-- Issued invoices get the next number, snapshot the client and business
-- details, and can never be edited (only voided). Prices are GST-inclusive
-- at 15%, so GST = 3/23 of the total.
-- Everything here is staff-only: reads go through RLS, writes only through
-- the functions below.

-- ───────────────────────────────────────────────────── business details ──

create table public.s4_business (
    id            boolean primary key default true check (id),  -- single row
    trading_name  text not null default '' check (char_length(trading_name) <= 120),
    legal_name    text not null default '' check (char_length(legal_name) <= 120),
    gst_number    text not null default '' check (gst_number = '' or gst_number ~ '^[0-9]{8,9}$'),
    address       text not null default '' check (char_length(address) <= 300),
    phone         text not null default '' check (char_length(phone) <= 40),
    email         text not null default '' check (char_length(email) <= 120),
    invoice_note  text not null default '' check (char_length(invoice_note) <= 500),
    updated_at    timestamptz not null default now()
);
insert into public.s4_business (trading_name, address, phone)
values ('Studio 4 Hair Salon', E'7 George Street\nPalmerston North', '022 188 5240');

create trigger s4_business_updated_at before update on public.s4_business
    for each row execute function public.s4_set_updated_at();

-- ──────────────────────────────────────────────────────────── invoices ──

create type public.s4_invoice_status as enum ('draft', 'issued', 'void');

create sequence public.s4_invoice_number_seq;

create table public.s4_invoices (
    id               uuid primary key default gen_random_uuid(),
    number           integer unique,                       -- set when issued
    booking_id       uuid not null references public.s4_bookings (id) on delete restrict,
    status           public.s4_invoice_status not null default 'draft',
    issue_date       date,
    -- Snapshots taken when issued, so later edits never rewrite an invoice.
    client_name      text,
    client_email     text,
    client_phone     text,
    supplier_name    text,
    supplier_legal   text,
    supplier_gst     text,
    supplier_address text,
    supplier_phone   text,
    supplier_email   text,
    note             text,
    total_cents      integer not null default 0 check (total_cents >= 0),
    gst_cents        integer not null default 0 check (gst_cents >= 0),
    created_by       uuid references public.s4_staff (user_id) on delete set null,
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now(),
    issued_at        timestamptz,
    voided_at        timestamptz,
    void_reason      text check (char_length(void_reason) <= 300),
    check (status = 'draft' or (number is not null and issue_date is not null and supplier_gst is not null)),
    check (status <> 'void' or (voided_at is not null and void_reason is not null))
);
-- One live invoice per booking; a voided one can be replaced.
create unique index s4_invoices_booking_live_key on public.s4_invoices (booking_id) where status <> 'void';
create index s4_invoices_created_idx on public.s4_invoices (created_at desc);

create trigger s4_invoices_updated_at before update on public.s4_invoices
    for each row execute function public.s4_set_updated_at();

create table public.s4_invoice_lines (
    invoice_id    uuid not null references public.s4_invoices (id) on delete cascade,
    sort_order    smallint not null,
    description   text not null check (char_length(trim(description)) between 1 and 200),
    quantity      integer not null check (quantity between 1 and 99),
    unit_cents    integer not null check (unit_cents between -10000000 and 10000000),  -- GST-inclusive; negative = discount
    line_cents    integer not null,
    needs_review  boolean not null default false,  -- came from a "from $X" price
    primary key (invoice_id, sort_order),
    check (line_cents = quantity * unit_cents)
);

-- ─────────────────────────────────────────────────────── immutability ──

create function public.s4_invoice_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
    if tg_op = 'DELETE' then
        if old.status <> 'draft' then
            raise exception 'invoice_locked' using errcode = 'P0001';
        end if;
        return old;
    end if;
    if old.status = 'void' then
        raise exception 'invoice_locked' using errcode = 'P0001';
    end if;
    if old.status = 'issued' then
        -- The only change allowed to an issued invoice is voiding it.
        if new.status <> 'void'
           or (to_jsonb(new) - array['status', 'voided_at', 'void_reason', 'updated_at'])
              <> (to_jsonb(old) - array['status', 'voided_at', 'void_reason', 'updated_at']) then
            raise exception 'invoice_locked' using errcode = 'P0001';
        end if;
    end if;
    return new;
end;
$$;
create trigger s4_invoices_guard before update or delete on public.s4_invoices
    for each row execute function public.s4_invoice_guard();

create function public.s4_invoice_lines_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
    v_status public.s4_invoice_status;
begin
    select status into v_status from public.s4_invoices
     where id = case when tg_op = 'DELETE' then old.invoice_id else new.invoice_id end;
    -- A missing parent means the draft itself is being deleted (cascade).
    if found and v_status <> 'draft' then
        raise exception 'invoice_locked' using errcode = 'P0001';
    end if;
    return case when tg_op = 'DELETE' then old else new end;
end;
$$;
create trigger s4_invoice_lines_guard before insert or update or delete on public.s4_invoice_lines
    for each row execute function public.s4_invoice_lines_guard();

-- ─────────────────────────────────────────────────────────── functions ──

/** Recalculate a draft's totals from its lines. */
create function public.s4_invoice_recalc(p_invoice_id uuid) returns void
language sql volatile security definer set search_path = '' as $$
    update public.s4_invoices i
       set total_cents = t.total,
           gst_cents = round(t.total * 3 / 23.0)::integer
      from (select coalesce(sum(line_cents), 0)::integer as total
              from public.s4_invoice_lines where invoice_id = p_invoice_id) t
     where i.id = p_invoice_id and i.status = 'draft';
$$;

/** The live invoice for a completed booking, creating a prefilled draft if there is none. */
create function public.s4_invoice_draft(p_booking_id uuid) returns uuid
language plpgsql volatile security definer set search_path = '' as $$
declare
    v_status public.s4_booking_status;
    v_id uuid;
begin
    if not public.s4_is_staff() then
        raise exception 'not_staff' using errcode = '42501';
    end if;
    select status into v_status from public.s4_bookings where id = p_booking_id for update;
    if not found then
        raise exception 'not_found' using errcode = 'P0001';
    end if;
    select id into v_id from public.s4_invoices where booking_id = p_booking_id and status <> 'void';
    if found then
        return v_id;
    end if;
    if v_status <> 'completed' then
        raise exception 'not_completed' using errcode = 'P0001';
    end if;

    insert into public.s4_invoices (booking_id, created_by)
    values (p_booking_id, auth.uid())
    returning id into v_id;

    insert into public.s4_invoice_lines (invoice_id, sort_order, description, quantity, unit_cents, line_cents, needs_review)
    select v_id,
           (row_number() over (order by bi.sort_order, bi.name))::smallint,
           left(bi.name || case when bi.gold_card_applied then ' (Gold Card)' else '' end, 200),
           1, bi.price_cents, bi.price_cents, bi.price_is_from
      from public.s4_booking_items bi
     where bi.booking_id = p_booking_id;

    perform public.s4_invoice_recalc(v_id);
    return v_id;
end;
$$;

/** Replace a draft's lines: [{ description, quantity, unit_cents }]. */
create function public.s4_invoice_save(p_invoice_id uuid, p_lines jsonb) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare
    v_status public.s4_invoice_status;
begin
    if not public.s4_is_staff() then
        raise exception 'not_staff' using errcode = '42501';
    end if;
    select status into v_status from public.s4_invoices where id = p_invoice_id for update;
    if not found then
        raise exception 'not_found' using errcode = 'P0001';
    end if;
    if v_status <> 'draft' then
        raise exception 'invoice_locked' using errcode = 'P0001';
    end if;
    if jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) > 50 then
        raise exception 'invalid_lines' using errcode = 'P0001';
    end if;

    delete from public.s4_invoice_lines where invoice_id = p_invoice_id;
    begin
        insert into public.s4_invoice_lines (invoice_id, sort_order, description, quantity, unit_cents, line_cents, needs_review)
        select p_invoice_id, l.ord::smallint, trim(l.v ->> 'description'),
               (l.v ->> 'quantity')::integer, (l.v ->> 'unit_cents')::integer,
               (l.v ->> 'quantity')::integer * (l.v ->> 'unit_cents')::integer,
               coalesce((l.v ->> 'needs_review')::boolean, false)
          from jsonb_array_elements(p_lines) with ordinality as l(v, ord);
    exception when check_violation or not_null_violation or invalid_text_representation or numeric_value_out_of_range then
        raise exception 'invalid_lines' using errcode = 'P0001';
    end;

    perform public.s4_invoice_recalc(p_invoice_id);
    if (select total_cents < 0 from public.s4_invoices where id = p_invoice_id) then
        raise exception 'invalid_lines' using errcode = 'P0001';
    end if;
end;
$$;

/** Issue a draft: number it, snapshot the details, and lock it. Returns the number. */
create function public.s4_invoice_issue(p_invoice_id uuid) returns integer
language plpgsql volatile security definer set search_path = '' as $$
declare
    inv public.s4_invoices;
    b public.s4_business;
    c public.s4_clients;
    v_tz text;
    v_number integer;
    v_total integer;
begin
    if not public.s4_is_staff() then
        raise exception 'not_staff' using errcode = '42501';
    end if;
    select * into inv from public.s4_invoices where id = p_invoice_id for update;
    if not found then
        raise exception 'not_found' using errcode = 'P0001';
    end if;
    if inv.status <> 'draft' then
        raise exception 'invoice_locked' using errcode = 'P0001';
    end if;
    select * into b from public.s4_business where id;
    if not found or b.gst_number = '' or b.trading_name = '' then
        raise exception 'business_details_missing' using errcode = 'P0001';
    end if;
    if not exists (select 1 from public.s4_invoice_lines where invoice_id = p_invoice_id) then
        raise exception 'invalid_lines' using errcode = 'P0001';
    end if;
    -- Recalculate here too, in case the lines changed after the last save.
    select coalesce(sum(line_cents), 0) into v_total from public.s4_invoice_lines where invoice_id = p_invoice_id;
    if v_total < 0 then
        raise exception 'invalid_lines' using errcode = 'P0001';
    end if;

    select cl.* into c from public.s4_bookings bk join public.s4_clients cl on cl.id = bk.client_id
     where bk.id = inv.booking_id;
    select timezone into v_tz from public.s4_settings where id;
    v_number := nextval('public.s4_invoice_number_seq');

    update public.s4_invoices
       set status = 'issued',
           number = v_number,
           issue_date = (now() at time zone coalesce(v_tz, 'Pacific/Auckland'))::date,
           issued_at = now(),
           total_cents = v_total,
           gst_cents = round(v_total * 3 / 23.0)::integer,
           client_name = trim(coalesce(c.first_name, '') || ' ' || coalesce(c.last_name, '')),
           client_email = c.email::text,
           client_phone = c.phone_e164,
           supplier_name = b.trading_name,
           supplier_legal = nullif(b.legal_name, ''),
           supplier_gst = b.gst_number,
           supplier_address = nullif(b.address, ''),
           supplier_phone = nullif(b.phone, ''),
           supplier_email = nullif(b.email, ''),
           note = nullif(b.invoice_note, '')
     where id = p_invoice_id;
    return v_number;
end;
$$;

/** Void an issued invoice (it keeps its number); the booking can then be invoiced again. */
create function public.s4_invoice_void(p_invoice_id uuid, p_reason text) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare
    v_status public.s4_invoice_status;
begin
    if not public.s4_is_staff() then
        raise exception 'not_staff' using errcode = '42501';
    end if;
    if nullif(trim(coalesce(p_reason, '')), '') is null then
        raise exception 'reason_required' using errcode = 'P0001';
    end if;
    select status into v_status from public.s4_invoices where id = p_invoice_id for update;
    if not found then
        raise exception 'not_found' using errcode = 'P0001';
    end if;
    if v_status = 'draft' then
        -- Nothing was issued: just throw the draft away.
        delete from public.s4_invoices where id = p_invoice_id;
        return;
    end if;
    if v_status <> 'issued' then
        raise exception 'invoice_locked' using errcode = 'P0001';
    end if;
    update public.s4_invoices
       set status = 'void', voided_at = now(), void_reason = left(trim(p_reason), 300)
     where id = p_invoice_id;
end;
$$;

-- ───────────────────────────────────────────────────────── RLS + grants ──

alter table public.s4_business enable row level security;
alter table public.s4_invoices enable row level security;
alter table public.s4_invoice_lines enable row level security;

create policy "s4 staff read business" on public.s4_business for select to authenticated using (public.s4_is_staff());
create policy "s4 staff update business" on public.s4_business for update to authenticated
    using (public.s4_is_staff()) with check (public.s4_is_staff());
create policy "s4 staff read invoices" on public.s4_invoices for select to authenticated using (public.s4_is_staff());
create policy "s4 staff read invoice lines" on public.s4_invoice_lines for select to authenticated using (public.s4_is_staff());

revoke all on public.s4_business, public.s4_invoices, public.s4_invoice_lines from anon, authenticated;
revoke all on sequence public.s4_invoice_number_seq from anon, authenticated;
grant select on public.s4_business, public.s4_invoices, public.s4_invoice_lines to authenticated;
grant update (trading_name, legal_name, gst_number, address, phone, email, invoice_note) on public.s4_business to authenticated;

revoke execute on function public.s4_invoice_guard(), public.s4_invoice_lines_guard(),
    public.s4_invoice_recalc(uuid), public.s4_invoice_draft(uuid), public.s4_invoice_save(uuid, jsonb),
    public.s4_invoice_issue(uuid), public.s4_invoice_void(uuid, text) from public, anon, authenticated;
grant execute on function public.s4_invoice_draft(uuid), public.s4_invoice_save(uuid, jsonb),
    public.s4_invoice_issue(uuid), public.s4_invoice_void(uuid, text) to authenticated;
