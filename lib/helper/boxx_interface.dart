import '../src/encryption.dart';
import '../boxx.dart';

/// Blueprint for boxx platform classes, providing the structure that must be followed by boxx subclasses
/// to maintain a consistent API. This ensures that developers using boxx have a predictable and standardized interface to work with
abstract class BoxxInterface {
  final String? encryptionKey;
  final EncryptionMode? mode;

  final EncryptAES aes = EncryptAES();
  final EncryptFernet fernet = EncryptFernet();

  BoxxInterface({required this.mode, this.encryptionKey});

  Future<void> put(String key, dynamic value);
  Future<void> delete(String key);
  Future<bool> exists(String key);
  Future<dynamic> get(String key);
  Future<void> clear();
}
