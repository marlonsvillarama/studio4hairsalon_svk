-- The shared "marlonslab" project had a trigger from another app that copied
-- every new auth user into public.fl_customers. Its function referenced the
-- table without a schema, and Supabase Auth runs with search_path = auth, so
-- the insert always failed and blocked ALL user creation ("Database error
-- creating new user"). The other app no longer needs it, so the trigger is
-- removed. The function public.handle_new_auth_user() is left in place.

drop trigger if exists on_auth_user_created on auth.users;
