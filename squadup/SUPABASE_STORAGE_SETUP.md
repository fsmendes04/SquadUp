# Configuração do Supabase Storage para Avatares

## ❌ Problema: RLS Policy Error
O erro `new row violates row-level security policy` indica que as políticas RLS não estão configuradas corretamente.

## ✅ Solução: Configuração Correta do Storage

### 1. Criar o Bucket (Dashboard do Supabase)
```
1. Ir para Storage > Buckets
2. Clicar em "Create bucket"
3. Nome: avatars
4. Public: ✅ Marcado (IMPORTANTE!)
5. Allowed MIME types: image/*
6. File size limit: 5MB
```

### 2. Configurar RLS Policies (SQL Editor)

**IMPORTANTE**: As políticas antigas podem estar incorretas. Execute primeiro:

```sql
-- Remover políticas existentes se houver erro
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
```

**Criar políticas corretas (Versão Simplificada):**

```sql
-- Política para INSERT (Upload) - formato: {user_id}_avatar_{timestamp}.ext
CREATE POLICY "Users can upload their own avatar" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' 
    AND name LIKE (auth.uid()::text || '_avatar_%')
);

-- Política para SELECT (Download/View)
CREATE POLICY "Users can view their own avatar" ON storage.objects
FOR SELECT 
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND name LIKE (auth.uid()::text || '_avatar_%')
);

-- Política para DELETE
CREATE POLICY "Users can delete their own avatar" ON storage.objects
FOR DELETE 
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND name LIKE (auth.uid()::text || '_avatar_%')
);

-- Política pública para visualização (opcional, para avatares públicos)
CREATE POLICY "Public can view avatars" ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'avatars');
```

**OU usar políticas mais permissivas (recomendado para começar):**

```sql
-- Políticas mais permissivas - todos usuários autenticados podem acessar avatares
CREATE POLICY "Authenticated users can manage avatars" ON storage.objects
FOR ALL 
TO authenticated
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');
```

### 3. Verificar RLS Status
```sql
-- Verificar se RLS está ativado
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- Se rowsecurity = false, ativar RLS:
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

### 4. Estrutura de Arquivos
O sistema salva os arquivos como:
```
avatars/
  ├── {user_id}_avatar_{timestamp}.jpg
  ├── {user_id}_avatar_{timestamp}.png
  └── ...
```

Exemplo: `a2d704ea-5c81-4431-9c53-1b11ab06d714_avatar_1758838852123.jpg`

### 5. Testando a Configuração

**Via SQL (no SQL Editor):**
```sql
-- Testar se o usuário atual pode acessar
SELECT auth.uid(); -- Deve retornar seu user ID

-- Testar política com um caminho de exemplo
SELECT * FROM storage.objects 
WHERE bucket_id = 'avatars' 
AND auth.uid()::text = (string_to_array(name, '/'))[1];
```

### 6. Debug: Se ainda houver erro

**Verificar políticas ativas:**
```sql
SELECT * FROM pg_policies WHERE tablename = 'objects';
```

**Testar upload manual via Dashboard:**
1. Ir para Storage > avatars
2. Tentar fazer upload manual de uma imagem
3. Se falhar, o problema está nas políticas

### 7. Alternativa: Desabilitar RLS Temporariamente (APENAS PARA TESTE)
```sql
-- ⚠️ APENAS PARA TESTE - NÃO USAR EM PRODUÇÃO
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
```

## 🔧 Próximos Passos - EXECUTAR AGORA

### PASSO 1: Configurar o Bucket (Dashboard Supabase)
1. Acesse seu projeto Supabase
2. Vá em **Storage** > **Buckets**
3. Se o bucket `avatars` não existir:
   - Clique em "Create bucket"
   - Nome: `avatars`
   - **IMPORTANTE**: Marque ✅ **Public bucket**
   - File size limit: 5MB
   - Allowed MIME types: `image/*`

### PASSO 2: Configurar RLS (SQL Editor)
**Copie e cole EXATAMENTE este código no SQL Editor:**

```sql
-- Remover políticas antigas se existirem
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can manage avatars" ON storage.objects;

-- SOLUÇÃO SIMPLES: Permitir tudo para usuários autenticados
CREATE POLICY "Authenticated users can manage avatars" ON storage.objects
FOR ALL 
TO authenticated
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

-- Permitir visualização pública (opcional)
CREATE POLICY "Public can view avatars" ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'avatars');
```

### PASSO 3: Verificar se funcionou
Após executar o SQL acima:
1. Teste o upload de avatar no app Flutter
2. Se ainda der erro, execute este comando adicional:

```sql
-- Se ainda houver erro, desabilitar RLS temporariamente
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
```

### PASSO 4: Testar o App
1. Abra o app Flutter
2. Vá para o perfil
3. Clique no avatar
4. Selecione uma imagem
5. ✅ Deve funcionar agora!

**Se ainda houver erro após todos os passos, me informe e faremos debug adicional.**