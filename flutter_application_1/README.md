# Inspeção de Campo

Aplicativo mobile desenvolvido em Flutter para auxiliar técnicos em atividades de inspeção e operação em campo.

O projeto simula um ambiente no qual profissionais precisam consultar ordens de serviço, registrar evidências, trabalhar sem conexão com a internet e sincronizar as informações posteriormente.

O foco principal do desafio está na arquitetura da aplicação, na persistência local e na sincronização offline.

---

## Principais funcionalidades

- Autenticação de usuários;
- Consulta de ordens de serviço;
- Registro de inspeções;
- Captura de fotos;
- Captura de localização GPS;
- Persistência local;
- Sincronização automática e manual;
- Histórico de inspeções.

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
│   └── storage/
│
├── feat/
│   ├── auth/
│   ├── home/
│   ├── work_orders/
│   ├── inspections/
│   ├── history/
│   └── sync/
│
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
├── architecture/
│   └── architecture.md
│
└── features/
    ├── authentication.md
    └── home.md
```

| Documento | Descrição |
|---|---|
| `architecture.md` | Arquitetura do projeto |
| `authentication.md` | Fluxo de login e autenticação |
| `home.md` | Painel inicial, resumo de ordens e estados da interface |
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

### Em andamento

- [ ] Interceptor do Dio
- [ ] Lista de ordens de serviço

### Planejado

- [ ] Detalhes da ordem de serviço
- [ ] Captura de fotos
- [ ] Captura de localização
- [ ] Persistência local
- [ ] Sincronização
- [ ] Histórico

---

## Licença

Este projeto foi desenvolvido exclusivamente para fins de estudo e avaliação técnica.

---

## 👨‍💻 Autor

Arthur Suassuna Maia Alves
