-- Criar tabela de grupos
CREATE TABLE IF NOT EXISTS groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Criar tabela de membros dos grupos
CREATE TABLE IF NOT EXISTS group_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    UNIQUE(group_id, user_id)
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_groups_created_by ON groups(created_by);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_groups_created_at ON groups(created_at);

-- Criar função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Criar trigger para atualizar updated_at na tabela groups
CREATE TRIGGER update_groups_updated_at 
    BEFORE UPDATE ON groups 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Políticas RLS (Row Level Security) para grupos
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Política para visualizar grupos (qualquer usuário autenticado pode ver grupos)
CREATE POLICY "Users can view all groups" ON groups
    FOR SELECT USING (auth.role() = 'authenticated');

-- Política para criar grupos (qualquer usuário autenticado pode criar)
CREATE POLICY "Users can create groups" ON groups
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Política para atualizar grupos (apenas o criador ou admins do grupo)
CREATE POLICY "Users can update their own groups" ON groups
    FOR UPDATE USING (
        created_by = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = groups.id 
            AND user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Política para deletar grupos (apenas o criador)
CREATE POLICY "Users can delete their own groups" ON groups
    FOR DELETE USING (created_by = auth.uid());

-- Políticas para group_members
-- Visualizar membros (membros do grupo podem ver outros membros)
CREATE POLICY "Group members can view group members" ON group_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM group_members gm 
            WHERE gm.group_id = group_members.group_id 
            AND gm.user_id = auth.uid()
        )
    );

-- Adicionar membros (apenas admins do grupo)
CREATE POLICY "Group admins can add members" ON group_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_members.group_id 
            AND user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Remover membros (admins podem remover qualquer membro, usuários podem se remover)
CREATE POLICY "Group admins can remove members or users can remove themselves" ON group_members
    FOR DELETE USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_members.group_id 
            AND user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Atualizar membros (apenas admins podem mudar roles)
CREATE POLICY "Group admins can update member roles" ON group_members
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = group_members.group_id 
            AND user_id = auth.uid() 
            AND role = 'admin'
        )
    );