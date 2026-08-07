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
│   │   └── models/
│   │       └── login_response.dart
│   ├── services/
│   │   └── auth_service.dart
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

O `accessToken` é armazenado no `flutter_secure_storage`. Após uma autenticação
online, `id`, `name`, `email` e `role` também são mantidos no SQLite por meio do
Drift. A senha nunca é armazenada localmente.

---

## Proteção da sessão e logout

Ao iniciar, o `AuthGate` lê o token seguro e tenta validá-lo com `GET /auth/me`.
A `HomePage` só é construída depois de uma validação bem-sucedida. Tokens
inválidos ou expirados (HTTP 401) são removidos e o login é exibido.

Se a API estiver inacessível por falha de conexão ou timeout, uma sessão já
autenticada pode ser restaurada com o usuário salvo no SQLite. Isso não permite
um primeiro login offline: sem token e usuário previamente salvos, o login
continua dependendo de `POST /auth/login`.

O mock não oferece endpoint de logout. Por isso, a saída é local: a ação
visível na `HomePage` remove o token e faz o `AuthGate` reconstruir o login,
sem manter uma tela autenticada na pilha de navegação.

O campo `role` é convertido e preservado no modelo, mas não altera o fluxo,
pois o desafio não exige autorização por perfil.

## Limitações fora do requisito obrigatório

- não há renovação automática do token;
- não há interceptador global do Dio;
- uma indisponibilidade da API impede a abertura da área interna quando não há
  usuário local de uma sessão previamente autenticada.
