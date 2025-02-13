import 'dart:io';

import 'package:flutter/foundation.dart';
import 'src/global.dart';
import 'src/sanitize_filename.dart';

/// Enctryption Modes
enum EncryptionMode {
  aes,
  fernet,
}

/// Class to handle all local storage
class Box {
  String path;

  String? encryptionKey;
  EncryptionMode? mode;
  File? lastFile;

  Box({required this.path, this.encryptionKey, this.mode});

  /// Save to local storage
  put(String key, dynamic value) async {
    try {
      key = '${sanitizeFilename(key)}.boxx';
      if (!kIsWeb) {
        if (encryptionKey == null) {
          File('$path/$key').writeAsString(value);
        } else {
          if (mode == EncryptionMode.fernet) {
            File('$path/$key')
                .writeAsString(fernet.encryptFernet(value, encryptionKey!));
          }
          {
            File('$path/$key')
                .writeAsString(aes.encryptAES(value, encryptionKey!));
          }
        }
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Delete from local storage
  delete(String key) async {
    try {
      key = '${sanitizeFilename(key)}.boxx';
      if (!kIsWeb) {
        File file = File('$path/$key');
        lastFile = file;
        if (await file.exists()) {
          file.delete();
        }
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool> exists(String key) async {
    if (!kIsWeb) {
      File file = File('$path/$key');
      lastFile = file;
      return await file.exists();
    } else {
      return false;
    }
  }

  /// Get from local storage
  Future<dynamic> get(String key) async {
    try {
      dynamic contents = '';
      key = '${sanitizeFilename(key)}.boxx';
      if (!kIsWeb) {
        File file = File('$path/$key');
        lastFile = file;
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
      }
      return contents;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return '';
    }
  }
}
