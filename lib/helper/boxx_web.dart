import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';

import '../src/encryption.dart';
import '../boxx.dart';
import 'boxx_interface.dart';

/// Boxx helper for web platform
class BoxxHelper implements BoxxInterface {
  @override
  final EncryptAES aes = EncryptAES();

  @override
  final EncryptFernet fernet = EncryptFernet();

  @override
  final EncryptionMode? mode;

  @override
  final String? encryptionKey;

  static const String storeName = 'boxx';
  static const String dbName = 'boxx';

  Database? _db;

  BoxxHelper({required this.mode, this.encryptionKey}) {
    _initDB().catchError((e, st) {
      debugPrint('BoxxHelper setup error: $e\n$st');
    });
  }

  /// Boxx setup for web
  Future<Database> _initDB() async {
    if (_db != null) return _db!;
    final factory = getIdbFactory();
    if (factory == null) throw StateError('IndexedDB factory is null');

    _db = await factory.open(
      dbName,
      version: 1,
      onUpgradeNeeded: (e) {
        final db = (e.target as OpenDBRequest).result;
        if (!db.objectStoreNames.contains(storeName)) {
          db.createObjectStore(storeName, keyPath: 'id');
        }
      },
    );
    return _db!;
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    try {
      final db = await _initDB();
      final txn = db.transaction(storeName, idbModeReadWrite);
      await txn.objectStore(storeName).delete(key);
      await txn.completed;
    } catch (e, st) {
      debugPrint('Delete error: $e\n$st');
    }
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    try {
      final db = await _initDB();
      final txn = db.transaction(storeName, idbModeReadOnly);
      final value = await txn.objectStore(storeName).getObject(key);
      await txn.completed;
      return value != null;
    } catch (e, st) {
      debugPrint('Exists check error: $e\n$st');
      return false;
    }
  }

  @override
  /// Get from local storage
  Future<dynamic> get(String key) async {
    try {
      final db = await _initDB();
      final txn = db.transaction(storeName, idbModeReadOnly);
      dynamic data = await txn.objectStore(storeName).getObject(key);
      await txn.completed;

      if (data != null && encryptionKey != null && mode != null) {
        switch (mode!) {
          case EncryptionMode.fernet:
            data = fernet.decryptFernet(data, encryptionKey!);
            break;
          case EncryptionMode.aes:
            data = aes.decryptAES(data, encryptionKey!);
            break;
          default:
            break;
        }
      }
      return data;
    } catch (e, st) {
      debugPrint('Get error: $e\n$st');
      return null;
    }
  }

  @override
  /// Clear all data from local storage
  Future<void> clear() async {
    try {
      final db = await _initDB();
      final txn = db.transaction(storeName, idbModeReadWrite);
      await txn.objectStore(storeName).clear();
      await txn.completed;
    } catch (e, st) {
      debugPrint('Clear storage error: $e\n$st');
    }
  }

  @override
  /// Save to local storage
  Future<void> put(String key, dynamic value) async {
    try {
      final db = await _initDB();
      final txn = db.transaction(storeName, idbModeReadWrite);
      String dataToStore;

      if (encryptionKey != null && mode != null) {
        switch (mode!) {
          case EncryptionMode.fernet:
            dataToStore = fernet.encryptFernet(
              value.toString(),
              encryptionKey!,
            );
            break;
          case EncryptionMode.aes:
            dataToStore = aes.encryptAES(value.toString(), encryptionKey!);
            break;
          default:
            dataToStore = value.toString();
        }
      } else {
        dataToStore = value.toString();
      }

      await txn.objectStore(storeName).put(dataToStore, key);
      await txn.completed;
    } catch (e, st) {
      debugPrint('Put error: $e\n$st');
    }
  }
}
