import 'package:encrypt/encrypt.dart';
import 'dart:convert';

///for AES Algorithms
class EncryptAES {
  static Encrypted? encrypted;
  // static var decrypted;

  String encryptAES(plainText, String encryptionKey) {
    final key = Key.fromUtf8(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted!.base64;
  }

  String decryptAES(plainText, String encryptionKey) {
    final key = Key.fromUtf8(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    var decrypted = encrypter.decrypt(encrypted!, iv: iv);
    return decrypted;
  }
}

///for Fernet Algorithms
class EncryptFernet {
  static Encrypted? fernetEncrypted;

  String encryptFernet(plainText, String encryptionKey) {
    final key = Key.fromUtf8(encryptionKey);
    final b64key = Key.fromUtf8(base64Url.encode(key.bytes));
    final fernet = Fernet(b64key);
    final encrypter = Encrypter(fernet);
    fernetEncrypted = encrypter.encrypt(plainText);
    return fernetEncrypted!.base64; // random cipher text
    // print(fernet.extractTimestamp(fernetEncrypted!.bytes));
  }

  String decryptFernet(plainText, String encryptionKey) {
    final key = Key.fromUtf8(encryptionKey);
    //final iv = IV.fromLength(16);
    final b64key = Key.fromUtf8(base64Url.encode(key.bytes));
    final fernet = Fernet(b64key);
    final encrypter = Encrypter(fernet);
    var fernetDecrypted = encrypter.decrypt(fernetEncrypted!);
    return fernetDecrypted;
  }
}
