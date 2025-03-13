import '../src/encryption.dart';
import '../boxx.dart';

/// Blueprint for boxx platform classes, providing the structure that must be followed by boxx subclasses
/// to maintain a consistent API. This ensures that developers using boxx have a predictable and standardized interface to work with
abstract class BoxxInterface {
  String path;

  String? encryptionKey;
  EncryptionMode? mode;

  EncryptAES aes = EncryptAES();
  EncryptFernet fernet = EncryptFernet();

  BoxxInterface({required this.path, this.encryptionKey, this.mode});

  Future<void> put(String key, dynamic value);
  Future<void> delete(String key);
  Future<bool> exists(String key);
  Future<dynamic> get(String key);
  String keyPath(String key);
}
