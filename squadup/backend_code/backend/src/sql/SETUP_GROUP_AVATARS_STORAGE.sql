-- Configuração do Storage para Avatares de Grupos no Supabase
-- Execute este SQL no Supabase SQL Editor

-- 1. Criar o bucket 'group-avatars' se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('group-avatars', 'group-avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Remover políticas existentes se existirem
DROP POLICY IF EXISTS "Group avatars can be uploaded by authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Public can view group avatars" ON storage.objects;
DROP POLICY IF EXISTS "Group avatars can be updated by authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Group avatars can be deleted by authenticated users" ON storage.objects;

-- 3. Criar política para permitir upload de avatares de grupos (usuários autenticados)
CREATE POLICY "Group avatars can be uploaded by authenticated users" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'group-avatars' 
    AND auth.uid() IS NOT NULL
);

-- 4. Criar política para permitir visualização pública dos avatares de grupos
CREATE POLICY "Public can view group avatars" ON storage.objects
FOR SELECT USING (bucket_id = 'group-avatars');

-- 5. Criar política para permitir atualização dos avatares de grupos
CREATE POLICY "Group avatars can be updated by authenticated users" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'group-avatars' 
    AND auth.uid() IS NOT NULL
);

-- 6. Criar política para permitir deletar avatares de grupos
CREATE POLICY "Group avatars can be deleted by authenticated users" ON storage.objects
FOR DELETE USING (
    bucket_id = 'group-avatars' 
    AND auth.uid() IS NOT NULL
);

-- Verificar se as políticas foram criadas
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

-- Verificar se o bucket foi criado
SELECT * FROM storage.buckets WHERE id = 'group-avatars';