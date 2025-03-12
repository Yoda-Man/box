import 'helper/boxx_factory.dart';
import 'helper/boxx_interface.dart';
import 'src/enum.dart';

/// Class to handle all local storage
class Boxx {
  String path;

  String? encryptionKey;
  EncryptionMode? mode;

  late final BoxxInterface boxx;

  Boxx({required this.path, this.encryptionKey, this.mode}) {
    boxx =
        getBoxxInterface(path: path, encryptionKey: encryptionKey, mode: mode);
  }
}
