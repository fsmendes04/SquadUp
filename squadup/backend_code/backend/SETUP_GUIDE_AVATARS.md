# 🚀 Setup Guide - Gestão de Avatares

## 📋 Pré-requisitos

1. ✅ Projeto NestJS configurado
2. ✅ Supabase project criado
3. ✅ Variáveis de ambiente configuradas

## 🛠️ Passos de Configuração

### 1. Configurar Supabase Storage

1. **Acesse o Supabase Dashboard**
   - Vá para [app.supabase.com](https://app.supabase.com)
   - Selecione seu projeto

2. **Execute o Script SQL**
   - Vá para SQL Editor
   - Execute o script em `src/sql/SETUP_AVATARS_STORAGE.sql`
   - Verifique se o bucket 'avatars' foi criado em Storage

3. **Verificar Políticas RLS**
   - Vá para Authentication > Policies
   - Confirme se as políticas para o bucket 'avatars' foram criadas

### 2. Configurar Variáveis de Ambiente

1. **Copie o arquivo de exemplo**
   ```bash
   cp .env.example .env
   ```

2. **Preencha as variáveis**
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_KEY=your-supabase-anon-key
   ```

3. **Obtenha as credenciais no Supabase Dashboard**
   - Settings > API
   - Copie a URL e a `anon public` key

### 3. Instalar Dependências

```bash
npm install
```

### 4. Executar o Projeto

```bash
# Desenvolvimento
npm run start:dev

# Produção
npm run build
npm run start:prod
```

## 🧪 Testando a Implementação

### 1. Teste de Upload

```bash
curl -X POST \
  http://localhost:3000/auth/avatar \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "avatar=@/path/to/test-image.jpg"
```

### 2. Teste de Visualização

```bash
curl -X GET \
  http://localhost:3000/auth/avatar \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. Teste de Exclusão

```bash
curl -X DELETE \
  http://localhost:3000/auth/avatar \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🔧 Verificações de Troubleshooting

### ✅ Checklist de Verificação

- [ ] Bucket 'avatars' criado no Supabase Storage
- [ ] Políticas RLS aplicadas corretamente
- [ ] Variáveis de ambiente configuradas
- [ ] Projeto compilando sem erros
- [ ] Usuário autenticado para testes
- [ ] Arquivo de teste preparado (< 5MB, formato válido)

### 🚨 Problemas Comuns

1. **"Error uploading to Supabase Storage"**
   - Verifique se executou o script SQL
   - Confirme as credenciais no .env

2. **"Invalid token"**
   - Faça login primeiro em `/auth/login`
   - Use o token retornado nos headers

3. **"File size too large"**
   - Use imagens menores que 5MB
   - Teste com uma imagem pequena primeiro

## 📊 Estrutura Final dos Arquivos

```
src/
├── auth/
│   ├── auth.controller.ts    # ✅ Atualizado com rotas de avatar
│   ├── auth.service.ts       # ✅ Atualizado com gestão de avatar
│   ├── auth.module.ts        # ✅ Inclui UploadService
│   └── dto/
│       └── update-profile.dto.ts # ✅ Inclui campos de avatar
├── upload/
│   ├── upload.controller.ts  # ✅ NOVO - Controlador de uploads
│   ├── upload.service.ts     # ✅ NOVO - Lógica de upload/storage
│   ├── upload.module.ts      # ✅ NOVO - Módulo de upload
│   └── README.md            # ✅ NOVO - Documentação completa
├── sql/
│   └── SETUP_AVATARS_STORAGE.sql # ✅ NOVO - Script de configuração
└── app.module.ts            # ✅ Atualizado com UploadModule
```

## 🎯 Próximos Passos

1. **Execute o script SQL** no Supabase Dashboard
2. **Configure as variáveis** de ambiente
3. **Teste os endpoints** com Postman ou cURL
4. **Integre no frontend** usando os exemplos da documentação
5. **Implemente validações** adicionais conforme necessário

## 📞 Suporte

Se encontrar problemas:
1. Verifique os logs do servidor
2. Teste as políticas no Supabase Dashboard
3. Confirme as credenciais de autenticação
4. Consulte a documentação completa em `upload/README.md`