-- Import of the old system's appointments (2026-11-28). They often overlap,
-- so the overlap check is skipped when an imported row is inserted; new
-- bookings (online, staff, and later edits) are still checked in full.

alter table public.s4_bookings add column legacy_id text unique;   -- id in the old (DynamoDB) system

create or replace function public.s4_bookings_check_overlap() returns trigger
language plpgsql volatile security definer set search_path = '' as $$
declare
    v_span tstzrange;
    v_hands tstzmultirange;
begin
    if new.status <> 'confirmed' then
        return new;
    end if;
    -- Appointments imported from the old system went in as they were booked,
    -- overlaps and all. They still count as busy for every other booking, and
    -- are checked like any other once changed.
    if tg_op = 'INSERT' and new.source = 'import' then
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
