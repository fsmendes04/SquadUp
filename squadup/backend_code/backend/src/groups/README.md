# API de Grupos - SquadUp

Esta API fornece funcionalidades completas para gerenciar grupos e seus membros.

## Estrutura do Banco de Dados

Antes de usar a API, execute o script SQL em `database-schema.sql` no seu Supabase para criar as tabelas necessárias.

### Tabelas Criadas:
- `groups`: Armazena informações dos grupos
- `group_members`: Relaciona usuários com grupos e define suas funções

## Endpoints da API

### 1. Criar Grupo
**POST** `/groups?userId={userId}`

```json
{
  "name": "Nome do Grupo",
  "description": "Descrição opcional",
  "memberIds": ["user-id-1", "user-id-2"] // Opcional
}
```

### 2. Listar Todos os Grupos
**GET** `/groups`

### 3. Listar Grupos de um Usuário
**GET** `/groups/user/{userId}`

### 4. Obter Detalhes de um Grupo
**GET** `/groups/{groupId}`

### 5. Atualizar Grupo
**PATCH** `/groups/{groupId}?userId={userId}`

```json
{
  "name": "Novo Nome",
  "description": "Nova Descrição"
}
```

### 6. Deletar Grupo
**DELETE** `/groups/{groupId}?userId={userId}`

### 7. Adicionar Membro ao Grupo
**POST** `/groups/{groupId}/members?requesterId={requesterId}`

```json
{
  "userId": "user-id-to-add"
}
```

### 8. Remover Membro do Grupo
**DELETE** `/groups/{groupId}/members?requesterId={requesterId}`

```json
{
  "userId": "user-id-to-remove"
}
```

## Funcionalidades Implementadas

### Controle de Acesso
- **Criação**: Qualquer usuário autenticado pode criar grupos
- **Administração**: O criador do grupo automaticamente vira admin
- **Atualização/Exclusão**: Apenas admins podem modificar o grupo
- **Gerenciar Membros**: Apenas admins podem adicionar/remover membros
- **Auto-remoção**: Usuários podem se remover do grupo (exceto o criador)

### Validações
- Nomes de grupos são obrigatórios
- Não é possível adicionar usuários já membros do grupo
- O criador não pode se remover do grupo
- Validação de permissões para todas as operações

### Segurança
- Row Level Security (RLS) habilitado no Supabase
- Políticas de segurança para controlar acesso aos dados
- Validação de DTOs com class-validator

## Modelos de Dados

### Group
```typescript
{
  id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
  created_by: string;
}
```

### GroupMember
```typescript
{
  id: string;
  group_id: string;
  user_id: string;
  joined_at: string;
  role: 'admin' | 'member';
}
```

### GroupWithMembers
```typescript
{
  ...Group,
  members: GroupMember[];
}
```

## Como Testar

1. Execute o script SQL no Supabase
2. Configure as variáveis de ambiente (`SUPABASE_URL` e `SUPABASE_KEY`)
3. Inicie o servidor: `npm run start:dev`
4. Use um cliente HTTP (Postman, Insomnia, etc.) para testar os endpoints

## Próximos Passos

Para melhorar ainda mais a funcionalidade, considere implementar:

1. **Notificações**: Notificar usuários quando forem adicionados/removidos
2. **Convites**: Sistema de convites para grupos privados
3. **Categorias**: Diferentes tipos de grupos (público, privado, etc.)
4. **Limites**: Limite máximo de membros por grupo
5. **Auditoria**: Log de ações realizadas nos grupos
6. **Busca**: Busca de grupos por nome ou descrição