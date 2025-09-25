-- SCRIPT SIMPLIFICADO PARA SUPABASE STORAGE - AVATARES
-- Execute este script no SQL Editor do Supabase Dashboard

-- IMPORTANTE: Primeiro crie o bucket MANUALMENTE no Dashboard:
-- 1. Vá para Storage > Create Bucket
-- 2. Nome: "avatars"  
-- 3. Marque "Public bucket" = TRUE
-- 4. Clique em Save

-- Depois execute este SQL:

-- Remover políticas existentes (se houver)
DROP POLICY IF EXISTS "avatar_upload_policy" ON storage.objects;
DROP POLICY IF EXISTS "avatar_select_policy" ON storage.objects;
DROP POLICY IF EXISTS "avatar_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "avatar_delete_policy" ON storage.objects;

-- Política para UPLOAD (INSERT)
CREATE POLICY "avatar_upload_policy" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid() IS NOT NULL AND
  (regexp_split_to_array(name, '/'))[1] = auth.uid()::text
);

-- Política para VISUALIZAR (SELECT) - público para todos
CREATE POLICY "avatar_select_policy" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

-- Política para ATUALIZAR (UPDATE)
CREATE POLICY "avatar_update_policy" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'avatars' AND
  auth.uid() IS NOT NULL AND
  (regexp_split_to_array(name, '/'))[1] = auth.uid()::text
);

-- Política para DELETAR (DELETE)
CREATE POLICY "avatar_delete_policy" ON storage.objects
FOR DELETE USING (
  bucket_id = 'avatars' AND
  auth.uid() IS NOT NULL AND
  (regexp_split_to_array(name, '/'))[1] = auth.uid()::text
);

-- Verificar se as políticas foram criadas
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%avatar%';