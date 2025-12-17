import 'package:encrypt/encrypt.dart';
import 'global.dart';

/// Exceptions for Boxx encryption errors
class BoxxEncryptionException implements Exception {
  final String message;
  BoxxEncryptionException(this.message);
  @override
  String toString() => 'BoxxEncryptionException: $message';
}

/// Helper for AES Algorithms
class EncryptAES {
  /// AES encryption.
  /// Generates a random IV for each encryption and prepends it to the result.
  /// Format: base64(IV) + ":" + base64(Ciphertext)
  String encryptAES(String plainText, String encryptionKey) {
    try {
      final key = Key.fromUtf8(
        String.fromCharCodes(padKeyWithZeros(encryptionKey, 32)),
      );

      // Generate a random 16-byte IV
      final iv = IV.fromSecureRandom(16);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Combine IV and ciphertext
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw BoxxEncryptionException('AES Encryption failed: $e');
    }
  }

  /// Performs AES decryption
  /// Expects format: base64(IV) + ":" + base64(Ciphertext)
  String decryptAES(String encryptedText, String encryptionKey) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw BoxxEncryptionException('Invalid encrypted data format');
      }

      final key = Key.fromUtf8(
        String.fromCharCodes(padKeyWithZeros(encryptionKey, 32)),
      );

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw BoxxEncryptionException('AES Decryption failed: $e');
    }
  }
}

/// Helper for Fernet Algorithms
class EncryptFernet {
  /// Performs fernet encryption and returns a base64 encoded string
  String encryptFernet(String plainText, String encryptionKey) {
    try {
      // Fernet key must be 32 bit url-safe base64-encoded bytes
      String keyValue = fernetKeyGenerator(encryptionKey);
      final key = Key.fromBase64(keyValue);
      final fernet = Fernet(key);
      final encrypter = Encrypter(fernet);

      final encrypted = encrypter.encrypt(plainText);
      return encrypted.base64;
    } catch (e) {
      throw BoxxEncryptionException('Fernet Encryption failed: $e');
    }
  }

  /// Performs fernet decryption
  String decryptFernet(String encryptedText, String encryptionKey) {
    try {
      // Fernet key must be 32 bit url-safe base64-encoded bytes
      String keyValue = fernetKeyGenerator(encryptionKey);
      final key = Key.fromBase64(keyValue);
      final fernet = Fernet(key);
      final encrypter = Encrypter(fernet);

      final encrypted = Encrypted.from64(encryptedText);
      return encrypter.decrypt(encrypted);
    } catch (e) {
      throw BoxxEncryptionException('Fernet Decryption failed: $e');
    }
  }
}
