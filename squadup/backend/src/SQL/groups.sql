-- Create the groups table
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  created_by uuid not null references profiles(id)
);
-- Enable Row Level Security
alter table public.groups enable row level security;
-- Policy: Allow the creator to insert a group
create policy "Allow group creation for authenticated users" on public.groups for
insert with check (auth.uid() = created_by);
-- Policy: Allow the creator to update their own groups
create policy "Allow group update for group creator" on public.groups for
update using (auth.uid() = created_by);
-- Policy: Allow the creator to delete their own groups
create policy "Allow group deletion for group creator" on public.groups for delete using (auth.uid() = created_by);
-- Policy: Allow all authenticated users to select (read) groups
create policy "Allow read access to all authenticated users" on public.groups for
select using (auth.role() = 'authenticated');