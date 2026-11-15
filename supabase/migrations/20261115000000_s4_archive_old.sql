-- Move the original Studio 4 tables (created January 2026) out of the public
-- API before the new booking schema replaces them.
--
-- They are copied, not just renamed, into a private `s4_archive` schema that
-- PostgREST does not expose and that anon/authenticated cannot read. This
-- also ends the public exposure of s4_appointments (client names, emails and
-- phone numbers were readable with the publishable key).
--
-- 20261115000200_s4_import.sql then rebuilds the catalogue and booking
-- history from these copies. The archive can be dropped once verified.

create schema if not exists s4_archive;
revoke all on schema s4_archive from public, anon, authenticated;

create table s4_archive.s4_categories_20261115   as select * from public.s4_categories;
create table s4_archive.s4_services_20261115     as select * from public.s4_services;
create table s4_archive.s4_clients_20261115      as select * from public.s4_clients;
create table s4_archive.s4_appointments_20261115 as select * from public.s4_appointments;

revoke all on all tables in schema s4_archive from public, anon, authenticated;

-- No CASCADE: if anything outside these four tables depends on them, the
-- migration stops here instead of silently dropping it.
drop table public.s4_appointments;
drop table public.s4_clients;
drop table public.s4_services;
drop table public.s4_categories;
