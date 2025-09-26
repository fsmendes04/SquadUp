-- Versão Simples - Configuração do Storage para Avatares
-- Execute este SQL no Supabase SQL Editor

-- 1. Criar o bucket 'user-uploads' se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-uploads', 'user-uploads', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Remover todas as políticas existentes para este bucket (se houver)
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Public can view avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar files" ON storage.objects;

-- 3. Criar política simples para acesso público (TEMPORÁRIO PARA TESTE)
CREATE POLICY "Public Access" ON storage.objects
FOR ALL USING (bucket_id = 'user-uploads');

-- IMPORTANTE: Esta política permite acesso público total ao bucket.
-- Após testar, substitua por políticas mais restritivas usando o arquivo SETUP_STORAGE_AVATARS.sql