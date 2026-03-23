# vlibras_flutter

## What This Is

Plugin Flutter multiplataforma (Android, iOS e Web) que integra o VLibras — suíte de acessibilidade em LIBRAS do governo brasileiro — em aplicativos Flutter. Dado um texto de entrada, o plugin exibe o avatar 3D animado (Hugo) realizando os sinais em LIBRAS. Destinado a desenvolvedores Flutter que precisam adicionar acessibilidade em LIBRAS a seus apps, bem como uso no app próprio do autor com intenção de publicação no pub.dev.

## Core Value

Um desenvolvedor Flutter consegue exibir tradução de texto para LIBRAS em qualquer plataforma com um único Controller e Widget, sem precisar lidar com os SDKs nativos diretamente.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Desenvolvedor pode criar um VLibrasController e associar a um VLibrasView
- [ ] Dado um texto enviado ao controller, o avatar 3D do VLibras executa a tradução em LIBRAS
- [ ] Funciona em Android usando o SDK nativo vlibras-mobile-android
- [ ] Funciona em iOS usando o SDK nativo vlibras-mobile-ios
- [ ] Funciona em Flutter Web usando o web player VLibras via HtmlElementView
- [ ] API pública documentada e adequada para publicação no pub.dev

### Out of Scope

- App de demonstração standalone — o foco é o pacote reutilizável (pode ter um exemplo mínimo no /example)
- Backend/tradução própria — usa a infraestrutura do VLibras existente
- Suporte a desktop (Windows/macOS/Linux) — foco em mobile e web primeiro

## Context

- VLibras é uma iniciativa do governo brasileiro (UFPB/RNP) para acessibilidade em LIBRAS
- Repositórios relevantes: https://github.com/orgs/spbgovbr-vlibras/repositories
  - vlibras-mobile-android: SDK Android nativo
  - vlibras-mobile-ios: SDK iOS nativo
  - vlibras-web-player: Player web (WebGL/Unity) do avatar
- Padrão de API escolhido: Controller + Widget (semelhante ao VideoPlayerController + VideoPlayer do Flutter)
- Não existe pacote Flutter para VLibras no pub.dev — oportunidade de contribuição à comunidade

## Constraints

- **Tech stack**: Flutter/Dart com platform channels para Android e iOS; HtmlElementView/WebView para Web
- **Dependência**: Requer SDKs nativos do VLibras (licença a verificar durante pesquisa)
- **Compatibilidade**: Deve seguir convenções de plugin Flutter (federated plugin ou plugin simples)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Controller + Widget como API | Padrão Flutter estabelecido (video_player), flexível para uso avançado | — Pending |
| SDKs nativos para mobile | Performance superior ao WebView em mobile | — Pending |
| Começar por pub.dev desde o início | Estrutura de pacote correta desde o dia 1 evita refatoração | — Pending |

---
*Last updated: 2026-03-22 after initialization*
