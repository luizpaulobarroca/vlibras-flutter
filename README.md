# vlibras_flutter

Plugin Flutter para exibir traduções de texto para LIBRAS usando o avatar 3D do [VLibras](https://vlibras.gov.br/) (iniciativa UFPB/RNP do governo brasileiro para acessibilidade digital).

## Plataformas

| Plataforma   | Suporte       |
|--------------|---------------|
| Flutter Web  | ✓ (estável)   |
| Android      | ✓ (via WebView) |
| iOS          | Planejado     |

---

## Instalação

O pacote ainda não está publicado no pub.dev. Use uma das três formas abaixo.

### 1. Via Git (recomendado para testar)

No `pubspec.yaml` do app consumidor:

```yaml
dependencies:
  vlibras_flutter:
    git:
      url: https://github.com/luizpaulobarroca/vlibras-flutter.git
      ref: main
```

Opcional — fixar uma tag ou commit específico:

```yaml
dependencies:
  vlibras_flutter:
    git:
      url: https://github.com/luizpaulobarroca/vlibras-flutter.git
      ref: v0.1.0        # ou um SHA de commit
```

Depois rode:

```bash
flutter pub get
```

### 2. Via path local

Clone o repositório ao lado do seu app e aponte para a pasta:

```yaml
dependencies:
  vlibras_flutter:
    path: ../vlibras-flutter
```

### 3. Via pub.dev

```yaml
dependencies:
  vlibras_flutter: ^0.1.0
```

*(disponível quando a primeira versão for publicada)*

---

## Configuração por plataforma

### Flutter Web

O avatar é carregado por um player Unity WebGL servido a partir do diretório `web/` do seu app. Você precisa de **dois conjuntos de arquivos**:

**a) O loader JS** em `web/vlibras/vlibras.js`
**b) Os assets Unity** em `web/vlibras/target/`:
```
web/vlibras/target/UnityLoader.js
web/vlibras/target/playerweb.json
web/vlibras/target/playerweb.data.unityweb
web/vlibras/target/playerweb.wasm.code.unityweb
web/vlibras/target/playerweb.wasm.framework.unityweb
```

A forma mais prática é copiar a pasta `web/vlibras/` do próprio repositório do plugin:

```bash
# a partir da raiz do seu app
git clone --depth 1 https://github.com/luizpaulobarroca/vlibras-flutter.git /tmp/vlibras
cp -r /tmp/vlibras/web/vlibras ./web/vlibras
```

Depois, referencie o loader no seu `web/index.html`, antes do `</body>`:

```html
<script src="vlibras/vlibras.js"></script>
```

Se você servir a partir de um path customizado, passe-o ao controller:

```dart
VLibrasController(targetPath: '/meu-app/vlibras/target');
```

### Android

Adicione a permissão de internet em `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    ...
</manifest>
```

Nenhum outro asset é necessário — o avatar Android carrega via WebView + CDN.

---

## Uso

### Opção A — widget de acessibilidade (mais simples)

Plugue no `builder` do seu `MaterialApp` e pronto: um botão flutuante à direita abre o avatar, e qualquer `Text` do app pode ser tocado para ser traduzido.

```dart
import 'package:flutter/material.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) =>
          VLibrasAccessibilityWidget(child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha aplicação')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Toque no botão azul e depois neste texto.'),
      ),
    );
  }
}
```

> `VLibrasAccessibilityWidget` precisa estar **dentro** de `MaterialApp` (por isso usamos `builder`), para que `Directionality`, `MediaQuery` e `Theme` estejam disponíveis.

### Opção B — controller + view (uso avançado)

Quando você quer integrar o avatar em um layout específico e controlar traduções manualmente:

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final VLibrasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VLibrasController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 400,
          height: 300,
          child: VLibrasView(controller: _controller),
        ),
        ValueListenableBuilder<VLibrasValue>(
          valueListenable: _controller,
          builder: (_, value, __) => Text('Status: ${value.status.name}'),
        ),
        ElevatedButton(
          onPressed: () => _controller.translate('Olá mundo'),
          child: const Text('Traduzir'),
        ),
      ],
    );
  }
}
```

---

## Estados do controller

| Status         | Descrição                                    |
|----------------|----------------------------------------------|
| `idle`         | Criado mas não inicializado                  |
| `initializing` | `initialize()` em andamento                  |
| `ready`        | Pronto para traduzir                         |
| `translating`  | Aguardando resposta do player                |
| `playing`      | Avatar animando a tradução                   |
| `error`        | Erro — veja `VLibrasValue.error`             |

Métodos do controller:

- `initialize()` — prepara a plataforma
- `translate(String)` — traduz um texto
- `pause()` / `resume()` / `stop()` / `repeat()` — controles do player
- `setSpeed(VLibrasSpeed)` — preset de velocidade (slow/normal/fast)
- `setAvatar(VLibrasAvatar)` — troca o avatar (ícaro/hosana/guga)
- `setSubtitles(bool)` — liga/desliga legendas

---

## Persistência de preferências do usuário

O controller não traz backend de persistência. Para salvar velocidade, avatar e legendas entre execuções, use os parâmetros opcionais do construtor com o pacote que preferir (ex.: `shared_preferences`):

```dart
Future<VLibrasSettings> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('vlibras_settings');
  if (raw == null) return const VLibrasSettings();
  return VLibrasSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<void> _saveSettings(VLibrasSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('vlibras_settings', jsonEncode(settings.toJson()));
}

final controller = VLibrasController(
  initialSettings: await _loadSettings(),
  onSettingsChanged: _saveSettings,
);
await controller.initialize();
```

`onSettingsChanged` é chamado apenas depois que o player aceita a mudança, então o callback nunca persiste um estado intermediário ou rejeitado. `initialSettings` é aplicado antes do primeiro `ready`.

---

## Customização do `VLibrasAccessibilityWidget`

```dart
VLibrasAccessibilityWidget(
  avatarWidth: 280,
  avatarHeight: 320,
  buttonSize: 56,
  showSettingsButton: true,
  settingsLabels: const VLibrasSettingsLabels(
    title: 'Configurações',
    speed: 'Velocidade',
    avatar: 'Avatar',
    subtitles: 'Legendas',
    close: 'Fechar',
  ),
  child: child!,
)
```

---

## Rodando o exemplo

```bash
git clone https://github.com/luizpaulobarroca/vlibras-flutter.git
cd vlibras-flutter/example
flutter pub get
flutter run -d chrome
```

## Licença

MIT — veja [LICENSE](LICENSE).
