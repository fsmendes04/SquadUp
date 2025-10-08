-- ============================================
-- SCRIPT PARA CORRIGIR RECURSÃO INFINITA NAS POLÍTICAS RLS
-- Execute este script no Supabase SQL Editor
-- ============================================

-- PRIMEIRO: Remover todas as políticas existentes
DROP POLICY IF EXISTS "Users can view all groups" ON groups;
DROP POLICY IF EXISTS "Users can create groups" ON groups;
DROP POLICY IF EXISTS "Users can update their own groups" ON groups;
DROP POLICY IF EXISTS "Users can delete their own groups" ON groups;
DROP POLICY IF EXISTS "Group members can view group members" ON group_members;
DROP POLICY IF EXISTS "Group admins can add members" ON group_members;
DROP POLICY IF EXISTS "Group admins can remove members or users can remove themselves" ON group_members;
DROP POLICY IF EXISTS "Group admins can update member roles" ON group_members;

-- ============================================
-- POLÍTICAS CORRIGIDAS SEM RECURSÃO
-- ============================================

-- POLÍTICAS PARA TABELA GROUPS (sem alterações)
CREATE POLICY "Users can view all groups" ON groups
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can create groups" ON groups
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own groups" ON groups
    FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY "Users can delete their own groups" ON groups
    FOR DELETE USING (created_by = auth.uid());

-- POLÍTICAS CORRIGIDAS PARA TABELA GROUP_MEMBERS
-- Política simplificada: membros podem ver outros membros do mesmo grupo
CREATE POLICY "Group members can view members" ON group_members
    FOR SELECT USING (
        user_id = auth.uid() OR
        group_id IN (
            SELECT group_id FROM group_members WHERE user_id = auth.uid()
        )
    );

-- Política para adicionar membros: apenas admins podem adicionar
CREATE POLICY "Group admins can add members" ON group_members
    FOR INSERT WITH CHECK (
        -- Verifica se o usuário que está inserindo é admin do grupo
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Política para remover membros: admins podem remover qualquer um, usuários podem se remover
CREATE POLICY "Members can be removed by admins or themselves" ON group_members
    FOR DELETE USING (
        user_id = auth.uid() OR  -- Usuário pode se remover
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Política para atualizar membros: apenas admins podem alterar roles
CREATE POLICY "Group admins can update member roles" ON group_members
    FOR UPDATE USING (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- VERIFICAR SE AS POLÍTICAS FORAM APLICADAS
-- ============================================

-- Listar todas as políticas das tabelas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('groups', 'group_members')
ORDER BY tablename, policyname;