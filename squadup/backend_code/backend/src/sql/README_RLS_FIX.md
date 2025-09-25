# 🔧 Correção do Erro de Row Level Security (RLS) - Despesas

## ❌ Problema
Erro ao criar despesas: `new row violates row-level security policy for table "expenses"`

## 🎯 Causa
As políticas de Row Level Security (RLS) do Supabase estão impedindo a criação de despesas devido a problemas na configuração das políticas.

## ✅ Soluções

### 🚀 Solução Rápida (Para Testar)
1. Abra o **Supabase SQL Editor**
2. Execute o script: `DISABLE_EXPENSES_RLS_TEMP.sql`
3. Teste a criação de despesas na aplicação
4. **IMPORTANTE**: Esta solução desabilita completamente a segurança das tabelas

### 🔒 Solução Segura (Recomendada)
1. Abra o **Supabase SQL Editor**
2. Execute o script: `FIX_EXPENSES_RLS.sql`
3. Este script corrige as políticas RLS mantendo a segurança

## 📁 Scripts Disponíveis

### `DISABLE_EXPENSES_RLS_TEMP.sql`
- **Objetivo**: Desabilita temporariamente o RLS para testar
- **Uso**: Apenas para desenvolvimento/teste
- **Segurança**: ⚠️ Remove toda a proteção das tabelas

### `FIX_EXPENSES_RLS.sql`
- **Objetivo**: Corrige as políticas RLS mantendo a segurança
- **Uso**: Produção e desenvolvimento
- **Segurança**: ✅ Mantém a proteção adequada

## 🔍 Como Verificar se Funcionou

### Após executar os scripts, verifique:

```sql
-- Verificar políticas ativas
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE tablename IN ('expenses', 'expense_participants');

-- Verificar se RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('expenses', 'expense_participants');
```

## 🛠️ Depois de Resolver

1. Teste a criação de despesas na aplicação
2. Se usar a solução temporária, **reabilite o RLS**:
   ```sql
   ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
   ALTER TABLE expense_participants ENABLE ROW LEVEL SECURITY;
   ```
3. Execute `FIX_EXPENSES_RLS.sql` para configurar as políticas corretas

## 💡 Explicação Técnica

O problema ocorre porque:
1. As políticas RLS estão verificando se o usuário é membro do grupo
2. Mas a verificação pode estar falhando devido a problemas na estrutura das queries
3. Ou as tabelas `group_members` podem não ter os dados corretos

A solução corrige as políticas para usar subqueries mais simples e diretas.