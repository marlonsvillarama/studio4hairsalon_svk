-- Invoice list for the admin (2026-11-28): the invoice plus the columns the
-- Tax invoices table shows and searches, so it can be paged in the database.
-- security_invoker: the existing staff-only rules on invoices, bookings and
-- clients apply to whoever reads it.

create view public.s4_invoice_list with (security_invoker = on) as
select i.id, i.number, i.status, i.issue_date, i.total_cents, i.gst_cents, i.created_at,
       case when i.number is null then 'Draft' else 'INV-' || lpad(i.number::text, 4, '0') end as number_text,
       coalesce(nullif(trim(i.client_name), ''),
                nullif(trim(coalesce(c.first_name, '') || ' ' || coalesce(c.last_name, '')), ''),
                'Client') as display_name,
       b.reference as booking_reference,
       b.starts_at as visit_at
  from public.s4_invoices i
  left join public.s4_bookings b on b.id = i.booking_id
  left join public.s4_clients c on c.id = b.client_id;

revoke all on public.s4_invoice_list from public, anon, authenticated;
grant select on public.s4_invoice_list to authenticated;
