# Phase 3: Web Platform Integration - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Conectar o Controller+API (Fase 2) ao player VLibras real no Flutter Web. Entrega: VLibrasView renderiza o avatar 3D, controller.translate("texto") causa animação visível, estados idle → initializing → ready → translating → playing → ready são observáveis. Não entrega suporte a Android/iOS (v2), nem app de exemplo nem documentação de publicação (Fase 4).

Requirements: WEB-01, WEB-02, CORE-02

</domain>

<decisions>
## Implementation Decisions

### Abordagem do player

- **Self-hosted Player** (vlibras-player-webjs) — única opção com translate() totalmente programático
- `vlibras.js` pre-compilado commitado em `web/` do plugin (não gerado em build step)
- Assets Unity WebGL (`target/`) ficam em `web/` do app Flutter — developer os adiciona manualmente
- `targetPath` fixado em `/vlibras/target` por convenção (sem parâmetro configurável em v1)
- Translator API fixado em `https://vlibras.gov.br/api` (sem parâmetro configurável em v1)
- `index.html` do app requer apenas `<script src="/vlibras/vlibras.js"></script>`; nenhuma estrutura HTML adicional necessária

### VLibrasView

- Widget preenche constraints do parent (developer usa `SizedBox`, `Expanded`, etc. — padrão Flutter)
- Sem UI própria de loading: durante `initializing`, a área fica vazia/preta; developer usa `VLibrasController.value` para mostrar seu próprio indicador
- Sem overlay de erro embutido: developer usa `ValueListenableBuilder<VLibrasValue>` para construir UI de erro
- Background transparente *(nota: viabilidade depende do renderer Unity WebGL do vlibras-player-webjs; investigar durante implementação)*

### Push de estado da plataforma

- `VLibrasWebPlatform` recebe um callback `void Function(VLibrasStatus)` no construtor para notificar o controller de transições de estado
- `animation:play` → callback(VLibrasStatus.playing)
- `animation:end` → callback(VLibrasStatus.ready)
- `translate()` no controller completa (`Future` resolve) quando `animation:end` dispara — developer pode `await controller.translate()` para esperar a animação completa
- Timeout configurável no `VLibrasWebPlatform` (default: 30s); se `animation:end` não chegar no prazo, emite erro via callback

### Registro da plataforma

- Conditional import em `VLibrasController`: `if (dart.library.io) platform/unsupported_platform.dart` / web usa `platform/web_platform.dart`
- `VLibrasController()` sem argumentos funciona automaticamente em Flutter Web (registra `VLibrasWebPlatform`)
- Em plataformas não-suportadas: lança `UnsupportedError` com mensagem clara ("vlibras_flutter suporta apenas Flutter Web em v1")
- `VLibrasWebPlatform` é detalhe interno de implementação — não exportada na API pública

### Claude's Discretion

- Estrutura de arquivos de `VLibrasWebPlatform` e `VLibrasJs` dentro de `lib/src/`
- Nomes das variáveis JS interop internas
- Como cancel-and-restart é implementado quando translate() é chamado durante playing (Fase 2 decidiu o comportamento; Fase 3 decide a mecânica)
- Valor exato do timeout padrão (em torno de 30s)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/src/vlibras_platform.dart`: Interface `VLibrasPlatform` — `VLibrasWebPlatform` implementará `initialize()`, `translate()`, `pause()`, `stop()`, `resume()`, `repeat()`, `setSpeed()`, `dispose()`
- `lib/src/vlibras_controller.dart`: `VLibrasController` pronto; Phase 3 substitui `_defaultPlatform()` por conditional import + `VLibrasWebPlatform`
- `lib/src/vlibras_value.dart`: `VLibrasStatus` com 6 estados já definidos: idle, initializing, ready, translating, playing, error
- Spike `spike/lib/vlibras_js.dart`: Bindings dart:js_interop para `VLibrasPlayerInstance` — reutilizável como base para `lib/src/vlibras_js.dart`
- Spike `spike/lib/main.dart`: Exemplo de `HtmlElementView.fromTagName('div', onElementCreated: ...)` — referência direta para `VLibrasView`

### Established Patterns

- `package:web` (não `dart:html`/`dart:js`): padrão Dart 3.7+, WASM-compatível; já confirmado no spike
- `dart:js_interop` + `dart:js_interop_unsafe`: necessário para `callAsConstructor` no construtor do Player
- `HtmlElementView.fromTagName('div')`: abordagem de embedding confirmada como correta
- `.toJS` em todos callbacks Dart→JS: obrigatório (confirmado no spike — omitir causa runtime error)
- `@JS('continue') external void resume()`: workaround para colisão com keyword Dart

### Integration Points

- `VLibrasController._defaultPlatform()`: substituído por conditional import para `VLibrasWebPlatform` em Phase 3
- `VLibrasController.translate()` e `VLibrasController.initialize()`: já gerenciam transições de estado; Phase 3 adiciona as transições `translating → playing → ready` via callback da plataforma
- Barrel export `lib/vlibras_flutter.dart`: adicionar `VLibrasView` às exportações públicas
- `web/` do plugin: adicionar `vlibras.js` (bundle do vlibras-player-webjs)

</code_context>

<specifics>
## Specific Ideas

- Developer do app precisa de duas etapas de setup: (1) copiar assets `target/` para `web/vlibras/target/`, (2) adicionar `<script src="/vlibras/vlibras.js"></script>` no `index.html`
- Fase 1 confirmou: event names do Player são `load`, `translate:start`, `animation:play`, `animation:pause`, `animation:end`, `animation:progress`
- O evento `error` pode não existir no Player — verificar `GlosaTranslator` source durante implementação
- Background transparente do avatar é o objetivo; se Unity WebGL não suportar, fallback é preto (documentar limitação)

</specifics>

<deferred>
## Deferred Ideas

- Fila de traduções (translate() enquanto playing → enfileirar) — DIFF-01, v2 (já decidido em Fase 2)
- `targetPath` e `translatorUrl` configuráveis via controller/view — v2 se houver demanda
- Suporte a Android/iOS (vlibras-mobile-android/ios SDKs via platform channels) — v2 (MOB-01, MOB-02)
- Investigação de licença VLibras para pub.dev — explicitamente reservado para Fase 4 (phase-01-findings.md §6)

</deferred>

---

*Phase: 03-web-platform-integration*
*Context gathered: 2026-03-24*
