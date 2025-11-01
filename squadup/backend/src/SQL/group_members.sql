-- Criar a tabela group_members
create table public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('admin', 'member')),
  joined_at timestamptz not null default now(),
  unique(group_id, user_id)
);

-- Criar índices para melhor performance
create index idx_group_members_group_id on public.group_members(group_id);
create index idx_group_members_user_id on public.group_members(user_id);
create index idx_group_members_role on public.group_members(role);

-- IMPORTANTE: Dar permissões básicas à role authenticated
grant select, insert, update, delete on public.group_members to authenticated;

-- Ativar Row Level Security
alter table public.group_members enable row level security;

-- Policy: Permitir usuários verem suas próprias associações de grupo
create policy "Allow users to view their own group memberships"
  on public.group_members
  for select
  using (
    auth.uid() = user_id
  );

-- Policy: Permitir inserção de membros (criador como admin E admins adicionando membros)
create policy "Allow admins to add members"
  on public.group_members
  for insert
  with check (
    -- Permite usuários se adicionarem como admin (criação de grupo)
    (auth.uid() = user_id and role = 'admin')
    or
    -- Permite admins existentes adicionarem novos membros
    exists (
      select 1 
      from public.group_members 
      where group_id = group_members.group_id 
        and user_id = auth.uid()
        and role = 'admin'
    )
  );

-- Policy: Permitir admins atualizarem roles de membros
create policy "Allow admins to update member roles"
  on public.group_members
  for update
  using (
    exists (
      select 1 
      from public.group_members 
      where group_id = group_members.group_id 
        and user_id = auth.uid()
        and role = 'admin'
    )
  );

-- Policy: Permitir admins removerem membros OU usuários se removerem
create policy "Allow admins to remove members or self-removal"
  on public.group_members
  for delete
  using (
    exists (
      select 1 
      from public.group_members 
      where group_id = group_members.group_id 
        and user_id = auth.uid()
        and role = 'admin'
    )
    or auth.uid() = user_id
  );

  -- Fix para políticas RLS de groups e group_members
-- Execute este script no Supabase SQL Editor

-- 1. Remover políticas existentes problemáticas
DROP POLICY IF EXISTS "Allow admins to add members" ON public.group_members;

-- 2. Recriar política de inserção com aliases corretos
CREATE POLICY "Allow admins to add members"
  ON public.group_members
  FOR INSERT
  WITH CHECK (
    -- Permite usuários se adicionarem como admin (criação de grupo)
    (auth.uid() = user_id AND role = 'admin')
    OR
    -- Permite admins existentes adicionarem novos membros
    EXISTS (
      SELECT 1 
      FROM public.group_members AS existing_members
      WHERE existing_members.group_id = group_members.group_id 
        AND existing_members.user_id = auth.uid()
        AND existing_members.role = 'admin'
    )
  );

-- 3. Verificar se a policy de insert na tabela groups está correta
-- Se necessário, recriar:
DROP POLICY IF EXISTS "Allow group creation for authenticated users" ON public.groups;

CREATE POLICY "Allow group creation for authenticated users" 
  ON public.groups 
  FOR INSERT 
  WITH CHECK (auth.uid() = created_by);

-- 4. Garantir grants estão corretos
GRANT SELECT, INSERT, UPDATE, DELETE ON public.groups TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.group_members TO authenticated;

-- 5. Verificar se existem conflitos com outras policies de SELECT
-- Remover policy duplicada se existir
DROP POLICY IF EXISTS "Allow read access to all authenticated users" ON public.groups;

-- 6. Manter apenas a policy que permite ver grupos dos quais é membro
-- Esta já deveria existir, mas vamos garantir:

CREATE POLICY "Allow users to view groups they are members of"
  ON public.groups
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 
      FROM public.group_members 
      WHERE group_members.group_id = groups.id 
        AND group_members.user_id = auth.uid()
    )
  );

-- 7. Verificar policy de visualização de membros

CREATE POLICY "Allow users to view group members"
  ON public.group_members
  FOR SELECT
  USING (
    -- Usuários podem ver membros dos grupos dos quais fazem parte
    EXISTS (
      SELECT 1 
      FROM public.group_members AS my_memberships
      WHERE my_memberships.group_id = group_members.group_id 
        AND my_memberships.user_id = auth.uid()
    )
  );
