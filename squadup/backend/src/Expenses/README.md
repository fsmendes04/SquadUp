# Módulo de Despesas

Este módulo implementa a funcionalidade de gestão de despesas integrada com os grupos existentes.

## Estrutura

- **Controller**: `expenses.controller.ts` - Endpoints da API
- **Service**: `expenses.service.ts` - Lógica de negócio
- **DTOs**: Pasta `dto/` - Objetos de transferência de dados
- **Models**: Pasta `models/` - Interfaces e tipos

## Funcionalidades

### 1. Criar Despesa
**POST** `/expenses`

Cria uma nova despesa associada a um grupo.

**Body:**
```json
{
  "group_id": "uuid",
  "payer_id": "uuid",
  "amount": 100.50,
  "description": "Jantar no restaurante",
  "category": "comida",
  "expense_date": "2023-12-01",
  "participant_ids": ["uuid1", "uuid2", "uuid3"]
}
```

### 2. Listar Despesas do Grupo
**GET** `/expenses/group/:groupId`

Lista todas as despesas de um grupo com filtros opcionais.

**Query Parameters:**
- `payer_id` (opcional): Filtrar por pagador
- `participant_id` (opcional): Filtrar por participante
- `start_date` (opcional): Data inicial (YYYY-MM-DD)
- `end_date` (opcional): Data final (YYYY-MM-DD)
- `category` (opcional): Filtrar por categoria

**Exemplo:**
```
GET /expenses/group/123e4567-e89b-12d3-a456-426614174000?category=comida&start_date=2023-12-01&end_date=2023-12-31
```

### 3. Obter Despesa por ID
**GET** `/expenses/:id`

Retorna os detalhes de uma despesa específica.

### 4. Editar Despesa
**PUT** `/expenses/:id`

Atualiza uma despesa existente.

**Body (todos os campos são opcionais):**
```json
{
  "amount": 120.00,
  "description": "Jantar no restaurante (atualizado)",
  "category": "alimentacao",
  "expense_date": "2023-12-02",
  "participant_ids": ["uuid1", "uuid2"]
}
```

### 5. Deletar Despesa
**DELETE** `/expenses/:id`

Remove uma despesa (soft delete).

## Regras de Negócio

1. **Autenticação**: Todos os endpoints requerem autenticação
2. **Membros do Grupo**: Apenas membros do grupo podem criar/visualizar/editar despesas
3. **Participantes**: Todos os participantes devem ser membros do grupo
4. **Pagador**: O pagador deve ser membro do grupo
5. **Divisão**: O valor da despesa é dividido igualmente entre todos os participantes
6. **Soft Delete**: Despesas deletadas são marcadas com `deleted_at` em vez de serem removidas

## Categorias Sugeridas

- `comida` - Alimentação
- `transporte` - Transporte
- `moradia` - Moradia/Acomodação
- `entretenimento` - Entretenimento
- `compras` - Compras
- `saude` - Saúde
- `educacao` - Educação
- `outros` - Outros

## Estrutura do Banco de Dados

### Tabela `expenses`
- `id` (UUID, PK)
- `group_id` (UUID, FK para groups)
- `payer_id` (UUID, FK para auth.users)
- `amount` (DECIMAL)
- `description` (TEXT)
- `category` (VARCHAR)
- `expense_date` (DATE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `deleted_at` (TIMESTAMP, nullable)

### Tabela `expense_participants`
- `id` (UUID, PK)
- `expense_id` (UUID, FK para expenses)
- `user_id` (UUID, FK para auth.users)
- `amount_owed` (DECIMAL)
- `created_at` (TIMESTAMP)

## Instalação

1. Execute o script SQL `CREATE_EXPENSES_TABLES.sql` no Supabase
2. O módulo já está registrado no `app.module.ts`
3. Instale as dependências necessárias (class-validator, class-transformer)

## Exemplo de Uso

```typescript
// Criar uma despesa
const expense = await fetch('/expenses', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_TOKEN'
  },
  body: JSON.stringify({
    group_id: 'group-uuid',
    payer_id: 'user-uuid',
    amount: 150.00,
    description: 'Pizza para o grupo',
    category: 'comida',
    expense_date: '2023-12-01',
    participant_ids: ['user1-uuid', 'user2-uuid', 'user3-uuid']
  })
});

// Listar despesas com filtros
const expenses = await fetch('/expenses/group/group-uuid?category=comida&start_date=2023-12-01');
```