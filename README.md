# vlibras_flutter

Plugin Flutter para exibir traduções de texto para LIBRAS usando o avatar 3D VLibras. Desenvolvido para [VLibras](https://vlibras.gov.br/), iniciativa do governo brasileiro (UFPB/RNP) para acessibilidade digital.

## Plataformas suportadas

| Plataforma | Suporte |
|------------|---------|
| Flutter Web | ✓ |
| Android | Planejado (v2) |
| iOS | Planejado (v2) |

## Instalação

Adicione ao `pubspec.yaml` do seu projeto:

```yaml
dependencies:
  vlibras_flutter: ^0.1.0
```

### Configuração dos assets VLibras

O plugin requer os assets do player VLibras na pasta `web/vlibras/` do seu app Flutter Web:

1. Copie o arquivo `vlibras.js` para `web/vlibras/vlibras.js`
2. Copie a pasta `target/` para `web/vlibras/target/`
3. Adicione o script no `web/index.html` antes do `</body>`:

```html
<script src="vlibras/vlibras.js"></script>
```

## Uso básico

```dart
import 'package:vlibras_flutter/vlibras_flutter.dart';

class MyWidget extends StatefulWidget {
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
          builder: (context, value, _) {
            return Text('Status: ${value.status.name}');
          },
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

## Estados do controller

| Status | Descrição |
|--------|-----------|
| `idle` | Criado mas não inicializado |
| `initializing` | `initialize()` em andamento |
| `ready` | Pronto para traduzir |
| `translating` | Aguardando resposta do player |
| `playing` | Avatar animando a tradução |
| `error` | Erro — veja `VLibrasValue.error` |

## Licença

MIT — veja [LICENSE](LICENSE)
