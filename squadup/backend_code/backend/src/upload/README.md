# 📸 Gestão de Avatares - API Documentation

## Visão Geral

Sistema completo para gestão de imagens de perfil (avatares) usando Supabase Storage. Cada usuário pode ter apenas um avatar por vez, com substituição automática e limpeza de arquivos antigos.

## 🚀 Configuração Inicial

### 1. Supabase Storage Setup

Execute o script SQL no Supabase Dashboard:
```sql
-- Executar o arquivo: src/sql/SETUP_AVATARS_STORAGE.sql
```

### 2. Variáveis de Ambiente

Certifique-se de que estas variáveis estão configuradas no seu `.env`:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
```

## 📡 Endpoints da API

### 🔐 Autenticação

Todos os endpoints de avatar requerem autenticação. Inclua o token JWT no header:
```
Authorization: Bearer your_jwt_token
```

---

### 1. Upload de Avatar

**POST** `/auth/avatar`

Faz upload de uma nova imagem de perfil para o usuário autenticado.

#### Headers
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

#### Body (Form Data)
- `avatar` (file): Arquivo de imagem (JPEG, PNG, WebP, GIF)
- Tamanho máximo: 5MB

#### Exemplo usando cURL
```bash
curl -X POST \
  http://localhost:3000/auth/avatar \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "avatar=@/path/to/your/image.jpg"
```

#### Exemplo usando JavaScript (Fetch)
```javascript
const formData = new FormData();
formData.append('avatar', fileInput.files[0]);

const response = await fetch('/auth/avatar', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${userToken}`
  },
  body: formData
});

const result = await response.json();
```

#### Response Success (200)
```json
{
  "success": true,
  "message": "Avatar uploaded successfully",
  "data": {
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "user_metadata": {
        "name": "User Name",
        "avatar_url": "https://your-project.supabase.co/storage/v1/object/public/avatars/user-id/avatar-123456789.jpg",
        "avatar_path": "user-id/avatar-123456789.jpg"
      }
    },
    "avatar": {
      "url": "https://your-project.supabase.co/storage/v1/object/public/avatars/user-id/avatar-123456789.jpg",
      "path": "user-id/avatar-123456789.jpg"
    }
  }
}
```

---

### 2. Obter Avatar do Usuário

**GET** `/auth/avatar`

Retorna a URL do avatar do usuário autenticado.

#### Headers
```
Authorization: Bearer {token}
```

#### Response Success (200)
```json
{
  "success": true,
  "message": "Avatar retrieved successfully",
  "data": {
    "avatar_url": "https://your-project.supabase.co/storage/v1/object/public/avatars/user-id/avatar-123456789.jpg"
  }
}
```

#### Response (Sem Avatar)
```json
{
  "success": true,
  "message": "No avatar found",
  "data": {
    "avatar_url": null
  }
}
```

---

### 3. Excluir Avatar

**DELETE** `/auth/avatar`

Remove o avatar do usuário autenticado.

#### Headers
```
Authorization: Bearer {token}
```

#### Response Success (200)
```json
{
  "success": true,
  "message": "Avatar deleted successfully",
  "data": {
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "user_metadata": {
        "name": "User Name"
      }
    }
  }
}
```

---

### 4. Obter Perfil Completo

**GET** `/auth/profile`

Retorna o perfil completo do usuário, incluindo avatar se disponível.

#### Headers
```
Authorization: Bearer {token}
```

#### Response Success (200)
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "user_metadata": {
        "name": "User Name",
        "avatar_url": "https://your-project.supabase.co/storage/v1/object/public/avatars/user-id/avatar-123456789.jpg"
      }
    }
  }
}
```

---

## 🔒 Endpoints Alternativos (através do módulo Upload)

### Upload de Avatar para Usuário Específico

**POST** `/users/{userId}/avatar`

*Nota: Este endpoint está disponível mas é recomendado usar `/auth/avatar` para melhor segurança.*

---

## ⚙️ Características Técnicas

### 🛡️ Validações

- **Tipos de arquivo permitidos**: JPEG, PNG, WebP, GIF
- **Tamanho máximo**: 5MB
- **Autenticação**: Obrigatória para todas as operações
- **Autorização**: Usuários só podem modificar seus próprios avatares

### 🗂️ Organização de Arquivos

- **Estrutura**: `{userId}/avatar-{timestamp}.{extensão}`
- **Exemplo**: `123e4567-e89b-12d3-a456-426614174000/avatar-1703123456789.jpg`

### 🧹 Limpeza Automática

- **Substituição**: Ao fazer upload de um novo avatar, o anterior é removido
- **Cleanup**: Arquivos antigos são automaticamente deletados
- **Otimização**: Evita acúmulo desnecessário de arquivos

### 🏗️ Estrutura do Bucket Supabase

```
Bucket: avatars (público)
├── user-id-1/
│   └── avatar-1703123456789.jpg
├── user-id-2/
│   └── avatar-1703123456790.png
└── user-id-3/
    └── avatar-1703123456791.webp
```

---

## 🔧 Exemplos de Uso

### React/Next.js Component

```jsx
import { useState } from 'react';

function AvatarUploader({ userToken, currentAvatarUrl, onAvatarUpdate }) {
  const [uploading, setUploading] = useState(false);

  const handleFileUpload = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    setUploading(true);
    
    try {
      const formData = new FormData();
      formData.append('avatar', file);

      const response = await fetch('/api/auth/avatar', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${userToken}`
        },
        body: formData
      });

      const result = await response.json();
      
      if (result.success) {
        onAvatarUpdate(result.data.avatar.url);
      }
    } catch (error) {
      console.error('Error uploading avatar:', error);
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteAvatar = async () => {
    try {
      const response = await fetch('/api/auth/avatar', {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      });

      const result = await response.json();
      
      if (result.success) {
        onAvatarUpdate(null);
      }
    } catch (error) {
      console.error('Error deleting avatar:', error);
    }
  };

  return (
    <div className="avatar-uploader">
      {currentAvatarUrl ? (
        <div>
          <img src={currentAvatarUrl} alt="Avatar" className="avatar-preview" />
          <button onClick={handleDeleteAvatar}>Remover Avatar</button>
        </div>
      ) : (
        <div className="no-avatar">Nenhum avatar</div>
      )}
      
      <input
        type="file"
        accept="image/*"
        onChange={handleFileUpload}
        disabled={uploading}
      />
      
      {uploading && <p>Enviando...</p>}
    </div>
  );
}
```

### Flutter (Dart) Example

```dart
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AvatarService {
  final String baseUrl;
  final String token;

  AvatarService({required this.baseUrl, required this.token});

  Future<Map<String, dynamic>> uploadAvatar(XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/avatar'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', image.path));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    
    return jsonDecode(responseBody);
  }

  Future<String?> getAvatarUrl() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/avatar'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['avatar_url'];
    }
    
    return null;
  }

  Future<bool> deleteAvatar() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/avatar'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
```

---

## 🚨 Tratamento de Erros

### Códigos de Status HTTP

- **200**: Sucesso
- **400**: Erro na requisição (arquivo inválido, muito grande, etc.)
- **401**: Não autenticado
- **403**: Não autorizado (tentando modificar avatar de outro usuário)
- **404**: Avatar não encontrado

### Exemplos de Erros

```json
{
  "success": false,
  "message": "Error uploading avatar",
  "error": "File size too large. Maximum size is 5MB"
}
```

```json
{
  "success": false,
  "message": "Error uploading avatar",
  "error": "Invalid file type. Allowed types: image/jpeg, image/png, image/webp, image/gif"
}
```

---

## 🔐 Segurança

### Políticas RLS (Row Level Security)

- ✅ Usuários podem fazer upload apenas em suas próprias pastas
- ✅ Avatares são públicos para visualização
- ✅ Apenas o proprietário pode atualizar/deletar seus avatares
- ✅ Autenticação obrigatória para todas as operações

### Boas Práticas

1. **Sempre validar** o tamanho e tipo do arquivo no frontend
2. **Redimensionar imagens** antes do upload quando possível
3. **Otimizar imagens** para web (compressão, formato WebP)
4. **Implementar loading states** durante upload
5. **Tratar erros** adequadamente na interface

---

## 📝 Notas Importantes

1. **Substituição automática**: Ao fazer upload de um novo avatar, o anterior é automaticamente removido
2. **URLs públicas**: Os avatares são acessíveis publicamente através da URL
3. **Cleanup automático**: Arquivos antigos são limpos automaticamente
4. **Metadados do usuário**: A URL do avatar é salva nos metadados do usuário no Supabase Auth
5. **Performance**: Use cache adequado no frontend para evitar recarregamentos desnecessários

---

## 🆘 Troubleshooting

### Problema: "Error uploading to Supabase Storage"
- ✅ Verifique se o bucket 'avatars' foi criado
- ✅ Confirme se as políticas RLS estão aplicadas
- ✅ Teste as permissões no Supabase Dashboard

### Problema: "File size too large"
- ✅ Redimensione a imagem antes do upload
- ✅ Use compressão de imagem
- ✅ Considere implementar resize automático no frontend

### Problema: "Invalid token"
- ✅ Verifique se o token JWT está válido
- ✅ Confirme se o usuário está autenticado
- ✅ Teste o token em outros endpoints
