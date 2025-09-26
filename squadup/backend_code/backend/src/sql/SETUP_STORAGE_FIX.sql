-- Script Simples e Seguro para Configurar Storage de Avatares
-- Execute este SQL no Supabase SQL Editor

-- 1. Criar o bucket se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-uploads', 'user-uploads', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Limpar todas as políticas existentes para este bucket
DELETE FROM storage.policies WHERE bucket_id = 'user-uploads';

-- OU se preferir usar DROP (escolha uma das opções):
-- DROP POLICY IF EXISTS "Users can upload avatar files" ON storage.objects;
-- DROP POLICY IF EXISTS "Public can view avatar files" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can update their own avatar files" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can delete their own avatar files" ON storage.objects;

-- 3. Criar política simples de acesso público (TEMPORÁRIO PARA TESTE)
CREATE POLICY "avatar_public_access" ON storage.objects
FOR ALL 
TO public
USING (bucket_id = 'user-uploads');

-- 4. Verificar se funcionou
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
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 5. Verificar bucket
SELECT * FROM storage.buckets WHERE id = 'user-uploads';