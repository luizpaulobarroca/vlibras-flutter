import '../vlibras_platform.dart';
import '../vlibras_value.dart';

VLibrasPlatform createDefaultPlatform(void Function(VLibrasStatus) onStatus, String targetPath) {
  throw UnsupportedError(
    'vlibras_flutter suporta apenas Flutter Web em v1',
  );
}
