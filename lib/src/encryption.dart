import 'package:encrypt/encrypt.dart';
import 'global.dart';

///for AES Algorithms
class EncryptAES {
  static Encrypted? encrypted;

  ///AES encryption. AES keys must be exactly 128, 192, or 256 bits long, which corresponds to byte arrays of lengths
  ///16, 24, or 32, respectively.
  ///
  String encryptAES(String plainText, String encryptionKey) {
    try {
      String keyValue =
          String.fromCharCodes(padKeyWithZeros(encryptionKey, 32));
      String ivValue = String.fromCharCodes(padKeyWithZeros(encryptionKey, 16));
      final key = Key.fromUtf8(keyValue);

      final iv = IV.fromUtf8(ivValue);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted!.base64;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  String decryptAES(String encryptedText, String encryptionKey) {
    try {
      String keyValue =
          String.fromCharCodes(padKeyWithZeros(encryptionKey, 32));
      String ivValue = String.fromCharCodes(padKeyWithZeros(encryptionKey, 16));
      final key = Key.fromUtf8(keyValue);

      final iv = IV.fromUtf8(ivValue);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      encrypted = Encrypted.from64(encryptedText);
      // static var decrypted;
      var decrypted = encrypter.decrypt(encrypted!, iv: iv);
      return decrypted;
    } on Exception catch (e) {
      return e.toString();
    }
  }
}

///for Fernet Algorithms
class EncryptFernet {
  static Encrypted? fernetEncrypted;

  String encryptFernet(String plainText, String encryptionKey) {
    try {
      //Fernet key must be 32 bit url-safe base64-encoded bytes
      String keyValue = fernetKeyGenerator(encryptionKey);
      final key = Key.fromBase64(keyValue);
      final fernet = Fernet(key);
      final encrypter = Encrypter(fernet);
      fernetEncrypted = encrypter.encrypt(plainText);
      return fernetEncrypted!.base64; // random cipher text
    } on Exception catch (e) {
      return e.toString();
    }
  }

  String decryptFernet(String encryptedText, String encryptionKey) {
    try {
      //Fernet key must be 32 bit url-safe base64-encoded bytes
      String keyValue = fernetKeyGenerator(encryptionKey);
      final key = Key.fromBase64(keyValue);
      final fernet = Fernet(key);
      final encrypter = Encrypter(fernet);
      fernetEncrypted == Encrypted.from64(encryptedText);
      var fernetDecrypted = encrypter.decrypt(fernetEncrypted!);
      return fernetDecrypted;
    } on Exception catch (e) {
      return e.toString();
    }
  }
}
