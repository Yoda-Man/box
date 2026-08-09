import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart' hide Padding;

import 'exceptions.dart';
import 'global.dart';

// Boxx requires high-entropy 32-byte keys. PBKDF2 adds per-record
// diversification without making synchronous web use impractical.
const int _kdfIterations = 10000;
const int _saltLength = 16;

Uint8List _deriveKey(String secret, Uint8List salt, int iterations) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(salt, iterations, 32));
  return derivator.process(Uint8List.fromList(utf8.encode(secret)));
}

Never _encryptionFailure(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  Error.throwWithStackTrace(
    BoxxEncryptionException('$operation failed', cause: error),
    stackTrace,
  );
}

/// Helper for AES Algorithms
class EncryptAES {
  static const String _prefix = 'boxx2:aes-gcm';

  /// Encrypts with AES-256-GCM using a per-message PBKDF2 salt and nonce.
  String encryptAES(String plainText, String encryptionKey) {
    try {
      final salt = IV.fromSecureRandom(_saltLength).bytes;
      final iv = IV.fromSecureRandom(12);
      final key = _deriveKey(encryptionKey, salt, _kdfIterations);
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true,
          AEADParameters(KeyParameter(key), 128, iv.bytes, Uint8List(0)),
        );
      final encrypted = cipher.process(
        Uint8List.fromList(utf8.encode(plainText)),
      );
      return '$_prefix:$_kdfIterations:${base64UrlEncode(salt)}:'
          '${base64UrlEncode(iv.bytes)}:${base64UrlEncode(encrypted)}';
    } catch (error, stackTrace) {
      _encryptionFailure('AES encryption', error, stackTrace);
    }
  }

  /// Decrypts current AES-GCM values and legacy AES-CBC values.
  String decryptAES(String encryptedText, String encryptionKey) {
    try {
      if (encryptedText.startsWith('$_prefix:')) {
        final parts = encryptedText.split(':');
        if (parts.length != 6) {
          throw const FormatException('Invalid AES-GCM value');
        }
        final iterations = int.parse(parts[2]);
        if (iterations != _kdfIterations) {
          throw const FormatException('Unsupported AES KDF parameters');
        }
        final salt = base64Url.decode(parts[3]);
        final iv = IV(Uint8List.fromList(base64Url.decode(parts[4])));
        final encrypted = Uint8List.fromList(base64Url.decode(parts[5]));
        final key = _deriveKey(encryptionKey, salt, iterations);
        final cipher = GCMBlockCipher(AESEngine())
          ..init(
            false,
            AEADParameters(KeyParameter(key), 128, iv.bytes, Uint8List(0)),
          );
        return utf8.decode(cipher.process(encrypted));
      }

      // Legacy v0.1.8-v0.2.0 format: base64(IV):base64(ciphertext).
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw const FormatException('Invalid legacy AES value');
      }
      final key = Key.fromUtf8(
        String.fromCharCodes(padKeyWithZeros(encryptionKey, 32)),
      );
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (error, stackTrace) {
      _encryptionFailure('AES decryption', error, stackTrace);
    }
  }
}

/// Helper for Fernet Algorithms
class EncryptFernet {
  static const String _prefix = 'boxx2:fernet';

  /// Encrypts with Fernet using a per-message PBKDF2 salt.
  String encryptFernet(String plainText, String encryptionKey) {
    try {
      final salt = IV.fromSecureRandom(_saltLength).bytes;
      final key = Key(_deriveKey(encryptionKey, salt, _kdfIterations));
      final fernet = Fernet(key);
      final encrypter = Encrypter(fernet);
      final encrypted = encrypter.encrypt(plainText);
      return '$_prefix:$_kdfIterations:${base64UrlEncode(salt)}:'
          '${base64UrlEncode(encrypted.bytes)}';
    } catch (error, stackTrace) {
      _encryptionFailure('Fernet encryption', error, stackTrace);
    }
  }

  /// Decrypts current and legacy Fernet values.
  String decryptFernet(String encryptedText, String encryptionKey) {
    try {
      if (encryptedText.startsWith('$_prefix:')) {
        final parts = encryptedText.split(':');
        if (parts.length != 5) {
          throw const FormatException('Invalid Fernet value');
        }
        final iterations = int.parse(parts[2]);
        if (iterations != _kdfIterations) {
          throw const FormatException('Unsupported Fernet KDF parameters');
        }
        final salt = Uint8List.fromList(base64Url.decode(parts[3]));
        final key = Key(_deriveKey(encryptionKey, salt, iterations));
        final fernet = Fernet(key);
        final encrypter = Encrypter(fernet);
        return encrypter.decrypt(
          Encrypted(Uint8List.fromList(base64Url.decode(parts[4]))),
        );
      }

      final key = Key.fromBase64(fernetKeyGenerator(encryptionKey));
      final fernet = Fernet(key);
      final encrypter = Encrypter(fernet);
      final encrypted = Encrypted.from64(encryptedText);
      return encrypter.decrypt(encrypted);
    } catch (error, stackTrace) {
      _encryptionFailure('Fernet decryption', error, stackTrace);
    }
  }
}
