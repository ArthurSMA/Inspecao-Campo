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
`Authorization: Bearer <accessToken>`. Uma resposta válida é persistida no
SQLite antes de ser devolvida à interface, que apresenta loading, erro com nova
tentativa, lista vazia ou a lista de cards.

Em `connectionError` ou timeout, o serviço consulta o cache local. Havendo
dados, a página continua exibindo as ordens sem erro bloqueante. Sem cache,
apresenta mensagem legível. HTTP 401, erros HTTP de servidor e payload inválido
não usam fallback local.

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
A ação de cada card abre o formulário de inspeção para a ordem selecionada.
A opção já selecionada mantém a página atual. Histórico abre a lista local de
inspeções. O menu da lista oferece logout.

Home e Work Orders reutilizam `AppNavigationBar`, mantendo os mesmos destinos e
permitindo que cada página controle apenas o índice selecionado e a navegação.

Se não houver token ou o endpoint responder HTTP 401, a página chama
`onSessionInvalid`, que remove o token e faz o `AuthGate` retornar ao login.

## Limitações atuais

- O formulário usa os dados já carregados da ordem; `GET /work-orders/:id` ainda
  não é consumido separadamente.
- Uma nova entrada tenta atualizar pela API e usa o cache somente quando a API
  está inacessível por conexão ou timeout.
