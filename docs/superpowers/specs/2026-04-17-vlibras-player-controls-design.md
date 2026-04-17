# VLibras Player Controls — Design

**Data:** 2026-04-17
**Escopo:** Primeiro spec do par (controles agora, glosa prévia depois).

## Objetivo

Expor ao consumer do plugin `vlibras_flutter` as funcionalidades de controle do player que o avatar Unity já suporta: reprodução (pause/stop/resume/repeat), velocidade, troca de avatar e legendas. Entregar também um painel de configurações pronto-para-uso no `VLibrasAccessibilityWidget`, equivalente ao que o usuário final encontra em sites como VLibras.gov.br e Shopee.

## Não-objetivos

- Tradução prévia de português para glosa LIBRAS (fica para o próximo spec).
- Controle de região de dicionário (`setRegion`).
- Controle de emoção do avatar (`applyEmotion`).
- Persistência automática via `shared_preferences` (plugin permanece sem essa dependência; persistência é opt-in por callback).
- Customização de posicionamento do painel dentro do `VLibrasAccessibilityWidget`.

## Arquitetura

Três camadas tocadas, cada uma com responsabilidade clara.

### Platform (`VLibrasPlatform` e implementações)

Contrato estendido com dois métodos novos:

- `Future<void> setAvatar(VLibrasAvatar avatar)` — delega ao JS `player.changeAvatar(avatar.id)`.
- `Future<void> setSubtitles(bool enabled)` — delega ao JS `player.toggleSubtitle()`. Como a API JS só expõe toggle (sem setter direto), o **controller** compara `enabled` com `value.subtitlesEnabled` e só chama `_platform.setSubtitles(...)` se houver diferença; o platform chama `toggleSubtitle()` incondicionalmente.

`pause`, `stop`, `resume`, `repeat`, `setSpeed` já existem no `VLibrasPlatform` e estão implementados em `VLibrasWebPlatform` e `VLibrasMobilePlatform` — não há mudança no contrato desses métodos.

No `VLibrasPlayerAdapter` (web) e no HTML do mobile, expor `changeAvatar` e `toggleSubtitle` análogos aos já existentes.

### Controller (`VLibrasController`)

Remove o comentário "Phase 3 will add…" (linha 151 do arquivo atual) e passa a expor:

```dart
// reprodução
Future<void> pause();
Future<void> stop();
Future<void> resume();
Future<void> repeat();

// configurações
Future<void> setSpeed(VLibrasSpeed speed);
Future<void> setAvatar(VLibrasAvatar avatar);
Future<void> setSubtitles(bool enabled);
```

Construtor ganha dois parâmetros opcionais:

```dart
VLibrasController({
  VLibrasPlatform? platform,
  String targetPath = '/vlibras/target',
  VLibrasSettings? initialSettings,
  void Function(VLibrasSettings)? onSettingsChanged,
});
```

### Widget layer

Dois widgets, ambos públicos:

- `VLibrasSettingsPanel(controller: ...)` — painel pronto reutilizável, independente do widget de acessibilidade.
- `VLibrasAccessibilityWidget` — ganha um toggle de configurações (botão ⚙️ secundário) que abre `VLibrasSettingsPanel` em overlay inline.

### Fluxo de evento típico (trocar velocidade)

1. Usuário toca no preset "Rápido" no painel.
2. `VLibrasSettingsPanel` chama `controller.setSpeed(VLibrasSpeed.fast)`.
3. Controller atualiza `VLibrasValue.speed` e aguarda `_platform.setSpeed(1.5)`.
4. Após o platform aceitar, dispara `onSettingsChanged(settings)` (se fornecido).
5. Todos os listeners (painel incluído) re-renderizam com o novo valor.

## API pública

### Enums (`lib/src/vlibras_value.dart`)

```dart
enum VLibrasSpeed {
  slow(0.5),
  normal(1.0),
  fast(1.5);

  const VLibrasSpeed(this.multiplier);
  final double multiplier;
}

enum VLibrasAvatar {
  icaro('icaro'),
  hosana('hosana'),
  guga('guga');

  const VLibrasAvatar(this.id);
  final String id; // string aceita pelo Unity player
}
```

### `VLibrasValue` estendido

Três campos novos com defaults — consumidores existentes continuam funcionando sem alteração.

```dart
const VLibrasValue({
  this.status = VLibrasStatus.idle,
  this.error,
  this.speed = VLibrasSpeed.normal,
  this.avatar = VLibrasAvatar.icaro,
  this.subtitlesEnabled = true,
});
```

`copyWith`, `==`, `hashCode`, `toString` atualizados para incluir os novos campos. `hasError` permanece.

### `VLibrasSettings` (novo objeto serializável)

Distinto de `VLibrasValue` (que carrega status também). Existe só para facilitar persistência.

```dart
@immutable
class VLibrasSettings {
  final VLibrasSpeed speed;
  final VLibrasAvatar avatar;
  final bool subtitlesEnabled;

  const VLibrasSettings({
    this.speed = VLibrasSpeed.normal,
    this.avatar = VLibrasAvatar.icaro,
    this.subtitlesEnabled = true,
  });

  Map<String, dynamic> toJson();
  factory VLibrasSettings.fromJson(Map<String, dynamic> json);
}
```

### Semântica do controller

- **Chamadas antes de `initialize()`:** enfileiradas numa fila interna e drenadas sequencialmente após `ready`. Chamar o Unity antes da carga é no-op silencioso — enfileirar evita perda de intenção do consumer.
- **Erros do platform:** capturados, armazenados em `VLibrasValue.error` seguindo o padrão ERR-01 atual de `initialize`/`translate`. Nunca propagam ao chamador.
- **`initialSettings`:** aplicado sequencialmente **antes** do controller transicionar para `ready` — o primeiro estado `ready` observado pelos listeners já reflete as preferências salvas. Após aplicar `initialSettings`, o controller drena a fila de chamadas pré-init (se houver). Durante ambas as fases, `onSettingsChanged` **não dispara** (flag `_applyingInitial`). Erros durante a aplicação inicial são logados via `debugPrint` e ignorados — não transicionam para `error`. Default perdido é melhor que plugin quebrado.
- **`onSettingsChanged`:** chamado **após** o platform aceitar cada mudança. Se `_platform.setX` lança, nada é salvo. A assinatura é síncrona (`void Function(VLibrasSettings)`), mas o consumer pode retornar um `Future` que o controller **não aguarda** — persistir não deve bloquear a UI.
- **Sem debounce:** mudanças são acionadas por toques humanos, frequência baixa. Se o consumer automatizar mudanças, debounce é responsabilidade dele.

## `VLibrasSettingsPanel` — widget público

### Assinatura

```dart
class VLibrasSettingsPanel extends StatelessWidget {
  const VLibrasSettingsPanel({
    super.key,
    required this.controller,
    this.onClose,
    this.labels = const VLibrasSettingsLabels(),
  });

  final VLibrasController controller;
  final VoidCallback? onClose;
  final VLibrasSettingsLabels labels;
}
```

### Layout

```
┌───────────────────────────────────────┐
│ Configurações                       ✕ │  header (✕ só se onClose != null)
├───────────────────────────────────────┤
│ Velocidade                            │
│ [ Devagar ][ Normal ][ Rápido ]       │  SegmentedButton
│                                       │
│ Avatar                                │
│ ( ◉ Ícaro )( ○ Hosana )( ○ Guga )     │  Row compacta
│                                       │
│ Legendas                    [●──]     │  Switch
└───────────────────────────────────────┘
```

Corpo envolvido em `ListenableBuilder(listenable: controller, ...)`. Cada controle lê de `controller.value` e escreve via método do controller. Zero estado local duplicado.

Largura intrínseca ~320dp; altura se ajusta ao conteúdo. Estilo Material 3, respeitando `Theme.of(context)`. Nenhum valor visual hardcoded além do espaçamento.

### `VLibrasSettingsLabels` — i18n sem dependência

```dart
@immutable
class VLibrasSettingsLabels {
  const VLibrasSettingsLabels({
    this.title = 'Configurações',
    this.speed = 'Velocidade',
    this.speedSlow = 'Devagar',
    this.speedNormal = 'Normal',
    this.speedFast = 'Rápido',
    this.avatar = 'Avatar',
    this.avatarIcaro = 'Ícaro',
    this.avatarHosana = 'Hosana',
    this.avatarGuga = 'Guga',
    this.subtitles = 'Legendas',
    this.close = 'Fechar',
  });

  final String title;
  final String speed;
  final String speedSlow;
  final String speedNormal;
  final String speedFast;
  final String avatar;
  final String avatarIcaro;
  final String avatarHosana;
  final String avatarGuga;
  final String subtitles;
  final String close;
}
```

Defaults em português (público-alvo do VLibras). Consumer passa uma instância custom para localizar.

### Acessibilidade

- Cada controle envolvido em `Semantics(label: ...)` apropriado.
- Foco visível via `FocusableActionDetector` (padrão Material).
- Targets de toque ≥ 48×48dp (respeitado pelos componentes Material usados).

## Integração no `VLibrasAccessibilityWidget`

### Estado interno adicional

```dart
bool _isSettingsOpen = false;
```

### Mudanças visuais

- **Avatar fechado:** botão único "abrir VLibras" (comportamento atual).
- **Avatar aberto:** botão principal + botão secundário ⚙️ ao lado, que alterna `_isSettingsOpen`.
- **Overlay do painel:** `Positioned` na mesma `Stack` do avatar, ancorado acima da dupla de botões. Conteúdo: `VLibrasSettingsPanel` com `onClose: () => setState(() => _isSettingsOpen = false)`. Envolvido em `Material(elevation: 8, borderRadius: 16)` para sombra/forma coerentes. Fade+slide de 180ms via `AnimatedSwitcher`, consistente com a animação existente do avatar.

### Novo parâmetro público

```dart
VLibrasAccessibilityWidget({
  // ... atuais
  this.showSettingsButton = true,
});
```

Default `true` porque é o diferencial visível que motiva esta feature. Consumer que queira o widget original sem painel passa `false`.

### Fora do escopo deste widget

- Configurar a posição do painel (acima/abaixo/lateral). Sempre acima dos botões.
- Expor builder custom do painel. Quem quiser layout próprio usa `VLibrasSettingsPanel` diretamente.

## Persistência (callbacks opt-in)

### Fluxo de carga

```dart
final controller = VLibrasController(
  initialSettings: savedSettings, // ou null
);
await controller.initialize();
// dentro de initialize(), se initialSettings != null,
// o controller aplica speed/avatar/subtitles antes de transicionar para 'ready'.
```

### Fluxo de salvamento

```dart
final controller = VLibrasController(
  onSettingsChanged: (settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vlibras_settings', jsonEncode(settings.toJson()));
  },
);
```

### Documentação

Adicionar seção "Persisting user preferences" no README do plugin com o snippet acima usando `shared_preferences`. Receita de 5 linhas; `shared_preferences` **não** entra no `pubspec.yaml` do plugin.

## Testes

### Unit tests (`test/vlibras_controller_test.dart` — expandir)

- `setSpeed` delega ao platform e atualiza `value.speed`.
- `setAvatar` idem para `value.avatar`.
- `setSubtitles` idem para `value.subtitlesEnabled`.
- `onSettingsChanged` é chamado pós-platform com `VLibrasSettings` completo.
- `onSettingsChanged` **não** dispara durante aplicação de `initialSettings`.
- `initialSettings` é aplicado sequencialmente após `ready`.
- Erro do platform em `setSpeed` preenche `value.error` e não lança.
- Chamadas antes de `initialize()` são enfileiradas e drenadas após `ready`.
- `pause`/`stop`/`resume`/`repeat` delegam ao platform.

### Widget tests (`test/vlibras_settings_panel_test.dart` — novo)

- Renderiza três seções com labels default (PT).
- Toque em "Rápido" chama `controller.setSpeed(VLibrasSpeed.fast)`.
- Seleção de avatar no radio chama `controller.setAvatar(...)`.
- Toggle de legendas chama `controller.setSubtitles(...)`.
- Botão ✕ aparece se e somente se `onClose != null`.
- `VLibrasSettingsLabels` custom substitui os defaults.

### Widget tests (`test/vlibras_accessibility_widget_test.dart` — expandir)

- `showSettingsButton: false` esconde o ⚙️.
- Toque em ⚙️ abre o painel (overlay visível).
- `onClose` do painel fecha o overlay.

### Integration tests — fora de escopo

Não rodamos E2E contra Unity WebGL no CI. Validação manual no `example/` continua sendo o gate final, igual ao padrão atual do plugin.

### Cobertura

Sem alvo numérico. Garantir que cada método público novo do controller e cada controle do painel tenha ao menos um teste de caminho feliz **e** um teste de comportamento sob erro (quando aplicável).

## Compatibilidade retroativa

- `VLibrasValue` ganha campos com defaults — todo call-site existente continua compilando sem alteração.
- `VLibrasController` ganha parâmetros opcionais no construtor — call-sites existentes continuam funcionando.
- `VLibrasAccessibilityWidget` ganha parâmetro `showSettingsButton` com default `true`. O comportamento visual muda para quem já usa o widget: surge um botão ⚙️. Isso é intencional (é o ponto da feature), mas precisa ser mencionado no CHANGELOG. Consumer que não quiser muda para `false`.

## Ordem sugerida de implementação

1. Enums `VLibrasSpeed` e `VLibrasAvatar`; `VLibrasValue` estendido; `VLibrasSettings`.
2. `VLibrasPlatform.setAvatar`/`setSubtitles` + implementações web e mobile (incluindo a diferença toggle-vs-set de legendas).
3. Controller: `setSpeed`/`setAvatar`/`setSubtitles`/`pause`/`stop`/`resume`/`repeat`; fila pré-init; callbacks `initialSettings`/`onSettingsChanged`.
4. `VLibrasSettingsPanel` + `VLibrasSettingsLabels`.
5. Integração no `VLibrasAccessibilityWidget` (botão ⚙️ + overlay).
6. Testes unit + widget.
7. Atualizar README com seção de persistência.
8. Validação manual no `example/`.
