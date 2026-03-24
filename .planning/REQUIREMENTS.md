# Requirements: vlibras_flutter

**Defined:** 2026-03-22
**Core Value:** Um desenvolvedor Flutter consegue exibir tradução de texto para LIBRAS em qualquer plataforma com um único Controller e Widget, sem precisar lidar com os SDKs nativos diretamente.

## v1 Requirements

Requirements para a primeira release publicável no pub.dev.

### API Core

- [x] **CORE-01**: Developer pode instanciar um VLibrasController e associá-lo a um VLibrasView widget
- [x] **CORE-02**: Developer pode chamar translate(String text) no controller para disparar a animação LIBRAS
- [x] **CORE-03**: VLibrasController expõe VLibrasValue com estados: idle, loading, playing, error
- [x] **CORE-04**: VLibrasController possui initialize() assíncrono para inicialização e dispose() para liberação de recursos

### Web Platform

- [x] **WEB-01**: Plugin renderiza o avatar VLibras em Flutter Web usando HtmlElementView
- [x] **WEB-02**: translate() envia texto ao web player VLibras e dispara a animação do avatar na view embutida

### Error Handling

- [x] **ERR-01**: Erros de tradução/inicialização são expostos via VLibrasValue.error (sem exceções lançadas para o developer)

### Publication

- [ ] **PUB-01**: Plugin inclui app /example funcional demonstrando uso básico do Controller+View
- [ ] **PUB-02**: Toda API pública possui comentários dartdoc (classes, métodos, propriedades)
- [ ] **PUB-03**: README documenta instalação, uso básico e plataformas suportadas
- [ ] **PUB-04**: Plugin inclui testes unitários e/ou widget cobrindo o comportamento do controller

## v2 Requirements

Deferidos — não no roadmap atual.

### Mobile Platforms

- **MOB-01**: Plugin funciona em Android usando SDK vlibras-mobile-android via platform channels
- **MOB-02**: Plugin funciona em iOS usando SDK vlibras-mobile-ios via platform channels

### Differentiators

- **DIFF-01**: Fila de traduções — developer pode enfileirar múltiplos textos para execução sequencial
- **DIFF-02**: Callbacks de estado — onStarted, onCompleted, onError via streams
- **DIFF-03**: Customização do avatar (velocidade, aparência) se suportado pelos SDKs nativos
- **DIFF-04**: VLibrasView expõe builder pattern para UI condicional por estado

## Out of Scope

| Feature | Razão |
|---------|-------|
| Suporte desktop (Windows/macOS/Linux) | Foco em mobile e web; SDKs VLibras não existem para desktop |
| Motor de tradução próprio | Depende da infraestrutura VLibras; não reinventar a roda |
| Renderizar avatar em Flutter puro (sem SDK/WebView) | Inviável sem acesso aos assets 3D proprietários |
| Widgets de UI prontos (botões, painéis) | Responsabilidade do developer; plugin não impõe UI |
| Integração com state management específico (Riverpod/Bloc) | Plugin deve ser agnóstico de state management |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 2: Core Dart API | In Progress (scaffold done; VLibrasController in 02-02) |
| CORE-02 | Phase 3: Web Platform Integration | Complete |
| CORE-03 | Phase 2: Core Dart API | In Progress (VLibrasValue/Status done; controller in 02-02) |
| CORE-04 | Phase 2: Core Dart API | Complete |
| WEB-01 | Phase 3: Web Platform Integration | Complete |
| WEB-02 | Phase 3: Web Platform Integration | Complete |
| ERR-01 | Phase 2: Core Dart API | Complete |
| PUB-01 | Phase 4: Publication Readiness | Pending |
| PUB-02 | Phase 4: Publication Readiness | Pending |
| PUB-03 | Phase 4: Publication Readiness | Pending |
| PUB-04 | Phase 4: Publication Readiness | Pending |

**Coverage:**
- v1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-03-22*
*Last updated: 2026-03-24 after Phase 2 Plan 1 (scaffold + contracts)*
