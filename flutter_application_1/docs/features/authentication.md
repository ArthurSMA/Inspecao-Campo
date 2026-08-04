# 🔐 Feature — Login e Autenticação

## Objetivo

A funcionalidade de autenticação é responsável por validar as credenciais do usuário, armazenar o token de acesso e permitir a navegação para as áreas protegidas do aplicativo.

Neste momento, o foco está na implementação do fluxo de login e na comunicação com a API mock fornecida pelo desafio.

---

## Fluxo de autenticação

```txt
LoginPage
    ↓
LoginForm
    ↓
AuthService
    ↓
ApiClient
    ↓
POST /auth/login
    ↓
LoginResponse
    ↓
TokenStorage
    ↓
HomePage
```

---

## Fluxo detalhado

1. O usuário informa o e-mail e a senha.

2. O formulário realiza a validação dos campos.

3. A requisição é enviada para a API.

4. O serviço converte a resposta para o modelo correspondente.

5. O token é armazenado localmente.

6. O usuário é redirecionado para a página inicial.

---

## Estrutura da feature

```txt
feat/
├── auth/
│   ├── data/
│   │   ├── models/
│   │   │   └── login_response.dart
│   │   │
│   │   └── services/
│   │       └── auth_service.dart
│   │
│   └── presentation/
│       ├── pages/
│       │   └── login_page.dart
│       │
│       └── widgets/
│           └── login_form.dart
│
└── home/
    └── presentation/
        └── pages/
            └── home_page.dart
```

---

## Responsabilidades

### LoginPage

Responsável pela estrutura principal da tela.

### LoginForm

Responsável pelos seguintes elementos:

- formulário;
- validação;
- loading;
- exibição de erros;
- navegação.

---

### AuthService

Responsável por:

- realizar a autenticação;
- consumir a API;
- converter a resposta;
- tratar erros.

---

### ApiClient

Responsável por:

- URL base;
- cabeçalhos;
- configuração do Dio;
- tempo limite das requisições.

---

### TokenStorage

Responsável por:

- salvar o token;
- recuperar o token;
- remover o token.

---

## Resposta esperada da API

```json
{
  "accessToken": "token",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": "u_001",
    "name": "Ana Técnica",
    "email": "tecnico@orbytis.com.br",
    "role": "field_technician"
  }
}
```

---

## Credenciais de teste

| Perfil | E-mail | Senha |
|------|------|------|
| Técnico | `tecnico@orbytis.com.br` | `123456` |
| Administrador | `admin@orbytis.com.br` | `admin123` |

---

## Configuração de rede

| Ambiente | URL |
|------|------|
| Computador | `http://localhost:3000` |
| Emulador Android | `http://10.0.2.2:3000` |
| Dispositivo físico | `http://192.168.x.x:3000` |

---

## Tratamento de erros

Atualmente são tratados:

- credenciais inválidas;
- falhas de conexão;
- tempo limite da requisição;
- rotas inexistentes;
- respostas inválidas;
- erros inesperados.

---

## Armazenamento do token

A biblioteca `flutter_secure_storage` é utilizada para armazenar o token de acesso de maneira segura.

Atualmente, apenas o campo `accessToken` é armazenado.

---

## Limitações atuais

Atualmente ainda não existem:

- proteção de rotas;
- logout;
- renovação automática do token;
- interceptadores do Dio;
- testes unitários;
- persistência da sessão após o fechamento do aplicativo.

---

## Próximos passos

- validar a sessão utilizando `GET /auth/me`;
- implementar o logout;
- adicionar interceptadores;
- proteger as rotas autenticadas;
- implementar testes unitários;
- adicionar gerenciamento de estado.