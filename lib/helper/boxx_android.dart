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
  final EncryptAES aes = EncryptAES();

  @override
  final EncryptFernet fernet = EncryptFernet();

  @override
  final EncryptionMode? mode;

  @override
  final String? encryptionKey;

  String? _path;

  BoxxHelper({required this.mode, this.encryptionKey}) {
    _init();
  }

  /// Boxx setup for non web
  Future<void> _init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _path = directory.path;
    } on Exception catch (e, st) {
      debugPrint('BoxxHelper setup error: $e\n$st');
    }
  }

  /// Ensure the path is initialized before use
  Future<String?> get _storagePath async {
    if (_path == null) {
      await _init();
    }
    return _path;
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    try {
      final path = await _storagePath;
      if (path == null) return;

      File file = File(_keyPath(key));
      if (await file.exists()) {
        file.delete();
      }
    } on Exception catch (e, st) {
      debugPrint('Delete error: $e\n$st');
    }
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    try {
      final path = await _storagePath;
      if (path == null) return false;

      File file = File(_keyPath(key));
      return await file.exists();
    } on Exception catch (e, st) {
      debugPrint('Exists check error: $e\n$st');
      return false;
    }
  }

  @override
  /// Clear all data from local storage
  Future<void> clear() async {
    try {
      final path = await _storagePath;
      if (path == null) return;

      Directory dir = Directory(_path!);
      if (await dir.exists()) {
        List<FileSystemEntity> files = dir.listSync();
        for (FileSystemEntity file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } on Exception catch (e, st) {
      debugPrint('Clear storage error: $e\n$st');
    }
  }

  @override
  /// Get from local storage
  Future<dynamic> get(String key) async {
    try {
      dynamic contents;
      final path = await _storagePath;
      if (path == null) return null;

      File file = File(_keyPath(key));
      if (await file.exists()) {
        contents = await file.readAsString();
        if (mode == EncryptionMode.fernet && encryptionKey != null) {
          contents = fernet.decryptFernet(contents, encryptionKey!);
        } else if (mode == EncryptionMode.aes && encryptionKey != null) {
          contents = aes.decryptAES(contents, encryptionKey!);
        }
      }

      return contents;
    } on Exception catch (e, st) {
      debugPrint('Get error: $e\n$st');
      return null;
    }
  }

  ///Get key path
  String _keyPath(String key) {
    key = '${sanitizeFilename(key)}.boxx';
    return '$_path/$key';
  }

  @override
  /// Save to local storage
  Future<void> put(String key, dynamic value) async {
    try {
      final path = await _storagePath;
      if (path == null) return;

      if (mode == EncryptionMode.fernet && encryptionKey != null) {
        File(
          _keyPath(key),
        ).writeAsString(fernet.encryptFernet(value.toString(), encryptionKey!));
      } else if (mode == EncryptionMode.aes && encryptionKey != null) {
        File(
          _keyPath(key),
        ).writeAsString(aes.encryptAES(value.toString(), encryptionKey!));
      } else {
        File(_keyPath(key)).writeAsString(value.toString());
      }
    } on Exception catch (e, st) {
      debugPrint('Put error: $e\n$st');
    }
  }
}
