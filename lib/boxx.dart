import 'helper/boxx_factory.dart';
import 'helper/boxx_interface.dart';

/// Enctryption Modes
/// Modes are placed in this file to make it easier to implement
enum EncryptionMode { aes, fernet, none }

/// Class to handle all local storage
class Boxx {
  EncryptionMode? mode;
  String? encryptionKey;
  late final BoxxInterface boxx;

  Boxx({required this.mode, this.encryptionKey}) {
    boxx = getBoxxInterface(mode: mode, encryptionKey: encryptionKey);
  }
}
