-- ============================================
-- SCRIPT PARA CORRIGIR POLÍTICAS RLS DAS DESPESAS
-- Execute este script no Supabase SQL Editor
-- ============================================

-- PRIMEIRO: Remover todas as políticas existentes das tabelas de despesas
DROP POLICY IF EXISTS "Group members can view expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can create expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can update expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can delete expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can view expense participants" ON expense_participants;
DROP POLICY IF EXISTS "Group members can create expense participants" ON expense_participants;
DROP POLICY IF EXISTS "Group members can update expense participants" ON expense_participants;
DROP POLICY IF EXISTS "Group members can delete expense participants" ON expense_participants;

-- ============================================
-- POLÍTICAS CORRIGIDAS SEM RECURSÃO - EXPENSES
-- ============================================

-- Visualizar despesas (apenas membros do grupo podem ver)
CREATE POLICY "Group members can view expenses" ON expenses
    FOR SELECT USING (
        deleted_at IS NULL AND
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid()
        )
    );

-- Criar despesas (apenas membros do grupo podem criar)
CREATE POLICY "Group members can create expenses" ON expenses
    FOR INSERT WITH CHECK (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid()
        )
    );

-- Atualizar despesas (apenas membros do grupo podem atualizar)
CREATE POLICY "Group members can update expenses" ON expenses
    FOR UPDATE USING (
        deleted_at IS NULL AND
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid()
        )
    );

-- Deletar despesas (soft delete - apenas membros do grupo)
CREATE POLICY "Group members can delete expenses" ON expenses
    FOR UPDATE USING (
        group_id IN (
            SELECT group_id FROM group_members 
            WHERE user_id = auth.uid()
        )
    );

-- ============================================
-- POLÍTICAS CORRIGIDAS - EXPENSE_PARTICIPANTS  
-- ============================================

-- Visualizar participantes (membros do grupo podem ver)
CREATE POLICY "Group members can view expense participants" ON expense_participants
    FOR SELECT USING (
        expense_id IN (
            SELECT e.id FROM expenses e
            WHERE e.group_id IN (
                SELECT group_id FROM group_members 
                WHERE user_id = auth.uid()
            )
            AND e.deleted_at IS NULL
        )
    );

-- Criar participantes (apenas membros do grupo podem criar)
CREATE POLICY "Group members can create expense participants" ON expense_participants
    FOR INSERT WITH CHECK (
        expense_id IN (
            SELECT e.id FROM expenses e
            WHERE e.group_id IN (
                SELECT group_id FROM group_members 
                WHERE user_id = auth.uid()
            )
            AND e.deleted_at IS NULL
        )
    );

-- Atualizar participantes (apenas membros do grupo podem atualizar)
CREATE POLICY "Group members can update expense participants" ON expense_participants
    FOR UPDATE USING (
        expense_id IN (
            SELECT e.id FROM expenses e
            WHERE e.group_id IN (
                SELECT group_id FROM group_members 
                WHERE user_id = auth.uid()
            )
            AND e.deleted_at IS NULL
        )
    );

-- Deletar participantes (apenas membros do grupo podem deletar)
CREATE POLICY "Group members can delete expense participants" ON expense_participants
    FOR DELETE USING (
        expense_id IN (
            SELECT e.id FROM expenses e
            WHERE e.group_id IN (
                SELECT group_id FROM group_members 
                WHERE user_id = auth.uid()
            )
            AND e.deleted_at IS NULL
        )
    );

-- ============================================
-- VERIFICAR SE AS POLÍTICAS FORAM APLICADAS
-- ============================================

-- Listar todas as políticas das tabelas de despesas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('expenses', 'expense_participants')
ORDER BY tablename, policyname;

-- Verificar se o RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('expenses', 'expense_participants');