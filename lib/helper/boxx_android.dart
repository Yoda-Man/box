import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

  late String path;

  BoxxHelper({required this.mode, this.encryptionKey}) {
    setup();
  }

  /// Boxx setup for non web
  Future<void> setup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      path = directory.path;
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

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
  /// Clear all data from local storage
  Future<void> clear() async {
    try {
      Directory dir = Directory(path);
      if (await dir.exists()) {
        List<FileSystemEntity> files = dir.listSync();
        for (FileSystemEntity file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
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
