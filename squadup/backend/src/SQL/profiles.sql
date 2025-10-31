-- 1. Create table profiles
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);
-- 2. Trigger for auto-create profile on new user
create or replace function public.handle_new_user() returns trigger as $$ begin
insert into public.profiles (id)
values (new.id);
return new;
end;
$$ language plpgsql security definer;
create trigger on_auth_user_created
after
insert on auth.users for each row execute procedure public.handle_new_user();
-- 3. Enable Row Level Security
alter table public.profiles enable row level security;
-- 4. Each user can only access their own profile
create policy "Users can view their own profile" on public.profiles for
select using (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles for
update using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users can insert their own profile" on public.profiles for
insert with check (auth.uid() = id);