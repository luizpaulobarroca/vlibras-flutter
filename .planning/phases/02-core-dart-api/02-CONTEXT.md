# Phase 2: Core Dart API - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Construir a arquitetura Dart pura: VLibrasController + VLibrasValue + VLibrasPlatform (interface). Tudo compilável e testável com mocks — sem nenhuma plataforma real por baixo. Não entrega embedding web nem integração com o player VLibras (isso é Fase 3).

Requirements: CORE-01, CORE-03, CORE-04, ERR-01

</domain>

<decisions>
## Implementation Decisions

### Máquina de estados

- 6 estados: `idle` → `initializing` → `ready` → `translating` → `playing` → `error`
- `idle`: controller criado mas initialize() ainda não chamado
- `initializing`: initialize() em progresso
- `ready`: inicializado, aguardando translate()
- `translating`: translate() aceito, aguardando resposta do player
- `playing`: avatar animando
- `error`: falha em initialize() ou translate()
- translate() enquanto `translating` ou `playing` → **cancela a atual, inicia nova** (v1; fila é DIFF-01 v2)
- Após `error` → estado reseta automaticamente para `translating` quando translate() é chamado
- initialize() é **idempotente** — chamadas repetidas quando já `ready`/`translating`/`playing` são ignoradas

### Estrutura do VLibrasValue

- Campos: `status` (enum `VLibrasStatus`) + `error` (String?) — mínimo para v1
- Classe de dados imutável (`@immutable`), não sealed class
- Implementa `==` e `hashCode` (evita notificações desnecessárias no ValueNotifier)
- Implementa `copyWith()` para atualizações parciais internas
- `error` é `null` quando não há erro; String descritiva quando há

### Mecanismo de notificação

- `VLibrasController extends ChangeNotifier` e expõe `VLibrasValue value`
- Developer consome via `ValueListenableBuilder<VLibrasValue>` ou `addListener`
- Padrão Flutter estabelecido (idêntico a `VideoPlayerController`)

### Escopo da platform interface

- `VLibrasPlatform` é **abstract class** simples (sem `plugin_platform_interface` package — plugin não é federated)
- Métodos públicos expostos: `initialize()`, `translate(String text)`, `pause()`, `stop()`, `resume()`, `repeat()`, `setSpeed(double speed)`, `dispose()`
- `load()`, `on()`, `off()` são **implementação interna** da plataforma web (Fase 3) — não aparecem na interface
- Controller recebe implementação via **construtor com parâmetro opcional**: `VLibrasController({VLibrasPlatform? platform})`
- Em produção, Controller usa a implementação real (injetada pela camada web na Fase 3); em testes, recebe um mock

### Modelo de erro

- `VLibrasValue.error` é `String?` — mensagem legível, null quando sem erro
- Erros de `initialize()` e `translate()` tratados da mesma forma (ambos vão para `VLibrasValue.error`)
- A mensagem deve incluir contexto: `"Falha ao inicializar: ..."` ou `"Falha ao traduzir: ..."`
- `error` limpa imediatamente (volta a `null`) ao entrar no estado `translating`
- Controller usa `debugPrint` em modo debug para logar erros internamente — silencioso em release

### Claude's Discretion

- Nomes exatos dos valores do enum `VLibrasStatus` (desde que cubram os 6 estados acima)
- Estrutura de arquivos e diretórios dentro de `lib/`
- Detalhes dos unit tests (cobertura e estrutura dos mocks)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets

- `spike/lib/vlibras_js.dart`: Bindings dart:js_interop para o Player — **reutilizável na Fase 3** como base para a implementação web da VLibrasPlatform
  - `VLibrasPlayerInstance` com métodos: load, translate, pause, stop, resume, repeat, setSpeed, on, off
  - Padrão `.toJS` para callbacks Dart → JS confirmado como necessário
- `spike/lib/main.dart`: Exemplo de `HtmlElementView.fromTagName('div', onElementCreated: ...)` — referência para Fase 3

### Established Patterns

- `package:web` (não `dart:html`/`dart:js`) — Dart 3.7+, WASM-compatível; já usado no spike
- `dart:js_interop` + `dart:js_interop_unsafe` — necessário para `callAsConstructor`
- `HtmlElementView.fromTagName('div')` — abordagem de embedding confirmada como correta (arquitetura certa, target JS errado no spike)

### Integration Points

- Fase 3 implementará `VLibrasPlatform` com `VLibrasWebPlatform` — usará os bindings do spike
- `VLibrasController` é a única API pública que o developer Flutter toca; `VLibrasPlatform` é detalhe interno
- A Fase 2 não cria nenhum widget (VLibrasView é Fase 3) — apenas `VLibrasController` + `VLibrasValue` + `VLibrasPlatform`

</code_context>

<specifics>
## Specific Ideas

- Padrão de referência: `VideoPlayerController` + `VideoPlayerValue` do pacote `video_player` do Flutter — mesma estrutura Controller/Value/ChangeNotifier
- O spike de Fase 1 provou que os event names corretos são: `load`, `translate:start`, `animation:play`, `animation:pause`, `animation:end`, `animation:progress`
- `continue()` do Player colide com keyword Dart — workaround: `@JS('continue') external void resume()`

</specifics>

<deferred>
## Deferred Ideas

- Fila de traduções (translate() enquanto playing → enfileirar) — DIFF-01, deferido para v2
- VLibrasValue com campo `text` (texto em tradução) — pode ser adicionado sem breaking change em v2
- VLibrasValue com campo `progress` (0.0–1.0) — `animation:progress` event existe no Player, mas expor em v1 não é necessário para os SCs

</deferred>

---

*Phase: 02-core-dart-api*
*Context gathered: 2026-03-24*
