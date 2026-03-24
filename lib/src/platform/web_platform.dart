import '../vlibras_platform.dart';
import '../vlibras_value.dart';
import '../vlibras_web_platform.dart';

VLibrasPlatform createDefaultPlatform(void Function(VLibrasStatus) onStatus) {
  return VLibrasWebPlatform(onStatus: onStatus);
}
