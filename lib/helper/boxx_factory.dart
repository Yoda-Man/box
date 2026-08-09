import '../src/encryption_mode.dart';
import 'boxx_interface.dart';
import 'boxx_native.dart'
    if (dart.library.js_interop) 'boxx_web.dart'
    as implementation;

class BoxxFactory {
  const BoxxFactory._();

  static const BoxxFactory instance = BoxxFactory._();

  BoxxInterface getBoxxInterface({
    required String namespace,
    required EncryptionMode mode,
    required String? encryptionKey,
    required EncryptionMode legacyMode,
    required String? legacyEncryptionKey,
  }) => implementation.BoxxHelper(
    namespace: namespace,
    mode: mode,
    encryptionKey: encryptionKey,
    legacyMode: legacyMode,
    legacyEncryptionKey: legacyEncryptionKey,
  );
}
