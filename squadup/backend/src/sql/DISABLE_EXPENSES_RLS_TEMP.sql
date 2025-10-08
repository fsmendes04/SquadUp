-- ============================================
-- SOLUÇÃO TEMPORÁRIA: DESABILITAR RLS DAS DESPESAS
-- Execute este script no Supabase SQL Editor APENAS PARA TESTAR
-- ============================================

-- DESABILITAR RLS nas tabelas de despesas (temporariamente para testar)
ALTER TABLE expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE expense_participants DISABLE ROW LEVEL SECURITY;

-- REMOVER TODAS AS POLÍTICAS EXISTENTES (garantir remoção completa)
DROP POLICY IF EXISTS "Group members can view expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can create expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can update expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can delete expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can view expense participants" ON expense_participants;
DROP POLICY IF EXISTS "Group members can create expense participants" ON expense_participants;
DROP POLICY IF EXISTS "Group members can update expense participants" ON expense_participants;
DROP POLICY IF EXISTS "Group members can delete expense participants" ON expense_participants;

-- Verificar se ainda existem políticas
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE tablename IN ('expenses', 'expense_participants')
ORDER BY tablename, policyname;

-- Verificar se o RLS foi desabilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('expenses', 'expense_participants');

-- Se as querys acima não retornarem políticas e rowsecurity = false, está tudo desabilitado!

-- ============================================
-- IMPORTANTE: LEMBRE-SE DE REABILITAR O RLS DEPOIS!
-- ============================================
-- Para reabilitar, execute:
-- ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE expense_participants ENABLE ROW LEVEL SECURITY;
-- E depois execute o arquivo FIX_EXPENSES_RLS.sql