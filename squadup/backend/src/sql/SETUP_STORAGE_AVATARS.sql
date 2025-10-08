-- Configuração do Storage para Avatares no Supabase
-- Execute este SQL no Supabase SQL Editor

-- 1. Criar o bucket 'user-uploads' se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-uploads', 'user-uploads', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Remover políticas existentes se existirem
DROP POLICY IF EXISTS "Users can upload avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Public can view avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar files" ON storage.objects;

-- 3. Criar política para permitir upload de avatares (usuários podem fazer upload de seus próprios arquivos)
CREATE POLICY "Users can upload avatar files" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'user-uploads' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 4. Criar política para permitir visualização pública dos avatares
CREATE POLICY "Public can view avatar files" ON storage.objects
FOR SELECT USING (bucket_id = 'user-uploads');

-- 5. Criar política para permitir atualização dos próprios avatares
CREATE POLICY "Users can update their own avatar files" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'user-uploads' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 6. Criar política para permitir deletar os próprios avatares
CREATE POLICY "Users can delete their own avatar files" ON storage.objects
FOR DELETE USING (
    bucket_id = 'user-uploads' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Verificar se as políticas foram criadas
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';