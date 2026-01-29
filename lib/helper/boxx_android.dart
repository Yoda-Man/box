import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../boxx.dart';
import '../src/sanitize_filename.dart';
import 'boxx_interface.dart';

/// Boxx helper for none web
class BoxxHelper extends BoxxInterface {
  BoxxHelper({required super.mode, super.encryptionKey});

  String? _path;

  @override
  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    _path = directory.path;
  }

  /// Ensure the path is initialized before use
  Future<String> get _storagePath async {
    if (_path == null) {
      await initialize();
    }
    return _path!;
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    final path = await _storagePath;
    File file = File(_keyPath(path, key));
    if (await file.exists()) {
      await file.delete();
      notifyListeners(key);
    }
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    final path = await _storagePath;
    File file = File(_keyPath(path, key));
    return await file.exists();
  }

  @override
  /// Clear all data from local storage
  Future<void> clear() async {
    final path = await _storagePath;
    Directory dir = Directory(path);
    if (await dir.exists()) {
      List<FileSystemEntity> files = dir.listSync();
      for (FileSystemEntity file in files) {
        if (file is File && file.path.endsWith('.boxx')) {
          await file.delete();
        }
      }
      notifyListeners('*');
    }
  }

  @override
  /// Get from local storage
  Future<dynamic> get(String key) async {
    final path = await _storagePath;
    File file = File(_keyPath(path, key));

    if (await file.exists()) {
      String contents = await file.readAsString();
      if (mode == EncryptionMode.fernet && encryptionKey != null) {
        contents = fernet.decryptFernet(contents, encryptionKey!);
      } else if (mode == EncryptionMode.aes && encryptionKey != null) {
        contents = aes.decryptAES(contents, encryptionKey!);
      }

      try {
        return jsonDecode(contents);
      } catch (_) {
        return contents;
      }
    }
    return null;
  }

  ///Get key path
  String _keyPath(String basePath, String key) {
    key = '${sanitizeFilename(key)}.boxx';
    return '$basePath/$key';
  }

  @override
  /// Save to local storage
  Future<void> put(String key, dynamic value) async {
    final path = await _storagePath;
    final file = File(_keyPath(path, key));

    String dataToStore = (value is String || value is num || value is bool)
        ? value.toString()
        : jsonEncode(value);

    if (mode == EncryptionMode.fernet && encryptionKey != null) {
      dataToStore = fernet.encryptFernet(dataToStore, encryptionKey!);
    } else if (mode == EncryptionMode.aes && encryptionKey != null) {
      dataToStore = aes.encryptAES(dataToStore, encryptionKey!);
    }

    await file.writeAsString(dataToStore);
    notifyListeners(key);
  }

  @override
  Future<List<String>> getKeys() async {
    final path = await _storagePath;
    Directory dir = Directory(path);
    if (await dir.exists()) {
      return dir
          .listSync()
          .where((e) => e is File && e.path.endsWith('.boxx'))
          .map(
            (e) => File(e.path).uri.pathSegments.last.replaceFirst('.boxx', ''),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<List<dynamic>> getValues() async {
    final keys = await getKeys();
    final values = <dynamic>[];
    for (final key in keys) {
      values.add(await get(key));
    }
    return values;
  }
}
