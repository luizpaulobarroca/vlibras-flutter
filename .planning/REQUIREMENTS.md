# Requirements: vlibras_flutter

**Defined:** 2026-03-22
**Core Value:** Um desenvolvedor Flutter consegue exibir tradução de texto para LIBRAS em qualquer plataforma com um único Controller e Widget, sem precisar lidar com os SDKs nativos diretamente.

## v1 Requirements

Requirements para a primeira release publicável no pub.dev.

### API Core

- [ ] **CORE-01**: Developer pode instanciar um VLibrasController e associá-lo a um VLibrasView widget
- [ ] **CORE-02**: Developer pode chamar translate(String text) no controller para disparar a animação LIBRAS
- [ ] **CORE-03**: VLibrasController expõe VLibrasValue com estados: idle, loading, playing, error
- [ ] **CORE-04**: VLibrasController possui initialize() assíncrono para inicialização e dispose() para liberação de recursos

### Web Platform

- [ ] **WEB-01**: Plugin renderiza o avatar VLibras em Flutter Web usando HtmlElementView
- [ ] **WEB-02**: translate() envia texto ao web player VLibras e dispara a animação do avatar na view embutida

### Error Handling

- [ ] **ERR-01**: Erros de tradução/inicialização são expostos via VLibrasValue.error (sem exceções lançadas para o developer)

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

Populado durante criação do roadmap.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | — | Pending |
| CORE-02 | — | Pending |
| CORE-03 | — | Pending |
| CORE-04 | — | Pending |
| WEB-01 | — | Pending |
| WEB-02 | — | Pending |
| ERR-01 | — | Pending |
| PUB-01 | — | Pending |
| PUB-02 | — | Pending |
| PUB-03 | — | Pending |
| PUB-04 | — | Pending |

**Coverage:**
- v1 requirements: 11 total
- Mapped to phases: 0
- Unmapped: 11 ⚠️

---
*Requirements defined: 2026-03-22*
*Last updated: 2026-03-22 after initial definition*
