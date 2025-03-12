import '../src/encryption.dart';
import '../src/enum.dart';

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
