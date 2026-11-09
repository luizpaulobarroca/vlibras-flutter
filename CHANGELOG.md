# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-11-09

### Fixed

- Tradução: o endpoint padrão `https://traducao2.vlibras.gov.br/dl/translate` passou a responder 401 a qualquer chamada, e o avatar só soletrava o texto cru (plurais, verbos e nomes saíam letra por letra). O padrão agora é `https://traducao2.vlibras.gov.br/translate`, o mesmo do widget oficial do gov.br. A resposta em JSON `{"traducao": "..."}` também é aceita.
- Tradução: o tradutor do governo responde 500 "Translation Core Unavailable" em parte das chamadas (cerca de 1 em 10 numa medição) e acerta na seguinte. Erros 5xx e de rede agora são repetidos até duas vezes (após 0,4 s e 1,2 s), dentro do limite de 30 s, antes de cair na soletração do texto.
- Web: o `translateUrl` do controller chegava à plataforma web e era descartado; agora é repassado ao player.
- Android: quando o sistema encerrava o processo de renderização do WebView (falta de memória, por exemplo), o app inteiro era encerrado junto, porque o `webview_flutter` não trata `onRenderProcessGone`. O plugin Android passa a tratar o evento (Android 8.0+), e o `VLibrasAccessibilityWidget` recria o avatar, uma vez sozinho e depois pelo botão "Tentar novamente".
- Com o painel aberto, a tela voltou a rolar (listas, sliders, `PageView`): o interceptor de toques ficou translúcido. O primeiro toque continua só traduzindo, e o segundo toque perto dele aciona o elemento com o toque real, sem evento sintético. Rolar a tela desarma o toque armado.
- Tocar num ícone não envia mais o caractere da fonte de ícones ao tradutor.

### Added

- Sem `Text` sob o dedo, o `VLibrasAccessibilityWidget` traduz o rótulo semântico mais próximo (`Image.semanticLabel`, `Icon.semanticLabel`, `Semantics(label:)`, tooltip). Imagens com texto embutido passam a ser traduzíveis com um `semanticLabel`, o que também ajuda leitores de tela.
- `VLibrasAccessibilityWidget.preloadAvatar` e `releaseAvatarWhenInBackground` (ver "Changed").
- `VLibrasSettingsLabels.retry`, rótulo do botão "Tentar novamente".

### Changed

- O avatar só é carregado quando o painel é aberto pela primeira vez. Antes, o WebView com o player Unity (~400 MB no processo do renderer) era carregado na montagem do widget, ou seja, na abertura do app, mesmo para quem nunca usa o VLibras. Para manter a carga antecipada, use `preloadAvatar: true`.
- Com o app em segundo plano e o painel fechado, o avatar é descarregado e volta a carregar na próxima abertura, mantendo velocidade, avatar e legendas (`releaseAvatarWhenInBackground`, padrão `true`).
- `VLibrasMobilePlatform` só cria o WebView e carrega o player em `initialize()`, e o `dispose()` descarrega a página na hora.
- `webview_flutter_android` passa a ser dependência direta, para o plugin Android acessar o WebView nativo.

## [0.4.0] - 2026-07-14

### Added

- Permite ao usuario redimensionar o painel expandido do `VLibrasAccessibilityWidget` com o gesto de pinca (dois dedos), tanto no cabecalho quanto sobre a area do avatar. Os novos parametros `minAvatarScale` e `maxAvatarScale` controlam os limites, e o tamanho e sempre restringido a safe area.

## [0.3.2] - 2026-06-09

### Changed

- Torna o botao flutuante e o painel do `VLibrasAccessibilityWidget` arrastaveis, com encaixe nas laterais e limites baseados na safe area.

## [0.3.0] - 2026-04-28

### Added

- URL de tradução customizável via `translationUrl` no `VLibrasController`
- Cor primária customizável para elementos de UI (`primaryColor` no `VLibrasAccessibilityWidget`)
- Melhorias de acessibilidade e aprimoramentos de UI

## [0.2.0] - 2026-04-23

### Added

- Registro oficial da plataforma Android no pacote (`android/` module + `VLibrasFlutterPlugin` stub)
- `AndroidManifest.xml` do plugin contribui automaticamente a permissão `INTERNET` e `network_security_config` permitindo cleartext apenas em `127.0.0.1` — necessário para o `HttpServer` loopback que serve os assets Unity ao WebView

### Changed

- README: seção Android passa a ser "zero setup" — o manifest do plugin é mesclado no app do consumer via manifest merger do Gradle
- Exemplo: removidos `AndroidManifest` e `network_security_config` redundantes que antes duplicavam o que o plugin agora contribui

## [0.1.0] - 2026-03-27

### Added

- `VLibrasController` com ciclo de vida completo: `initialize()`, `translate()`, `dispose()`
- `VLibrasView` widget que renderiza o avatar VLibras em Flutter Web via `HtmlElementView`
- `VLibrasValue` e `VLibrasStatus` com 6 estados: `idle`, `initializing`, `ready`, `translating`, `playing`, `error`
- `VLibrasPlatform` interface abstrata para injeção de plataforma customizada e testes
- Suporte inicial exclusivo a Flutter Web (Android/iOS planejados para v2)
- App de exemplo com avatar flutuante snap-para-quinas e demonstração interativa
