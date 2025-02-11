import 'package:encrypt/encrypt.dart';
import 'dart:convert';

import 'global.dart';

///for AES Algorithms
class EncryptAES {
  static Encrypted? encrypted;

  ///AES encryption. AES keys must be exactly 128, 192, or 256 bits long, which corresponds to byte arrays of lengths
  ///16, 24, or 32, respectively.
  ///
  String encryptAES(plainText, String encryptionKey) {
    try {
      String keyValue =
          String.fromCharCodes(padKeyWithZeros(encryptionKey, 32));
      final key = Key.fromUtf8(keyValue);
      final iv = IV.fromLength(32);
      final encrypter = Encrypter(AES(key));
      encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted!.base64;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  String decryptAES(plainText, String encryptionKey) {
    try {
      String keyValue =
          String.fromCharCodes(padKeyWithZeros(encryptionKey, 32));
      final key = Key.fromUtf8(keyValue);
      final iv = IV.fromLength(32);
      final encrypter = Encrypter(AES(key));
      encrypted = Encrypted.from64(plainText);
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

  String encryptFernet(plainText, String encryptionKey) {
    try {
      final key = Key.fromUtf8(encryptionKey);
      final b64key = Key.fromUtf8(base64Url.encode(key.bytes));
      final fernet = Fernet(b64key);
      final encrypter = Encrypter(fernet);
      fernetEncrypted = encrypter.encrypt(plainText);
      return fernetEncrypted!.base64; // random cipher text
      // print(fernet.extractTimestamp(fernetEncrypted!.bytes));
    } on Exception catch (e) {
      return e.toString();
    }
  }

  String decryptFernet(plainText, String encryptionKey) {
    try {
      final key = Key.fromUtf8(encryptionKey);
      //final iv = IV.fromLength(16);
      final b64key = Key.fromUtf8(base64Url.encode(key.bytes));
      final fernet = Fernet(b64key);
      final encrypter = Encrypter(fernet);
      fernetEncrypted == Encrypted.from64(plainText);
      var fernetDecrypted = encrypter.decrypt(fernetEncrypted!);
      return fernetDecrypted;
    } on Exception catch (e) {
      return e.toString();
    }
  }
}
