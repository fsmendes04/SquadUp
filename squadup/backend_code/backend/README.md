# SquadUp Backend API

Backend API para a aplicação SquadUp, construído com NestJS e Supabase.
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## 🚀 Funcionalidades

- ✅ **Autenticação de usuários** (register, login)
- ✅ **Gerenciamento de perfil** (atualizar nome e avatar)
- ✅ **Upload de Avatar** com Supabase Storage
- ✅ **Deleção de Avatar**
- ✅ **Guards de autenticação** para endpoints protegidos
- ✅ **Validação de arquivos** (formato e tamanho)

## 📋 Pré-requisitos

- Node.js 18+
- npm ou yarn
- Conta no Supabase
- Bucket 'avatars' configurado no Supabase Storage

## ⚙️ Configuração

### 1. Instalar dependências

```bash
npm install
```

### 2. Configurar variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
```

### 3. Configurar Supabase Storage

Consulte o arquivo `AVATAR_SETUP.md` para instruções detalhadas sobre como configurar o bucket de avatares no Supabase.

## 🏃‍♂️ Executar o projeto

```bash
# desenvolvimento
npm run start:dev

# produção
npm run start:prod

# debug
npm run start:debug
```

## 📡 Endpoints da API

### Autenticação
- `POST /auth/register` - Registrar novo usuário
- `POST /auth/login` - Fazer login

### Perfil e Avatar
- `PUT /auth/update-profile` - Atualizar perfil (requer autenticação)
- `POST /auth/upload-avatar` - Upload de avatar (requer autenticação)
- `DELETE /auth/delete-avatar` - Deletar avatar (requer autenticação)

### Grupos
- `GET /groups` - Listar grupos
- `POST /groups` - Criar grupo
- `GET /groups/:id` - Obter grupo por ID

Para documentação detalhada da API de avatares, consulte `AVATAR_API_DOCS.md`.

## 🧪 Testes

```bash
# testes unitários
npm run test

# testes e2e
npm run test:e2e

# cobertura de testes
npm run test:cov
```

## 🛠️ Estrutura do Projeto

```
src/
├── auth/
│   ├── dto/                    # Data Transfer Objects
│   ├── auth.controller.ts      # Controlador de autenticação
│   ├── auth.service.ts         # Serviços de autenticação
│   ├── auth.guard.ts          # Guard de autenticação
│   ├── auth.module.ts         # Módulo de autenticação
│   └── current-user.decorator.ts # Decorator para usuário atual
├── groups/
│   ├── dto/
│   ├── models/
│   ├── groups.controller.ts
│   ├── groups.service.ts
│   └── groups.module.ts
├── supabase/
│   └── supabase.service.ts    # Serviço do Supabase
├── app.controller.ts
├── app.module.ts
├── app.service.ts
└── main.ts
```

## 📝 Arquivos de Documentação

- `AVATAR_SETUP.md` - Guia de configuração do Supabase Storage
- `AVATAR_API_DOCS.md` - Documentação completa da API de avatares
- `test-avatar-api.ps1` - Script de teste para endpoints de avatar

## 🔒 Segurança

- Todos os endpoints de perfil e avatar são protegidos por autenticação JWT
- Validação de tipos de arquivo para uploads (apenas imagens)
- Limite de tamanho de arquivo (5MB)
- Guards customizados para verificação de token

## 📚 Tecnologias Utilizadas

- **NestJS** - Framework Node.js
- **Supabase** - Backend-as-a-Service (Auth + Storage)
- **Multer** - Middleware para upload de arquivos
- **TypeScript** - Linguagem de programação
- **class-validator** - Validação de dados

## 🚀 Deploy

Para fazer deploy da aplicação, consulte a [documentação do NestJS](https://docs.nestjs.com/deployment).

## 📄 Licença

Este projeto está licenciado sob a Licença MIT.
