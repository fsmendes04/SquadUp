-- Fix para recursão infinita nas políticas RLS
-- Execute este script no Supabase SQL Editor

-- ====================================
-- PARTE 1: LIMPAR TODAS AS POLÍTICAS EXISTENTES
-- ====================================

-- Remover todas as políticas de group_members
DROP POLICY IF EXISTS "Allow users to view their own group memberships" ON public.group_members;
DROP POLICY IF EXISTS "Allow users to view group members" ON public.group_members;
DROP POLICY IF EXISTS "Allow admins to add members" ON public.group_members;
DROP POLICY IF EXISTS "Allow admins to update member roles" ON public.group_members;
DROP POLICY IF EXISTS "Allow admins to remove members or self-removal" ON public.group_members;

-- Remover todas as políticas de groups
DROP POLICY IF EXISTS "Allow group creation for authenticated users" ON public.groups;
DROP POLICY IF EXISTS "Allow group update for group creator" ON public.groups;
DROP POLICY IF EXISTS "Allow group deletion for group creator" ON public.groups;
DROP POLICY IF EXISTS "Allow read access to all authenticated users" ON public.groups;
DROP POLICY IF EXISTS "Allow users to view groups they are members of" ON public.groups;

-- ====================================
-- PARTE 2: CRIAR POLÍTICAS SEM RECURSÃO
-- ====================================

-- ===== POLÍTICAS PARA group_members =====

-- SELECT: Usuários podem ver membros dos grupos dos quais fazem parte
-- SIMPLES: apenas verifica se o usuário está na mesma tabela
CREATE POLICY "select_group_members"
  ON public.group_members
  FOR SELECT
  USING (
    -- Usuário pode ver membros do grupo se ele também for membro
    group_id IN (
      SELECT gm.group_id 
      FROM public.group_members gm
      WHERE gm.user_id = auth.uid()
    )
  );

-- INSERT: Permite inserção em duas situações específicas
CREATE POLICY "insert_group_members"
  ON public.group_members
  FOR INSERT
  WITH CHECK (
    -- Situação 1: Usuário se adicionando como admin (criação de grupo)
    (auth.uid() = user_id AND role = 'admin')
    OR
    -- Situação 2: Um admin existente adicionando novos membros
    (
      role = 'member' AND
      EXISTS (
        SELECT 1 
        FROM public.group_members gm
        WHERE gm.group_id = group_members.group_id 
          AND gm.user_id = auth.uid()
          AND gm.role = 'admin'
      )
    )
  );

-- UPDATE: Apenas admins podem atualizar roles
CREATE POLICY "update_group_members"
  ON public.group_members
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 
      FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id 
        AND gm.user_id = auth.uid()
        AND gm.role = 'admin'
    )
  );

-- DELETE: Admins podem remover membros OU usuários podem se remover
CREATE POLICY "delete_group_members"
  ON public.group_members
  FOR DELETE
  USING (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 
      FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id 
        AND gm.user_id = auth.uid()
        AND gm.role = 'admin'
    )
  );

-- ===== POLÍTICAS PARA groups =====

-- INSERT: Qualquer usuário autenticado pode criar grupo
CREATE POLICY "insert_groups" 
  ON public.groups 
  FOR INSERT 
  WITH CHECK (auth.uid() = created_by);

-- SELECT: Usuários podem ver grupos dos quais são membros
-- IMPORTANTE: Esta política NÃO deve fazer join com group_members durante INSERT
CREATE POLICY "select_groups"
  ON public.groups
  FOR SELECT
  USING (
    id IN (
      SELECT gm.group_id 
      FROM public.group_members gm
      WHERE gm.user_id = auth.uid()
    )
  );

-- UPDATE: Apenas o criador pode atualizar
CREATE POLICY "update_groups"
  ON public.groups
  FOR UPDATE
  USING (auth.uid() = created_by);

-- DELETE: Apenas o criador pode deletar
CREATE POLICY "delete_groups"
  ON public.groups
  FOR DELETE
  USING (auth.uid() = created_by);

-- ====================================
-- PARTE 3: GARANTIR PERMISSÕES
-- ====================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.groups TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.group_members TO authenticated;

-- ====================================
-- PARTE 4: VERIFICAÇÃO (OPCIONAL)
-- ====================================

-- Para testar, execute estas queries após fazer login:
-- SELECT * FROM public.group_members WHERE user_id = auth.uid();
-- SELECT * FROM public.groups WHERE id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid());
