# Inspeção de Campo

Aplicativo mobile desenvolvido em Flutter para auxiliar técnicos em atividades de inspeção e operação em campo.

O projeto simula um ambiente no qual profissionais consultam ordens de serviço.
Ordens, usuário autenticado e inspeções são persistidos localmente com
Drift/SQLite. Inspeções podem ser preenchidas offline e sincronizadas com a API
manualmente ou após a recuperação da conectividade.

---

## Principais funcionalidades

- Autenticação de usuários;
- Consulta de ordens de serviço;
- Resumo de ordens abertas na Home;
- Tratamento de sessão, conectividade e erros da API.
- Formulário de inspeção com foto e GPS;
- Rascunhos, fila de sincronização, retry e histórico local.

---

## Arquitetura

O projeto segue a abordagem **Feature First**, na qual cada funcionalidade é organizada de maneira independente.

```text
lib/
├── app/
│   └── app.dart
│
├── core/
│   ├── network/
│   ├── database/
│   └── storage/
│
├── feat/
│   ├── auth/
│   ├── home/
│   ├── inspection/
│   └── work_orders/
├── shared/
└── main.dart
```

---

## Estrutura do projeto

```text
.
├── android/
├── ios/
├── lib/
│   ├── app/
│   ├── core/
│   └── feat/
│
├── docs/
│   ├── architecture/
│   └── features/
│
├── test/
├── pubspec.yaml
└── README.md
```

---

## Tecnologias

### Aplicação

- Dart
- Flutter
- Material Design
- Dio
- flutter_secure_storage
- connectivity_plus
- Drift / SQLite

### API mock

- Node.js
- Express

---

## Como executar a API

A API está localizada fora da pasta do aplicativo Flutter.

```bash
cd ../mock-api
npm install
npm start
```

---

## Como executar o aplicativo

```bash
flutter pub get
flutter devices
flutter run
```

---

## Configuração de rede

| Ambiente | Endereço |
|---|---|
| Computador | `http://localhost:3000` |
| Emulador Android | `http://10.0.2.2:3000` |
| Dispositivo físico | `http://192.168.x.x:3000` |

---

## Documentação

```text
docs/
└── features/
    ├── authentication.md
    ├── home.md
    ├── inspection.md
    └── work_orders.md
```

| Documento | Descrição |
|---|---|
| `authentication.md` | Fluxo de login e autenticação |
| `home.md` | Painel inicial, resumo de ordens e estados da interface |
| `inspection.md` | Persistência, formulário, fila e sincronização |
| `work_orders.md` | Listagem, filtros e representação das ordens |
| `CONTRATO_API.md` | Contrato da API |
| `DESAFIO_CANDIDATO.md` | Especificação do desafio |

---

## Estado atual

### Concluído

- [x] Login
- [x] Consumo da API
- [x] Persistência do token
- [x] Tratamento de erros
- [x] Navegação
- [x] Proteção de rotas
- [x] Logout
- [x] Resumo de ordens abertas na Home
- [x] Lista e filtros de ordens de serviço
- [x] Cache offline de ordens de serviço
- [x] Restauração offline de sessão previamente autenticada
- [x] Formulário de inspeção com observação, condição, foto e GPS
- [x] Rascunho e conclusão persistidos no SQLite
- [x] POST multipart de inspeções
- [x] Fila manual e automática
- [x] Histórico local, filtros e retry

### Em andamento

- [ ] Interceptor do Dio

### Planejado

- [ ] Campos dinâmicos opcionais (`form-schema`)
- [ ] Conciliação opcional com `GET /inspections`

## Funcionamento online e offline

O `db.json` pertence à API mock e continua sendo o banco remoto. O Dio acessa a
API e o Drift controla exclusivamente o SQLite local do aplicativo.

```text
ONLINE:  API → Flutter/Dio → SQLite/Drift → UI
OFFLINE: SQLite/Drift → UI
```

Uma resposta válida de `GET /work-orders` atualiza o cache antes de chegar à UI.
Em falhas de conexão ou timeout, as ordens salvas são usadas. HTTP 401 e payload
inválido não são escondidos pelo cache.

O primeiro login sempre exige a API. Após um login online, token e dados mínimos
do usuário são salvos separadamente: o token no armazenamento seguro e
`id`, `name`, `email` e `role` no SQLite. A senha nunca é armazenada. Uma sessão
previamente autenticada pode ser restaurada offline; HTTP 401 ou logout explícito
removem a sessão local.

## Inspeções e sincronização

```text
Formulário → SQLite → draft/pending
pending/failed → POST /inspections → synced/failed
```

Cada inspeção recebe um `clientId` UUID v4 uma única vez. O mesmo valor é usado
nos retries, permitindo a resposta idempotente HTTP 200 da API. HTTP 200 e 201
são sucesso: o `serverId` é salvo, o status vira `synced` e o erro é limpo.
Falhas ficam como `failed` com mensagem legível e podem ser reenviadas pelo
histórico ou pelo botão da Home. A foto é copiada para o diretório persistente do
aplicativo e o histórico é lido do SQLite, incluindo itens ainda não enviados.

---

## Licença

Este projeto foi desenvolvido exclusivamente para fins de estudo e avaliação técnica.

---

## 👨‍💻 Autor

Arthur Suassuna Maia Alves
