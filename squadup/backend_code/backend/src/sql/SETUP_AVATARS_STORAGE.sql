-- Script para configurar o Supabase Storage para avatares de usuários
-- Execute este script no SQL Editor do Supabase Dashboard

-- PARTE 1: CONFIGURAÇÃO DO BUCKET
-- Esta parte você deve fazer MANUALMENTE no Dashboard do Supabase:
-- 1. Vá para Storage no painel lateral
-- 2. Clique em "Create Bucket"
-- 3. Nome: avatars
-- 4. Marque "Public bucket" como TRUE 
-- 5. Clique em "Save"

-- PARTE 2: CONFIGURAÇÃO DAS POLÍTICAS RLS
-- Execute o código abaixo no SQL Editor:

-- Verificar se RLS está habilitado (geralmente já está por padrão)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes se houver conflito
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Avatars are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;

-- 2. Política para permitir que usuários façam upload de seus próprios avatares
CREATE POLICY "Users can upload their own avatars" ON storage.objects 
FOR INSERT 
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.uid() IS NOT NULL 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Política para permitir que avatares sejam públicos para visualização
CREATE POLICY "Avatars are publicly viewable" ON storage.objects 
FOR SELECT 
USING (bucket_id = 'avatars');

-- 4. Política para permitir que usuários atualizem seus próprios avatares
CREATE POLICY "Users can update their own avatars" ON storage.objects 
FOR UPDATE 
USING (
  bucket_id = 'avatars' 
  AND auth.uid() IS NOT NULL 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 5. Política para permitir que usuários deletem seus próprios avatares
CREATE POLICY "Users can delete their own avatars" ON storage.objects 
FOR DELETE 
USING (
  bucket_id = 'avatars' 
  AND auth.uid() IS NOT NULL 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 6. (Opcional) Criar tabela para tracking de avatares se necessário
-- Esta tabela pode ser útil para manter histórico ou metadados adicionais
CREATE TABLE IF NOT EXISTS public.user_avatars (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Garantir que cada usuário tenha apenas um avatar ativo
  UNIQUE(user_id)
);

-- 7. Habilitar RLS na tabela de avatares
ALTER TABLE public.user_avatars ENABLE ROW LEVEL SECURITY;

-- 8. Políticas para a tabela user_avatars
CREATE POLICY "Users can view all avatars" ON public.user_avatars FOR SELECT USING (true);

CREATE POLICY "Users can insert their own avatar" ON public.user_avatars 
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own avatar" ON public.user_avatars 
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own avatar" ON public.user_avatars 
FOR DELETE USING (auth.uid() = user_id);

-- 9. Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_avatars_updated_at 
    BEFORE UPDATE ON public.user_avatars 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 10. Comentários para documentação
COMMENT ON TABLE public.user_avatars IS 'Tabela para armazenar metadados dos avatares dos usuários';
COMMENT ON COLUMN public.user_avatars.user_id IS 'ID do usuário proprietário do avatar';
COMMENT ON COLUMN public.user_avatars.file_path IS 'Caminho do arquivo no Supabase Storage';
COMMENT ON COLUMN public.user_avatars.file_url IS 'URL pública do avatar';
COMMENT ON COLUMN public.user_avatars.file_size IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN public.user_avatars.mime_type IS 'Tipo MIME do arquivo (image/jpeg, image/png, etc.)';