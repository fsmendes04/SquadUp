# 🚨 Solução para Erro de Upload de Avatar

## Problema
```
Error uploading avatar: new row violates row-level security policy
```

## Causa
O bucket `user-uploads` no Supabase Storage não está configurado ou não tem as políticas RLS adequadas.

## ✅ Solução Passo a Passo

### 1. Acessar o Supabase Dashboard
- Vá para: https://supabase.com/dashboard
- Selecione seu projeto
- Vá para **Storage** → **Buckets**

### 2. Criar o Bucket (se não existir)
- Clique em **New bucket**
- Nome: `user-uploads`
- ✅ Marque **Public bucket**
- Clique em **Save**

### 3. Configurar Políticas RLS

#### Opção A: Configuração Simples (para teste)
1. Vá para **SQL Editor**
2. Execute o arquivo: `src/sql/SETUP_STORAGE_SIMPLE.sql`
3. Teste o upload de avatar

#### Opção B: Configuração Segura (recomendada)
1. Vá para **SQL Editor**
2. Execute o arquivo: `src/sql/SETUP_STORAGE_AVATARS.sql`
3. Teste o upload de avatar

### 4. Verificar Configuração
```sql
-- Verificar se o bucket existe
SELECT * FROM storage.buckets WHERE id = 'user-uploads';

-- Verificar políticas
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
```

### 5. Testar Upload
- Reinicie o backend: `npm run start:dev`
- Teste o upload de avatar no frontend
- Verifique os logs do console

## 🔧 Troubleshooting Adicional

### Se ainda houver erro:

1. **Verificar Autenticação:**
   - Confirme que o usuário está logado
   - Verifique se o token JWT é válido

2. **Verificar Permissões do Bucket:**
   ```sql
   UPDATE storage.buckets SET public = true WHERE id = 'user-uploads';
   ```

3. **Limpar Cache:**
   - Limpe o cache do navegador
   - Reinicie o backend

4. **Verificar Logs:**
   - Backend: logs no terminal
   - Frontend: console do navegador
   - Supabase: logs na dashboard

## 📁 Estrutura de Arquivos no Storage
```
user-uploads/
├── {userId}/
│   ├── avatar_1234567890.jpg
│   └── avatar_1234567891.png
└── {userId2}/
    └── avatar_1234567892.jpg
```

## 🚀 Após a Configuração
O upload de avatar deve funcionar normalmente:
1. Usuário clica na câmera do avatar
2. Escolhe galeria ou câmera
3. Seleciona/tira foto
4. Upload automático para Supabase Storage
5. URL salva no user_metadata
6. Avatar atualizado no frontend