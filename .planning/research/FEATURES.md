# Feature Landscape

**Domain:** Plugin Flutter multiplataforma para traducao texto-para-LIBRAS via VLibras
**Researched:** 2026-03-22
**Confidence:** MEDIUM (based on training data knowledge of Flutter plugin patterns, VLibras SDK surface, and accessibility plugin conventions; web verification tools were unavailable)

---

## Table Stakes

Features que usuarios (desenvolvedores Flutter) esperam. Ausencia = plugin nao e adotado.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **TS-01: VLibrasController** | Padrao Flutter estabelecido (video_player, webview_flutter, camera). Desenvolvedores esperam controlar o widget via controller, nao via GlobalKey ou callbacks soltos. | Med | Core da API. Gerencia lifecycle, envia textos, expoe estado. Deve extender `ValueNotifier<VLibrasState>` ou usar `ChangeNotifier`. |
| **TS-02: VLibrasView widget** | O complemento natural do controller. Um widget declarativo que renderiza o avatar 3D. Sem widget = nao e um plugin Flutter, e uma lib de bindings. | Med | `PlatformView` no mobile (AndroidView/UiKitView), `HtmlElementView` na web. Deve aceitar o controller como parametro obrigatorio. |
| **TS-03: translate(String text)** | Funcionalidade core do produto. Sem isso, o plugin nao faz nada. | Low | Metodo no controller. Envia texto para o SDK nativo e o avatar executa a traducao. |
| **TS-04: Suporte Android** | Plataforma mobile dominante no Brasil (~85% market share). Sem Android = irrelevante para o publico-alvo. | High | Requer platform channel para vlibras-mobile-android. PlatformView com AndroidView. |
| **TS-05: Suporte iOS** | Complemento obrigatorio para publicacao no pub.dev como plugin multiplataforma serio. | High | Requer platform channel para vlibras-mobile-ios. PlatformView com UiKitView. |
| **TS-06: Suporte Web** | VLibras web player (Unity WebGL) e o mais maduro dos SDKs. Muitos apps Flutter sao web-first. | Med | HtmlElementView com o vlibras-web-player. Possivelmente mais simples que mobile por ser JS interop direto. |
| **TS-07: State management via ValueNotifier/Stream** | Desenvolvedores precisam reagir a estados (carregando, traduzindo, idle, erro). Sem isso, nao ha como construir UI responsiva ao redor do avatar. | Med | `VLibrasState` enum ou sealed class: `uninitialized`, `loading`, `ready`, `translating`, `error`. Controller expoe via `value` (ValueNotifier) ou Stream. |
| **TS-08: Lifecycle management (init/dispose)** | Leak de recursos nativos e o bug #1 em plugins Flutter. Controller DEVE ter `initialize()` e `dispose()` explicitos. | Med | `initialize()` carrega o SDK nativo. `dispose()` libera. Deve integrar com o widget lifecycle automaticamente quando possivel. |
| **TS-09: Error handling basico** | Desenvolvedores precisam saber quando algo falha (SDK nao carregou, texto invalido, rede indisponivel). | Low | Erros expostos via estado (`VLibrasState.error(message)`) e/ou `onError` callback. Nunca engolir excecoes silenciosamente. |
| **TS-10: Exemplo minimo funcional (/example)** | Requisito de facto para publicacao no pub.dev. Sem example = pontuacao baixa no pub.dev, ninguem adota. | Low | App Flutter minimo demonstrando controller + widget + translate. Um main.dart com < 100 linhas. |
| **TS-11: Documentacao de API publica** | pub.dev gera docs automaticamente via dartdoc. API sem documentacao = pontuacao baixa, ninguem adota. | Low | Dartdoc comments em todas as classes/metodos publicos. README com quickstart. |

---

## Diferenciadores

Features que separam este plugin de uma integracao "crua". Nao esperadas, mas geram valor significativo.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **DF-01: Fila de textos (translation queue)** | Permite enviar multiplos textos em sequencia sem esperar cada um terminar. Crucial para apps que traduzem conteudo dinamico (chat, feed de noticias). Nenhum wrapper VLibras existente oferece isso. | Med | Controller mantem uma fila interna. Cada texto e traduzido em sequencia. Expoe estado da fila (quantos pendentes). Metodos: `enqueue(String)`, `clearQueue()`, `queue` getter. |
| **DF-02: Callbacks granulares de progresso** | Alem de "traduzindo/idle", informar quando cada frase/palavra comeca e termina. Permite sincronizar UI (highlight de texto sendo traduzido). | High | Depende do que o SDK nativo expoe. Se o SDK emite callbacks por glosa/sinal, mapear para Dart. Se nao, e INVIAVEL sem fork do SDK. **Necessita verificacao da API nativa.** |
| **DF-03: Customizacao visual do avatar** | Permitir ajustar aparencia do Hugo (cor de pele, roupa, fundo). Apps corporativos querem alinhar com brand guidelines. | Med | Depende do SDK nativo suportar isso. VLibras web player historicamente suporta algumas opcoes de customizacao. Expor via `VLibrasConfig` ou `VLibrasTheme`. |
| **DF-04: Controle de velocidade da traducao** | Usuarios surdos tem diferentes niveis de fluencia. Velocidade ajustavel e feature de acessibilidade genuina. | Low | Se o SDK nativo suportar playback speed (provavel no web player, incerto nos SDKs mobile). Metodo `setSpeed(double)` no controller. |
| **DF-05: Widget builder pattern** | `VLibrasBuilder(controller, builder: (context, state, child) => ...)` permite UI reativa sem boilerplate. Similar ao `ValueListenableBuilder` mas tipado. | Low | Widget puro Dart, sem dependencia de plataforma. Conveniencia sobre `ValueListenableBuilder<VLibrasState>`. |
| **DF-06: Accessibility-first Semantics** | O plugin de acessibilidade DEVE ser acessivel. Widget com Semantics corretos para screen readers, anunciando estado da traducao. | Low | `Semantics` widget wrapping o PlatformView. Labels dinamicos: "Avatar VLibras traduzindo: [texto]". Ironia nao intencional se faltar. |
| **DF-07: Suporte a glosas (alem de texto)** | Permitir enviar glosas LIBRAS diretamente (nao apenas texto portugues). Para apps que ja tem motor de traducao proprio. | Low | Metodo `translateGloss(String gloss)` no controller. VLibras SDK nativo provavelmente aceita glosas diretamente. E um bypass do motor de traducao. |
| **DF-08: Modo compacto / mini-player** | Widget redimensionavel que funciona como overlay flutuante ou inline pequeno. Comum no VLibras web (icone no canto que expande). | Med | Requer gerenciamento de tamanho do PlatformView. Possivelmente dois modos: `VLibrasView.compact()` e `VLibrasView.expanded()`, ou parametros de sizing. |
| **DF-09: Preloading / warm-up** | Permitir inicializar o SDK antes de mostrar o widget, para que a primeira traducao seja instantanea. SDKs Unity/WebGL tem cold start significativo. | Med | `VLibrasController.initialize()` chamado no initState de uma tela anterior. Controller fica `ready` antes do widget ser montado. |
| **DF-10: Platform capability query** | Permitir ao dev verificar se a plataforma atual suporta VLibras antes de mostrar UI. `VLibras.isSupported` static method. | Low | Verifica plataforma + disponibilidade do SDK. Retorna bool. Util para mostrar/esconder botao de LIBRAS condicionalmente. |

---

## Anti-Features

Features deliberadamente FORA do escopo. Construi-las seria prejudicial.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **AF-01: Motor de traducao proprio** | VLibras ja tem motor de traducao mantido pela UFPB/RNP com anos de pesquisa linguistica. Reimplementar e reinventar a roda com qualidade inferior. O projeto explicitamente usa infraestrutura VLibras existente. | Delegar 100% da traducao para o SDK VLibras. O plugin e uma ponte, nao um tradutor. |
| **AF-02: Renderizacao propria do avatar** | O avatar Hugo e renderizado via Unity (mobile) ou WebGL (web). Tentar renderizar em Flutter puro (Canvas/CustomPainter) seria anos de trabalho para resultado inferior. | Usar PlatformView para embedar a renderizacao nativa do SDK. |
| **AF-03: Suporte a desktop (Windows/macOS/Linux)** | Nao ha SDK VLibras oficial para desktop. O web player poderia teoricamente rodar via webview em desktop, mas a complexidade e alta e a demanda e baixa. PROJECT.md ja exclui. | Focar em mobile + web. Se desktop for demandado no futuro, considerar embedding de webview com o web player. |
| **AF-04: Cache/persistencia de traducoes** | Gravar animacoes traduzidas para replay offline parece util, mas envolve armazenamento de dados de animacao 3D, questoes de licenciamento do conteudo VLibras, e complexidade de sincronizacao. | Cada traducao e feita on-the-fly. Se o usuario precisa de cache, e responsabilidade da camada de aplicacao. |
| **AF-05: Reconhecimento de LIBRAS (camera -> texto)** | Direcao oposta (LIBRAS para texto) e um problema de computer vision completamente diferente. Misturar no mesmo plugin dilui o foco. | Se demandado, seria um plugin separado. Este plugin faz SOMENTE texto -> LIBRAS. |
| **AF-06: Internacionalizacao para outras linguas de sinais** | VLibras e especifico para LIBRAS (Lingua Brasileira de Sinais). Tentar suportar ASL, BSL, LSF etc. exigiria motores de traducao completamente diferentes. | Nome do pacote e `vlibras_flutter`, nao `sign_language_flutter`. Escopo e LIBRAS via VLibras. |
| **AF-07: Gerenciamento de estado global** | Nao fornecer Provider/Bloc/Riverpod integration built-in. Acoplar a um gerenciador de estado especifico limita adocao. | Controller e `ChangeNotifier`/`ValueNotifier` padrao. Qualquer state management funciona nativamente com isso. |
| **AF-08: Widget de UI pronto (botao, overlay)** | Fornecer botao "traduzir para LIBRAS" com design pronto acopla o visual do app do usuario. | Fornecer apenas o VLibrasView (avatar) e o controller. O desenvolvedor cria seus proprios botoes/overlays. O /example pode demonstrar um padrao. |

---

## Feature Dependencies

```
TS-01 (VLibrasController) --> TS-02 (VLibrasView) [View requer Controller]
TS-01 (VLibrasController) --> TS-03 (translate) [translate e metodo do Controller]
TS-01 (VLibrasController) --> TS-07 (State management) [State e exposto pelo Controller]
TS-01 (VLibrasController) --> TS-08 (Lifecycle) [init/dispose sao do Controller]

TS-02 (VLibrasView) --> TS-04 (Android) [View usa AndroidView internamente]
TS-02 (VLibrasView) --> TS-05 (iOS) [View usa UiKitView internamente]
TS-02 (VLibrasView) --> TS-06 (Web) [View usa HtmlElementView internamente]

TS-07 (State management) --> TS-09 (Error handling) [Erros sao um estado]

TS-03 (translate) --> DF-01 (Fila) [Fila e uma extensao de translate]
TS-03 (translate) --> DF-07 (Glosas) [Glosas e um tipo alternativo de translate]

TS-07 (State management) --> DF-02 (Callbacks granulares) [Callbacks refinam o estado]
TS-07 (State management) --> DF-05 (Widget builder) [Builder consome estado]

TS-08 (Lifecycle) --> DF-09 (Preloading) [Preload e um uso avancado de init]

DF-03 (Customizacao avatar) --> depende da API do SDK nativo [VERIFICAR]
DF-04 (Velocidade) --> depende da API do SDK nativo [VERIFICAR]
DF-02 (Callbacks granulares) --> depende da API do SDK nativo [VERIFICAR]
```

### Diagrama simplificado de camadas

```
Camada Dart (API publica):
  VLibrasController -+-> translate() / enqueue()
                     +-> state (ValueNotifier<VLibrasState>)
                     +-> initialize() / dispose()
  VLibrasView ---------> PlatformView wrapper
  VLibrasBuilder ------> convenience widget

Camada Platform Channel:
  MethodChannel / EventChannel <-> Platform-specific code

Camada Nativa:
  Android: vlibras-mobile-android SDK
  iOS: vlibras-mobile-ios SDK
  Web: vlibras-web-player (JS interop)
```

---

## MVP Recommendation

### Fase 1 - Fundacao (DEVE ter para primeira release)

Priorizar:
1. **TS-01: VLibrasController** - Core absoluto. Tudo depende disso.
2. **TS-02: VLibrasView** - Sem widget visivel, nao ha produto.
3. **TS-03: translate(text)** - Funcionalidade minima viavel.
4. **TS-07: State management** - Sem estado, o dev nao sabe o que esta acontecendo.
5. **TS-08: Lifecycle** - Sem dispose, o plugin vaza recursos.
6. **TS-09: Error handling** - Sem erros, o dev nao consegue debugar.
7. **UMA plataforma** (TS-06 Web OU TS-04 Android) - Comecar por uma, validar a API, depois expandir.

### Fase 2 - Multiplataforma

8. **Restante das plataformas** (TS-04, TS-05, TS-06).
9. **TS-10: Exemplo funcional** - Necessario antes de pub.dev.
10. **TS-11: Documentacao** - Necessario antes de pub.dev.

### Fase 3 - Diferenciadores

11. **DF-01: Fila de textos** - Maior valor agregado com complexidade moderada.
12. **DF-05: Widget builder** - Conveniencia barata que melhora DX.
13. **DF-06: Accessibility Semantics** - Ironia inaceitavel se um plugin de acessibilidade nao for acessivel.
14. **DF-10: Platform capability query** - Simples e util.

### Deferir para releases futuras

- **DF-02: Callbacks granulares** - Depende de investigacao do SDK nativo. Pode ser inviavel.
- **DF-03: Customizacao do avatar** - Depende do SDK. Nice to have.
- **DF-04: Velocidade** - Depende do SDK.
- **DF-08: Modo compacto** - Estilizacao, nao funcionalidade core.
- **DF-09: Preloading** - Otimizacao prematura na Fase 1.

### Qual plataforma primeiro?

**Recomendacao: Web primeiro.** Razoes:
1. O vlibras-web-player e o SDK mais documentado e maduro do VLibras.
2. JS interop no Flutter web e mais direto que platform channels nativos.
3. Permite validar toda a API Dart (controller, state, lifecycle) sem a complexidade de PlatformViews nativos.
4. Ciclo de iteracao mais rapido (hot reload web, sem build nativo).
5. Uma vez que a API Dart esta solida, adicionar Android/iOS e "apenas" a camada de platform channel.

**Alternativa valida: Android primeiro** se o objetivo e mobile-first e o dev tem mais experiencia com Android nativo. O SDK Android do VLibras tem exemplos mais claros de integracao.

---

## Notas sobre Verificacao Pendente

As seguintes features dependem de verificacao da API real dos SDKs nativos VLibras:

| Feature | O que verificar | Onde verificar |
|---------|----------------|---------------|
| DF-02 (Callbacks granulares) | SDK emite eventos por sinal/glosa traduzida? | Codigo fonte dos SDKs mobile e web player |
| DF-03 (Customizacao avatar) | Quais parametros de aparencia o SDK aceita? | API do web player (JS), SDKs mobile |
| DF-04 (Velocidade) | SDK aceita parametro de velocidade de animacao? | API do web player, SDKs mobile |
| DF-07 (Glosas) | SDK aceita glosas diretamente alem de texto PT? | Documentacao/codigo fonte dos SDKs |
| DF-09 (Preloading) | SDK permite inicializacao sem view visivel? | Testes praticos com os SDKs |

**Recomendacao: Clonar os repos dos SDKs e inspecionar as APIs publicas antes de iniciar implementacao.** Isso transformaria varias features de "MEDIUM confidence" para "HIGH confidence".

---

## Sources

- Padroes de API Flutter baseados em plugins oficiais: `video_player`, `webview_flutter`, `camera`, `google_maps_flutter` (training data, MEDIUM confidence)
- VLibras como iniciativa governamental UFPB/RNP: https://www.vlibras.gov.br/ (training data, MEDIUM confidence)
- Repositorios VLibras: https://github.com/orgs/spbgovbr-vlibras/repositories (referenced in PROJECT.md, nao verificados diretamente nesta sessao)
- Convencoes pub.dev para pontuacao de pacotes (training data, HIGH confidence - padrao estavel)
- Market share Android no Brasil ~85% (training data, MEDIUM confidence - dado aproximado)

**Nota de confianca geral:** Web search tools estavam indisponiveis durante esta pesquisa. Todas as recomendacoes sao baseadas em conhecimento de treinamento sobre Flutter plugin patterns e o ecossistema VLibras. Verificacao com documentacao oficial dos SDKs VLibras e fortemente recomendada antes de finalizar o roadmap.
