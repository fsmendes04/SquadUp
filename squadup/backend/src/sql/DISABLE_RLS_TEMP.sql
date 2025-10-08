-- ============================================
-- SOLUÇÃO DRÁSTICA: DESABILITAR RLS TEMPORARIAMENTE
-- Execute este script no Supabase SQL Editor
-- ============================================

-- DESABILITAR RLS nas tabelas (temporariamente para testar)
ALTER TABLE groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_members DISABLE ROW LEVEL SECURITY;

-- REMOVER TODAS AS POLÍTICAS EXISTENTES (garantir remoção completa)
DROP POLICY IF EXISTS "Users can view all groups" ON groups;
DROP POLICY IF EXISTS "Users can create groups" ON groups;
DROP POLICY IF EXISTS "Users can update their own groups" ON groups;
DROP POLICY IF EXISTS "Users can delete their own groups" ON groups;
DROP POLICY IF EXISTS "Group members can view group members" ON group_members;
DROP POLICY IF EXISTS "Group members can view members" ON group_members;
DROP POLICY IF EXISTS "Group admins can add members" ON group_members;
DROP POLICY IF EXISTS "Group admins can remove members or users can remove themselves" ON group_members;
DROP POLICY IF EXISTS "Members can be removed by admins or themselves" ON group_members;
DROP POLICY IF EXISTS "Group admins can update member roles" ON group_members;

-- Verificar se ainda existem políticas
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE tablename IN ('groups', 'group_members')
ORDER BY tablename, policyname;

-- Se a query acima não retornar nenhuma linha, está tudo limpo!