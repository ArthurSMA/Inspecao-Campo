# Feature — Home

## Objetivo

A Home apresenta a situação atual do aplicativo, a saudação do usuário, o resumo
das ordens abertas e os indicadores previstos para inspeção e sincronização. Ela
também mantém as ações rápidas, a navegação inferior e o acesso ao logout.

## Fluxo atual

```text
AuthGate
  → HomePage.initState()
  → TokenStorage
  → ConnectivityService
  → WorkOrderService
  → GET /work-orders
  → HomeSummary
  → HomeDashboard
```

O carregamento acontece fora de `build()`. O gesto de atualizar e o botão
`Tentar novamente` repetem o mesmo fluxo.

## Estados da interface

- Verificando: consulta o token, a conectividade e a API.
- Online: a API respondeu e a sessão não foi rejeitada.
- Offline: não há interface de rede ou a API não pôde ser alcançada.
- Status indisponível: ocorreu uma falha inesperada antes de ser possível
  classificar a disponibilidade.
- Sucesso: o resumo usa as ordens retornadas pela API.
- Vazio: a API respondeu, mas não há ordens `open` ou `in_progress`.
- Erro: a API respondeu com erro de servidor/rota ou payload inválido; a tela
  oferece nova tentativa.
- Sessão expirada: o token é removido e o `AuthGate` volta ao login.

## Conectividade

Rede disponível e API acessível são conceitos diferentes:

- `connectivity_plus` informa se existe uma interface de rede, mas isso não
  comprova acesso à internet ou à API.
- “Sistema online” só aparece depois que `GET /work-orders` responde.
- Falha de conexão ou timeout coloca a Home em “Modo offline”.
- Uma resposta HTTP 404/500 comprova que a API foi alcançada; por isso o banner
  permanece online e o cartão apresenta o erro específico.
- HTTP 401 nunca é classificado como offline: ele invalida a sessão.

Quando a API está inacessível, a Home consulta o cache de ordens pelo mesmo
`WorkOrderService`. Com cache, calcula o número de ordens abertas e indica modo
offline com dados locais. Sem cache, informa que não há ordens armazenadas.

## Carregamento das ordens

O `WorkOrderService` reutiliza `ApiClient`, envia o token no header
`Authorization: Bearer <token>`, converte o JSON e classifica erros de conexão,
sessão, servidor e payload. A Home considera abertas ordens com status `open` ou
`in_progress`.

O fluxo atual é:

```text
Online: API → SQLite → resumo/interface
Offline: SQLite → resumo/interface
```

## Resumo exibido

- Nome do usuário: real, recebido do `AuthGate`.
- Ordens abertas: real, calculado a partir de `GET /work-orders`.
- Inspeções pendentes: calculadas do SQLite.
- Falhas de sincronização: calculadas do SQLite.

## Sincronização

O botão da Home envia itens `pending` e `failed` pela fila local. Uma transição
offline → online também dispara a mesma fila, sem tratar conectividade como prova
de disponibilidade da API. O horário da última sincronização ainda não é salvo.

## Estrutura de arquivos

```text
lib/
├── core/network/
│   ├── api_client.dart
│   └── connectivity_service.dart
└── feat/
    ├── home/
    │   ├── data/models/
    │   │   ├── home_availability.dart
    │   │   └── home_summary.dart
    │   └── presentation/
    │       ├── pages/home_page.dart
    │       └── widgets/home_dashboard.dart
    └── work_orders/
        ├── data/models/work_order.dart
        └── services/work_order_service.dart
```

## Responsabilidade de cada arquivo

- `home_page.dart`: coordena carregamento e estado, sem lógica no `build()`.
- `home_dashboard.dart`: apenas recebe estados, apresenta widgets e dispara ações.
- `home_availability.dart`: representa a disponibilidade da Home sem misturá-la
  ao resultado de uma sincronização.
- `home_summary.dart`: reúne os indicadores numéricos.
- `connectivity_service.dart`: consulta a presença de uma interface de rede.
- `work_order_service.dart`: acessa a API e classifica suas falhas.
- `work_order.dart`: converte o contrato de ordens e identifica ordens abertas.
- `app_navigation_bar.dart`: mantém os mesmos destinos inferiores na Home e em
  Work Orders; Histórico permanece apenas como destino não implementado.

## Tratamento de erros

- Sem rede/API inacessível: modo offline e mensagem de ausência de cache.
- HTTP 401: exclusão do token e retorno ao login.
- HTTP 404/500: “Não foi possível carregar as ordens de serviço.”
- Payload ou data inválida: “A API retornou dados em formato inesperado.”
- Erro inesperado: estado de disponibilidade indeterminado e nova tentativa.

## Limitações atuais

- Não há login offline; o primeiro login exige a API.
- Uma sessão previamente autenticada pode ser restaurada offline usando token e
  usuário local. HTTP 401 continua invalidando a sessão.
- A última sincronização ainda não é persistida.
- O sync automático ocorre somente enquanto a aplicação está ativa.

## Próximos passos

- Persistir o horário da última sincronização.
- Avaliar conciliação opcional com `GET /inspections`.
