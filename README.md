# CollimaScope

**Colimação de telescópios Newtonianos e Dobsonianos com a câmera do celular.**

O CollimaScope é um assistente visual com guias ajustáveis para auxiliar o
aprendizado e a inspeção aproximada da colimação: a câmera olha pelo
focalizador e o app desenha, por cima da imagem ao vivo,
círculos de referência geometricamente perfeitos, mira central, marcadores
de parafusos e grade — guiando um fluxo de 7 etapas que vai da verificação da
imagem da câmera até a validação em estrela. Tudo offline, sem conta, sem
rastreamento e com uma única permissão: a câmera.

**[⬇️ Baixar o APK (Releases)](https://github.com/AmaroMiranda/collima_scope/releases)** —
requer Android 7+ e câmera traseira.

## Recursos

- **Fluxo guiado em 7 etapas** — cada etapa traz objetivo, instrução e as
  guias visuais adequadas já posicionadas; notas ópticas aparecem quando a
  física do telescópio pede (ex.: offset aparente do secundário em
  Newtonianos rápidos).
- **Círculos que nunca achatam** — a regra central do app: guias principais
  são círculos perfeitos definidos só por centro e raio. Não existe
  largura/altura nem escala X/Y em nenhuma guia de referência.
- **Editor de guias em painel compacto** — chips para selecionar qualquer
  guia da etapa, sliders de raio/espessura/opacidade, 6 cores predefinidas,
  travar/ocultar/centralizar/duplicar/excluir — sem cobrir o preview.
- **Modo avançado** — quem já tem o adaptador alinhado pode iniciar sem as
  verificações iniciais (com aviso claro de perda de precisão); um seletor de etapas permite saltar para qualquer estágio a
  qualquer momento.
- **Perfis de equipamento** — telescópios (abertura, focal, focalizador 1,25"/2",
  marca central, nº de parafusos, offset do secundário) e adaptadores de
  celular ficam salvos para reuso entre sessões.
- **Histórico com antes/depois** — cada sessão registra capturas por etapa;
  a exportação grava a imagem com o overlay de guias desenhado por cima.
- **Modo vermelho** — tema noturno em tons de vermelho para preservar a
  adaptação da visão ao escuro no campo.
- Interface escura, em português (pt-BR), Material Design 3.

## As 7 etapas

| # | Etapa | Objetivo |
|---|---|---|
| 1 | Verificar imagem da câmera | Identificar deformações visíveis: a borda circular de referência deve parecer regular em pé e deitado (não substitui calibração geométrica medida) |
| 2 | Alinhar câmera ao focalizador | Reduzir deslocamento e inclinação da câmera em relação ao eixo do focalizador (alinhamento manual) |
| 3 | Centralizar no focalizador | Fazer o círculo-guia coincidir com a borda interna do tubo do focalizador |
| 4 | Posicionar o secundário | Posicionar o secundário sob o focalizador, respeitando a geometria (offset aparente é normal em alguns Newtonianos) |
| 5 | Secundário → primário | Ajustar o secundário até o primário inteiro aparecer no círculo, com a marca central sobre a mira |
| 6 | Ajustar primário | Colimar o primário até o reflexo da marca central coincidir com a mira, com anéis concêntricos e marcadores dos parafusos como referência |
| 7 | Validação em estrela | Star test: estrela brilhante centralizada e desfocada deve mostrar anéis simétricos |

O app é um assistente visual — ele não emite instruções ópticas do tipo
"gire o parafuso X em Y graus". A precisão final vem do preview sem
distorção, dos círculos de referência e do alinhamento físico do celular
ao focalizador.

## Como funciona

| Peça | Onde | O que faz |
|---|---|---|
| `ViewportTransform` | `core/viewport/` | mapeia coordenadas entre sensor → preview → widget com **escala sempre uniforme** (mesmo fator em X e Y), tanto em `cover` quanto em `contain` — é isso que garante círculo perfeito em qualquer orientação e resolução |
| `Point2D` | `core/geometry/` | coordenadas normalizadas (0.0–1.0) independentes de pixels; raios são fração do menor lado visível |
| Guias | `features/collimation/domain/` | hierarquia `sealed` — `CircleGuide`, `CrosshairGuide`, `GridGuide`, `ScrewMarkerGuide`, `SpiderGuide` — serializada em JSON por etapa |
| `GuidePainter` | `shared/painters/` | `CustomPainter` que desenha as guias sobre o preview; círculos principais nunca passam por `drawOval` |
| Workflow | `features/collimation/` | `CollimationWorkflowEngine` define textos, notas ópticas e guias padrão de cada etapa; o controller (Riverpod) gerencia sessão, navegação e edições |
| Persistência | `core/storage/` | perfis, sessões e guias em armazenamento local (`SharedPreferences`) — nada sai do aparelho |

Decisões de projeto que valem conhecer antes de contribuir:

- **A elipse é só diagnóstico.** Existe uma `DiagnosticEllipse` no domínio,
  mas ela nunca pode ser usada como referência principal — se um círculo de
  referência parecer oval, o problema é o preview (etapa 1), não a guia.
- **Escala uniforme é inegociável.** Qualquer mudança no viewport precisa
  manter o mesmo fator de escala em X e Y. `BoxFit.fill` e afins são bugs
  por definição neste app.
- **Guias padrão são ponto de partida, não verdade.** Cada etapa nasce com
  guias sensatas (`defaultGuides`), mas o usuário pode editar, duplicar e
  reposicionar tudo — o estado editado é o que persiste na sessão.

## Compilando

Requisitos:

- Flutter (canal estável) com as ferramentas de Android

```bash
git clone https://github.com/AmaroMiranda/collima_scope.git
cd collima_scope
flutter pub get
flutter run            # dispositivo real recomendado (precisa de câmera)
```

Release:

```bash
flutter build apk --release
```

O emulador funciona para navegar na interface, mas a validação de verdade
pede um aparelho real apontado para um focalizador — o preview da câmera é o
coração do app.

## Testes

```bash
flutter test
```

A suíte cobre o `ViewportTransform` (escala uniforme, cover/contain,
rotações), a serialização das guias, o controller do fluxo de colimação e a
exportação com overlay.

## Estrutura do projeto

```
lib/
  app/                  MaterialApp, tema (escuro + modo vermelho), rotas
  core/
    geometry/           Point2D normalizado
    viewport/           ViewportTransform (escala uniforme)
    camera/             engine da câmera (plugin camera)
    storage/            persistência local
    export/             exportação de captura com overlay
  features/
    collimation/        workflow, controller, tela da câmera, editor de guias
    telescope_profile/  perfis de telescópio (CRUD)
    adapter_profile/    perfis de adaptador (CRUD)
    history/            sessões, capturas antes/depois, detalhe
    guide/              guia educativo das etapas
    home/               tela inicial
  shared/painters/      GuidePainter (CustomPainter das guias)
test/                   viewport, guias, controller, exportação
```

## Segurança e privacidade

- Nenhuma chave de API, nenhum backend, nenhum rastreamento
- Funciona 100% offline; dados ficam no aparelho
- Permissão única: câmera

## Contribuindo

1. Fork, branch (`git checkout -b feature/sua-ideia`), commits descritivos, PR.
2. **Respeite a regra dos círculos**: qualquer PR que introduza escala
   não-uniforme no viewport ou desenhe guia principal como elipse será
   recusado — essa é a invariante que faz o app funcionar.
3. Mudanças de comportamento óptico (textos das etapas, notas, guias padrão)
   devem citar a referência de colimação que as justifica.
4. Teste em dispositivo real antes de abrir o PR.

Ideias já mapeadas para V2: detecção automática de círculos (OpenCV),
análise de desalinhamento assistida, suporte a SCT/RC e refratores, iOS.

## FAQ

**Preciso de um adaptador de celular?**
Não é obrigatório para explorar o app, mas para colimar de verdade sim: a
câmera precisa estar estável e centralizada no focalizador. Qualquer suporte
universal de ocular funciona.

**O círculo de teste parece oval. E agora?**
Não continue — é exatamente para isso que a etapa 1 existe. Verifique se o
preview não está sendo esticado por alguma configuração de tela/zoom do
aparelho e reinicie a sessão.

**Funciona em SCT, RC ou refrator?**
O fluxo atual foi desenhado para Newtonianos e Dobsonianos. Outros desenhos
ópticos estão no radar da V2.

**Funciona em iPhone?**
Ainda não — Android primeiro. iOS depende de demanda (e de um Mac por perto).

## Licença

Copyright 2026 Amaro Miranda

Licenciado sob a [MIT License](LICENSE).
