# Guia de Instalação - Módulo de Despesas

Este guia explica como configurar o módulo de despesas no seu projeto SquadUp.

## 1. Estrutura Criada

O módulo de despesas foi criado com a seguinte estrutura:

```
src/expenses/
├── dto/
│   ├── create-expense.dto.ts
│   ├── update-expense.dto.ts
│   └── filter-expenses.dto.ts
├── models/
│   └── expense.model.ts
├── expenses.controller.ts
├── expenses.service.ts
├── expenses.module.ts
├── expenses.service.spec.ts
├── index.ts
├── README.md
└── API_EXAMPLES.md
```

## 2. Configuração do Banco de Dados

### Passo 1: Execute o SQL no Supabase

1. Acesse o Supabase Dashboard do seu projeto
2. Vá para **SQL Editor**
3. Execute o script `src/sql/CREATE_EXPENSES_TABLES.sql`

Este script criará:
- Tabela `expenses` (despesas)
- Tabela `expense_participants` (participantes das despesas)
- Índices para performance
- Políticas RLS (Row Level Security)
- Funções auxiliares para cálculos

### Passo 2: Verificar Tabelas Criadas

Após executar o script, você deve ver as seguintes tabelas no Supabase:

- ✅ `expenses`
- ✅ `expense_participants`

## 3. Dependências

As seguintes dependências já estão instaladas:

- ✅ `@nestjs/common`
- ✅ `@nestjs/core`
- ✅ `@nestjs/config` (recém instalada)
- ✅ `@supabase/supabase-js`
- ✅ `class-validator`
- ✅ `class-transformer`

## 4. Configuração do Módulo

O módulo já foi integrado ao `app.module.ts`:

```typescript
import { ExpensesModule } from './expenses/expenses.module';

@Module({
  imports: [
    // ... outros módulos
    ExpensesModule
  ],
  // ...
})
export class AppModule {}
```

## 5. Variáveis de Ambiente

Certifique-se de que as seguintes variáveis estão configuradas no seu `.env`:

```env
SUPABASE_URL=sua_url_do_supabase
SUPABASE_KEY=sua_chave_do_supabase
```

## 6. Endpoints Disponíveis

Após a configuração, os seguintes endpoints estarão disponíveis:

- `POST /expenses` - Criar despesa
- `GET /expenses/group/:groupId` - Listar despesas do grupo
- `GET /expenses/:id` - Obter despesa por ID
- `PUT /expenses/:id` - Editar despesa
- `DELETE /expenses/:id` - Deletar despesa

## 7. Testando a Instalação

### Iniciar o Servidor
```bash
npm run start:dev
```

### Testar Compilação
```bash
npm run build
```

### Executar Testes
```bash
npm run test
```

## 8. Próximos Passos

1. **Testar Endpoints**: Use os exemplos em `API_EXAMPLES.md`
2. **Personalizar Categorias**: Ajuste as categorias conforme suas necessidades
3. **Implementar Frontend**: Integre com o app Flutter
4. **Adicionar Funcionalidades**: Como divisão personalizada, comentários, etc.

## 9. Funcionalidades Implementadas

✅ **Criar Despesa**
- Vinculada a um grupo
- Pagador definido
- Múltiplos participantes
- Divisão automática do valor
- Categorização

✅ **Listar Despesas**
- Por grupo
- Filtros por pessoa, período, categoria
- Ordenação por data

✅ **Editar Despesa**
- Alterar valor, descrição, categoria
- Modificar participantes
- Atualização automática dos valores

✅ **Deletar Despesa**
- Soft delete para manter histórico
- Preservação de dados para auditoria

✅ **Segurança**
- Autenticação obrigatória
- Verificação de membros do grupo
- Row Level Security no banco

## 10. Troubleshooting

### Erro: "Usuário não é membro do grupo"
- Verifique se o usuário está adicionado ao grupo
- Confirme se o JWT token está correto

### Erro: "SUPABASE_URL and SUPABASE_KEY must be defined"
- Verifique o arquivo `.env`
- Confirme se as variáveis estão corretas

### Erro de Compilação
- Execute `npm install` para instalar dependências
- Verifique se todas as importações estão corretas

### Erro ao Executar SQL
- Confirme se as tabelas `groups` e `group_members` existem
- Verifique se o usuário tem permissões no Supabase

## 11. Suporte

Para dúvidas ou problemas:

1. Consulte o `README.md` do módulo
2. Verifique os exemplos em `API_EXAMPLES.md`
3. Analise os logs do servidor
4. Teste os endpoints com dados válidos