# Phase 1: SDK Investigation Spike - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Verificar se o web player VLibras pode ser carregado e controlado dentro de um Flutter Web HtmlElementView, e documentar a superfície exata da API JS necessária para translate e callbacks de estado. Não entrega código de produção — entrega conhecimento validado para as Fases 2 e 3.

</domain>

<decisions>
## Implementation Decisions

### Artefatos do spike

- Código é **descartável** — prova conceito, não é base para a Fase 3
- Vive em `spike/` na raiz do repositório, separado do código do plugin
- Deletado após a conclusão da Fase 1 (achados ficam no documento)
- Criado com `flutter create` padrão com suporte a Web habilitado
- Inclui README mínimo com comandos para rodar (`flutter run -d chrome`)
- Inclui integration tests básicos rodando apenas em Chrome interativo (não headless)

### Documentação dos achados

- Documento principal: `.planning/research/phase-01-findings.md`
- Inclui snippets Dart usando `dart:js_interop` mostrando como chamar cada função JS descoberta
- Registra dead ends (o que foi tentado e não funcionou + razão)
- Inclui seção dedicada de licenciamento do VLibras para redistribuição via pub.dev
- Estrutura do documento: API surface (init/translate/eventos), URLs/CDN, CSP/CORS, dead ends, licença

### Abordagem de embedding

- **Primeira abordagem**: HtmlElementView + dart:html — cria `<div>` via dart:html, injeta script VLibras, registra como HtmlElementView
- **Plano B** (se HtmlElementView falhar): iframe + postMessage para comunicação Dart↔player
- Player carregado via CDN público primeiro (URLs oficiais vlibras.gov.br)
- Testa apenas a versão mais recente disponível no CDN
- Usar **dart:js_interop** (Dart 3+), não dart:js clássico

### Escopo da investigação

- Mapear o init flow explícito (se `VLibras.init()` existe ou carrega automaticamente)
- Mapear todos os callbacks/eventos de estado disponíveis: onStarted, onCompleted, onError e similares
- Investigar implicações do Unity WebGL do player vs CanvasKit do Flutter Web (potencial conflito de contexto WebGL)
- Verificar requisitos de CSP e CORS necessários no `index.html` do Flutter Web
- Prototipar estrutura básica com `@JS` annotations para as funções descobertas

### Claude's Discretion

- Estrutura interna do README do spike
- Quais integration tests específicos implementar (além de verificar loading básico)
- Detalhes da estrutura `@JS` no spike (pode ser simples, é descartável)

</decisions>

<specifics>
## Specific Ideas

- O maior risco técnico identificado é conflito entre o WebGL do Unity (player VLibras) e o CanvasKit do Flutter Web — investigar isso explicitamente
- Se HtmlElementView não funcionar por conflito de canvas, fallback é iframe + postMessage
- A licença do VLibras é um blocker para pub.dev identificado no STATE.md — resolver no spike evita surpresa na Fase 4

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets

- Nenhum — projeto em branco, primeira fase

### Established Patterns

- Nenhum padrão estabelecido ainda

### Integration Points

- `spike/` será criado como projeto Flutter standalone (não integrado ao plugin ainda)
- Achados do spike alimentam diretamente a Fase 2 (design de VLibrasValue states) e Fase 3 (implementação do HtmlElementView real)

</code_context>

<deferred>
## Deferred Ideas

- Nenhuma — discussão ficou dentro do escopo da fase

</deferred>

---

*Phase: 01-sdk-investigation-spike*
*Context gathered: 2026-03-23*
