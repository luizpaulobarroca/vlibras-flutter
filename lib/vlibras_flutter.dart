/// VLibras Flutter plugin — exibe traduções de texto para LIBRAS com avatar 3D.
///
/// Ponto de entrada público do pacote. Importar este arquivo expõe:
/// - [VLibrasController] — controla o ciclo de vida da tradução
/// - [VLibrasView] — widget que renderiza o avatar VLibras
/// - [VLibrasAccessibilityWidget] — widget de acessibilidade com botão flutuante e captura de texto
/// - [VLibrasValue] e [VLibrasStatus] — estado imutável do controller
/// - [VLibrasPlatform] — interface para injeção de plataforma customizada
library;

export 'src/vlibras_value.dart';
export 'src/vlibras_settings.dart';
export 'src/vlibras_platform.dart';
export 'src/vlibras_controller.dart';
export 'src/vlibras_view.dart';
export 'src/vlibras_accessibility_widget.dart';
