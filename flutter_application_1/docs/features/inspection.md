# Feature — Inspeções locais e sincronização

## Fluxo local

```text
Work Order → formulário → SQLite → draft/pending
```

Rascunhos aceitam dados incompletos e nunca entram na fila. Ao concluir, a
observação deve ter ao menos 10 caracteres e foto, latitude e longitude são
obrigatórias. A foto selecionada é copiada para `inspection_photos` no diretório
persistente da aplicação.

## Identidade e status

O `clientId` é um UUID v4 criado uma única vez e persistido no SQLite. Editar um
rascunho ou tentar novamente não gera outro UUID.

- `draft`: edição local, não enviado;
- `pending`: pronto para envio;
- `synced`: confirmado pela API, com `serverId`;
- `failed`: tentativa falhou, com `errorMessage`.

## Sincronização

```text
pending/failed → POST /inspections multipart → synced/failed
```

Os itens são enviados sequencialmente. HTTP 200 idempotente e HTTP 201 são
sucesso. Falhas de rede e erros não transitórios ficam como `failed`, preservando
o motivo e o `clientId`. HTTP 401 não é tratado como sucesso e invalida a sessão.

O usuário pode sincronizar pela Home ou tentar novamente um item no histórico.
Uma transição de conectividade offline → online também dispara uma tentativa. O
`connectivity_plus` serve apenas como gatilho; o resultado do POST determina o
sucesso real.

## Histórico

O histórico usa o SQLite como fonte principal para também mostrar drafts,
pendências e falhas que ainda não existem no servidor. Há filtros por todos os
quatro status e ação de retry para itens `failed`.

## Limitações atuais

- Não há serviço de background; sync ocorre enquanto o app está ativo.
- A recuperação de imagem perdida por encerramento do Android durante a tela
  externa do `image_picker` ainda não foi implementada.
- `GET /inspections` está disponível no serviço, mas não é usado para conciliação.
- Campos dinâmicos e geofence continuam fora desta etapa.
