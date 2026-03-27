# Phase 4: Publication Readiness - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Tornar o plugin publicável no pub.dev: example app funcional, dartdoc na API pública, README, CHANGELOG, testes completos, e `flutter pub publish --dry-run` sem erros bloqueantes.

Requirements: PUB-01, PUB-02, PUB-03, PUB-04

</domain>

<decisions>
## Implementation Decisions

### Example app

- **UI polida** com branding VLibras, conteúdo informativo sobre o plugin e demonstração interativa
- **Avatar flutuante com snap para quinas**: o VLibrasView se comporta como uma janela flutuante que o usuário pode arrastar livremente; ao soltar, anima automaticamente para a quina mais próxima das 4 (top-left, top-right, bottom-left, bottom-right)
- **Sempre visível** — avatar não pode ser ocultado; flutua sobre todo o conteúdo da página
- **Tamanho fixo mas parametrizável** — tamanho padrão definido (ex: 200×200), mas o exemplo deixa clara a possibilidade de customizar
- **Conteúdo principal**: TextField para digitar texto livre + botão "Traduzir" que aciona `controller.translate()`
- **Indicadores de estado visíveis**: texto simples mostrando o `VLibrasValue.status` atual ("Inicializando...", "Traduzindo...", "Erro: ...") — educa o developer sobre como consumir o controller

### README

- **Idioma**: Português (público-alvo principal são desenvolvedores brasileiros; VLibras é iniciativa nacional)
- **Nível**: Essencial — o que é o plugin, instalação, uso básico com snippet de código, plataformas suportadas, setup dos assets VLibras (`target/` e script no `index.html`)
- **Sem screenshots** no MVP — texto e código são suficientes para o score pana v1

### CHANGELOG

- **Formato Keep a Changelog** — `## [0.1.0] - YYYY-MM-DD` com seções `Added` listando as capacidades entregues
- Entrada única para v0.1.0 (primeiro release)

### pubspec metadata

- **Licença**: MIT — arquivo `LICENSE` na raiz com texto MIT padrão
- **Versão**: `0.1.0` (pre-stable, indica release real mas não promete API frozen)
- **Homepage**: Claude escolhe URL adequada (repositório atual ou placeholder descritivo)
- **topics**: `accessibility`, `libras`, `sign-language`, `vlibras` — melhora descoberta no pub.dev
- **description**: melhorar para ser descritiva e clara (~100–180 chars)
- **plugin.platforms**: declarar `web: {}` explicitamente (atualmente vazio `{}`)
- **.pubignore**: excluir `build/`, `spike/`, `web/vlibras/target/` do pacote publicado (Unity assets são assets do app, não do pacote)

### Cobertura de testes

- **VLibrasView — expandir**: adicionar testes para `buildMobileView` em non-web (widget retornado pela plataforma), `onElementCreated` configura `id`/`style` no div corretamente, widget usa o controller fornecido
- **VLibrasWebPlatform — ampliar com casos de erro**:
  - Timeout expira sem `animation:end` → emite `VLibrasStatus.error` com mensagem descritiva
  - `translate()` chamado durante `playing` → cancela e reinicia (cancel-and-restart)
  - `initialize()` idempotente — segunda chamada ignorada quando já `ready`
- **Garantir que todos os testes existentes passam** com `flutter test` (exceto testes `@TestOn('browser')` que requerem Chrome)

### Claude's Discretion

- Implementação interna do snap animation (AnimationController, physics, curve de animação)
- Estrutura de arquivos interna do /example
- Exato texto das seções do README (desde que cubra os requisitos essenciais)
- URL do repositório no homepage (se não disponível, usar `https://github.com/example/vlibras_flutter`)
- Qual teste de View é VM-compilável vs browser-only

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/src/vlibras_controller.dart`: `VLibrasController` completo com `translate()`, `initialize()`, `dispose()`, `value` (VLibrasValue) — pronto para uso no /example
- `lib/src/vlibras_view.dart`: `VLibrasView` widget — base do avatar flutuante; precisa ser envolvido em widget de drag/snap no /example
- `lib/src/vlibras_value.dart`: `VLibrasStatus` com 6 estados — `initializing`, `translating`, `playing`, `error` são os relevantes para o indicador de estado no /example
- `test/mocks/mock_vlibras_platform.dart`: MockVLibrasPlatform com mocktail — reutilizável em todos os novos testes
- `test/vlibras_web_platform_test.dart`: FakePlayer já implementado — base para os novos casos de erro

### Established Patterns

- `ValueListenableBuilder<VLibrasValue>` — padrão para consumir estado no /example (já demonstrado no dartdoc do controller)
- `HtmlElementView.fromTagName('div', onElementCreated: ...)` — embedding confirmado funcional
- `flutter test` (VM) para testes de controller/value; `@TestOn('browser')` para testes de View e WebPlatform

### Integration Points

- `/example/lib/main.dart`: cria `VLibrasController`, chama `initialize()`, usa `VLibrasView` e `ValueListenableBuilder`
- `web/vlibras/vlibras.js`: asset do plugin; developer copia `target/` para `web/vlibras/target/` no app
- `pubspec.yaml`: atualizar `version`, `description`, `homepage`, `topics`, `flutter.plugin.platforms`
- `flutter pub publish --dry-run`: bloqueantes atuais são LICENSE (arquivo faltando) e README (faltando)

</code_context>

<specifics>
## Specific Ideas

- Avatar flutuante com snap para quinas: comportamento semelhante ao "chat bubble" flutuante do Facebook Messenger — arrasta livremente, ao soltar vai para a quina mais próxima com animação suave
- O /example deve ser uma landing page que também serve de demonstração — não apenas um app de teste
- VLibras é iniciativa do governo brasileiro (UFPB/RNP) — README deve contextualizar isso em português

</specifics>

<deferred>
## Deferred Ideas

- Screenshots no README — pode ser adicionado após publicação inicial, quando o app de exemplo estiver rodando
- Versão bilingue do README (EN + PT-BR) — baixa prioridade para v0.1.0
- Avatar redimensionável por gesto — DIFF-04, v2

</deferred>

---

*Phase: 04-publication-readiness*
*Context gathered: 2026-03-27*
