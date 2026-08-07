# Feature — Work Orders

## Objetivo

A feature lista as ordens de serviço recebidas da API, permite filtrar o
resultado em memória e preserva o fluxo de autenticação ao detectar uma sessão
inválida.

## Fluxo

```text
API (GET /work-orders)
  ↓
WorkOrderService
  ↓
WorkOrder.fromJson
  ↓
List<WorkOrder>
  ↓
WorkOrdersPage
  ↓
filtro em memória
  ↓
WorkOrderCard
```

A `WorkOrdersPage` inicia o carregamento em `initState`, lê o token pelo
`TokenStorage` e chama o serviço com o header
`Authorization: Bearer <accessToken>`. A resposta é mantida em memória e a
interface apresenta loading, erro com nova tentativa, lista vazia ou a lista de
cards.

## Estrutura e responsabilidades

```text
feat/work_orders/
├── data/models/work_order.dart
├── presentation/
│   ├── pages/work_orders_page.dart
│   └── widgets/
│       ├── work_order_card.dart
│       └── work_order_filters.dart
└── services/work_order_service.dart
```

- `WorkOrder`: representa id, código, título, descrição, endereço, prioridade,
  status, coordenadas, datas e observações da API.
- `WorkOrderService`: executa `GET /work-orders`, converte o JSON e traduz
  falhas de sessão, conexão, timeout, servidor e payload em mensagens úteis.
- `WorkOrdersPage`: coordena token, carregamento, estado, filtro e navegação.
- `WorkOrderCard`: exibe os dados da ordem e traduz prioridade e status.
- `WorkOrderFilters`: apresenta e comunica a seleção do filtro.
- `WorkOrderPresentation`: extension da camada de apresentação que concentra
  labels e cores de status, além dos labels e cores suaves de prioridade.

## Filtros

- **Todas**: mostra todas as ordens carregadas.
- **Abertas**: mostra `open` e `in_progress`, pois ambas ainda não foram
  concluídas.
- **Concluídas**: mostra somente `done`.

Trocar o filtro não chama a API novamente. A lista original permanece em
memória e apenas a coleção exibida é derivada no momento da renderização.

## Status e prioridades

| Valor da API | Status exibido | Cor indicadora |
| --- | --- | --- |
| `open` | Aberta | azul neutro |
| `in_progress` | Em andamento | azul de destaque |
| `done` | Concluída | verde |

A cor do status é aplicada de forma coerente à linha lateral esquerda, ao ponto
indicador e ao texto do rodapé do card. Essa regra visual fica exclusivamente em
`work_order_presentation.dart`; o contrato JSON continua inalterado.

| Valor da API | Prioridade exibida |
| --- | --- |
| `high` | Alta |
| `medium` | Média |
| `low` | Baixa |

As prioridades usam badges discretos e não compartilham a semântica de cores do
status.

## Navegação e sessão

Na Home, **Ordens** abre `WorkOrdersPage`; na lista, **Início** volta à Home.
A opção já selecionada mantém a página atual. Como Histórico ainda não existe,
ela exibe um `SnackBar`. O menu da lista oferece logout.

Home e Work Orders reutilizam `AppNavigationBar`, mantendo os mesmos destinos e
permitindo que cada página controle apenas o índice selecionado e a navegação.

Se não houver token ou o endpoint responder HTTP 401, a página chama
`onSessionInvalid`, que remove o token e faz o `AuthGate` retornar ao login.

## Limitações atuais

- A tela de detalhes/início da ordem ainda não foi implementada.
- Histórico ainda não possui página.
- Não existe cache local; uma nova entrada na página consulta a API novamente.
