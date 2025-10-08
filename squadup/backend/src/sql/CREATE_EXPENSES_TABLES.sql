-- ============================================
-- SCRIPT SQL PARA CRIAR TABELAS DE DESPESAS
-- Execute este script no Supabase SQL Editor
-- ============================================

-- Criar tabela de despesas
CREATE TABLE IF NOT EXISTS expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    payer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    expense_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

-- Criar tabela de participantes das despesas
CREATE TABLE IF NOT EXISTS expense_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount_owed DECIMAL(10,2) NOT NULL CHECK (amount_owed >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(expense_id, user_id)
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_expenses_group_id ON expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_payer_id ON expenses(payer_id);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_deleted_at ON expenses(deleted_at);
CREATE INDEX IF NOT EXISTS idx_expense_participants_expense_id ON expense_participants(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_participants_user_id ON expense_participants(user_id);

-- Criar trigger para atualizar updated_at na tabela expenses
CREATE TRIGGER update_expenses_updated_at 
    BEFORE UPDATE ON expenses 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- POLÍTICAS RLS (Row Level Security)
-- ============================================

-- Habilitar RLS nas tabelas
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_participants ENABLE ROW LEVEL SECURITY;

-- Políticas para tabela EXPENSES
-- Visualizar despesas (apenas membros do grupo podem ver)
CREATE POLICY "Group members can view expenses" ON expenses
    FOR SELECT USING (
        deleted_at IS NULL AND
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = expenses.group_id 
            AND user_id = auth.uid()
        )
    );

-- Criar despesas (apenas membros do grupo podem criar)
CREATE POLICY "Group members can create expenses" ON expenses
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = expenses.group_id 
            AND user_id = auth.uid()
        )
    );

-- Atualizar despesas (apenas membros do grupo podem atualizar)
CREATE POLICY "Group members can update expenses" ON expenses
    FOR UPDATE USING (
        deleted_at IS NULL AND
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = expenses.group_id 
            AND user_id = auth.uid()
        )
    );

-- Deletar despesas (soft delete - apenas membros do grupo)
CREATE POLICY "Group members can delete expenses" ON expenses
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = expenses.group_id 
            AND user_id = auth.uid()
        )
    );

-- Políticas para tabela EXPENSE_PARTICIPANTS
-- Visualizar participantes (membros do grupo podem ver)
CREATE POLICY "Group members can view expense participants" ON expense_participants
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM expenses e
            JOIN group_members gm ON gm.group_id = e.group_id
            WHERE e.id = expense_participants.expense_id 
            AND gm.user_id = auth.uid()
            AND e.deleted_at IS NULL
        )
    );

-- Criar participantes (apenas membros do grupo podem criar)
CREATE POLICY "Group members can create expense participants" ON expense_participants
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM expenses e
            JOIN group_members gm ON gm.group_id = e.group_id
            WHERE e.id = expense_participants.expense_id 
            AND gm.user_id = auth.uid()
            AND e.deleted_at IS NULL
        )
    );

-- Atualizar participantes (apenas membros do grupo podem atualizar)
CREATE POLICY "Group members can update expense participants" ON expense_participants
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM expenses e
            JOIN group_members gm ON gm.group_id = e.group_id
            WHERE e.id = expense_participants.expense_id 
            AND gm.user_id = auth.uid()
            AND e.deleted_at IS NULL
        )
    );

-- Deletar participantes (apenas membros do grupo podem deletar)
CREATE POLICY "Group members can delete expense participants" ON expense_participants
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM expenses e
            JOIN group_members gm ON gm.group_id = e.group_id
            WHERE e.id = expense_participants.expense_id 
            AND gm.user_id = auth.uid()
            AND e.deleted_at IS NULL
        )
    );

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

-- Função para calcular o total de despesas de um grupo
CREATE OR REPLACE FUNCTION get_group_expenses_total(group_uuid UUID)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(amount), 0)
        FROM expenses
        WHERE group_id = group_uuid AND deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para calcular quanto um usuário deve em um grupo
CREATE OR REPLACE FUNCTION get_user_debt_in_group(user_uuid UUID, group_uuid UUID)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(ep.amount_owed), 0)
        FROM expense_participants ep
        JOIN expenses e ON e.id = ep.expense_id
        WHERE ep.user_id = user_uuid 
        AND e.group_id = group_uuid 
        AND e.deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para calcular quanto um usuário pagou em um grupo
CREATE OR REPLACE FUNCTION get_user_payments_in_group(user_uuid UUID, group_uuid UUID)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(amount), 0)
        FROM expenses
        WHERE payer_id = user_uuid 
        AND group_id = group_uuid 
        AND deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;