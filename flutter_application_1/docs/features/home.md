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

Como ainda não há cache de ordens, o modo offline informa: “Sem conexão e sem
ordens armazenadas localmente.” A estrutura já permite informar a presença de
dados locais quando essa persistência for implementada.

## Carregamento das ordens

O `WorkOrderService` reutiliza `ApiClient`, envia o token no header
`Authorization: Bearer <token>`, converte o JSON e classifica erros de conexão,
sessão, servidor e payload. A Home considera abertas ordens com status `open` ou
`in_progress`.

Não existe cache local nesta etapa. Portanto, o fluxo atual é:

```text
Online: API → resumo em memória → interface
Offline: mensagem sem cache → tentar novamente
```

## Resumo exibido

- Nome do usuário: real, recebido do `AuthGate`.
- Ordens abertas: real, calculado a partir de `GET /work-orders`.
- Inspeções pendentes: zero temporário; ainda não há banco local de inspeções.
- Falhas de sincronização: zero temporário; ainda não há fila local.

## Sincronização

Não existe fila de sincronização nem valor persistido de última sincronização.
Por isso:

- o banner mostra “Nenhuma sincronização realizada” quando online;
- o botão mostra “Nenhum item para sincronizar” e fica desabilitado;
- nenhuma sincronização fictícia é executada;
- os estados `pending` e `failed` serão conectados ao banco local futuramente.

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

- Não existe cache local de ordens.
- Não há login offline; o primeiro login exige a API.
- O `AuthGate` ainda valida a sessão na API ao iniciar o aplicativo, portanto uma
  inicialização totalmente offline ainda não abre a Home.
- Não há banco de inspeções, fila de sincronização ou última sincronização salva.
- O detalhe de uma ordem e o Histórico ainda não possuem páginas.

## Próximos passos

- Persistir usuário validado e ordens para permitir inicialização offline segura.
- Implementar o detalhe de ordens.
- Conectar inspeções pendentes e falhas ao banco local.
- Implementar fila e persistência da última sincronização.
