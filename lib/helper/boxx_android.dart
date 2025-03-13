import 'dart:io';

import 'package:flutter/foundation.dart';

import '../boxx.dart';
import '../src/encryption.dart';
import '../src/sanitize_filename.dart';
import 'boxx_interface.dart';

/// Boxx helper for none web
class BoxxHelper implements BoxxInterface {
  @override
  EncryptAES aes = EncryptAES();

  @override
  String? encryptionKey;

  @override
  EncryptFernet fernet = EncryptFernet();

  @override
  EncryptionMode? mode;

  @override
  String path;

  BoxxHelper({required this.path, this.encryptionKey, this.mode});

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    try {
      File file = File(keyPath(key));
      if (await file.exists()) {
        file.delete();
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    try {
      File file = File(keyPath(key));
      return await file.exists();
    } on Exception catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  @override
  /// Get from local storage
  Future<dynamic> get(String key) async {
    try {
      dynamic contents = '';

      File file = File(keyPath(key));
      if (await file.exists()) {
        if (encryptionKey == null) {
          contents = await file.readAsString();
        } else {
          contents = await file.readAsString();
          if (mode == EncryptionMode.fernet) {
            contents = fernet.decryptFernet(contents, encryptionKey!);
          } else {
            contents = aes.decryptAES(contents, encryptionKey!);
          }
        }
      }

      return contents;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return '';
    }
  }

  @override
  ///Get key path
  String keyPath(String key) {
    key = '${sanitizeFilename(key)}.boxx';
    return '$path/$key';
  }

  @override
  /// Save to local storage
  Future<void> put(String key, dynamic value) async {
    try {
      if (encryptionKey == null) {
        File(keyPath(key)).writeAsString(value);
      } else {
        if (mode == EncryptionMode.fernet) {
          File(
            keyPath(key),
          ).writeAsString(fernet.encryptFernet(value, encryptionKey!));
        }
        {
          File(
            keyPath(key),
          ).writeAsString(aes.encryptAES(value, encryptionKey!));
        }
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}
