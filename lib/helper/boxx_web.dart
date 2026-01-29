import 'dart:async';
import 'dart:convert';
import 'package:idb_shim/idb_browser.dart';

import '../boxx.dart';
import 'boxx_interface.dart';

/// Boxx helper for web platform
class BoxxHelper extends BoxxInterface {
  BoxxHelper({required super.mode, super.encryptionKey});

  static const String storeName = 'boxx';
  static const String dbName = 'boxx';

  Database? _db;

  @override
  Future<void> initialize() async {
    if (_db != null) return;
    _db = await _initDB();
  }

  /// Boxx setup for web
  Future<Database> _initDB() async {
    final factory = getIdbFactory();
    if (factory == null) throw StateError('IndexedDB factory is null');

    return await factory.open(
      dbName,
      version: 1,
      onUpgradeNeeded: (e) {
        final db = (e.target as OpenDBRequest).result;
        if (!db.objectStoreNames.contains(storeName)) {
          db.createObjectStore(storeName, keyPath: 'id');
        }
      },
    );
  }

  Future<Database> get _initializedDB async {
    if (_db == null) {
      await initialize();
    }
    return _db!;
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    final db = await _initializedDB;
    final txn = db.transaction(storeName, idbModeReadWrite);
    await txn.objectStore(storeName).delete(key);
    await txn.completed;
    notifyListeners(key);
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    final db = await _initializedDB;
    final txn = db.transaction(storeName, idbModeReadOnly);
    final value = await txn.objectStore(storeName).getObject(key);
    await txn.completed;
    return value != null;
  }

  @override
  /// Get from local storage
  Future<dynamic> get(String key) async {
    final db = await _initializedDB;
    final txn = db.transaction(storeName, idbModeReadOnly);
    dynamic data = await txn.objectStore(storeName).getObject(key);
    await txn.completed;

    if (data != null) {
      if (encryptionKey != null && mode != null) {
        if (mode == EncryptionMode.fernet) {
          data = fernet.decryptFernet(data, encryptionKey!);
        } else if (mode == EncryptionMode.aes) {
          data = aes.decryptAES(data, encryptionKey!);
        }
      }

      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  @override
  /// Clear all data from local storage
  Future<void> clear() async {
    final db = await _initializedDB;
    final txn = db.transaction(storeName, idbModeReadWrite);
    await txn.objectStore(storeName).clear();
    await txn.completed;
    notifyListeners('*');
  }

  @override
  /// Save to local storage
  Future<void> put(String key, dynamic value) async {
    final db = await _initializedDB;
    final txn = db.transaction(storeName, idbModeReadWrite);
    String dataToStore = (value is String || value is num || value is bool)
        ? value.toString()
        : jsonEncode(value);

    if (encryptionKey != null && mode != null) {
      if (mode == EncryptionMode.fernet) {
        dataToStore = fernet.encryptFernet(dataToStore, encryptionKey!);
      } else if (mode == EncryptionMode.aes) {
        dataToStore = aes.encryptAES(dataToStore, encryptionKey!);
      }
    }

    await txn.objectStore(storeName).put(dataToStore, key);
    await txn.completed;
    notifyListeners(key);
  }

  @override
  Future<List<String>> getKeys() async {
    final db = await _initializedDB;
    final txn = db.transaction(storeName, idbModeReadOnly);
    final keys = await txn.objectStore(storeName).getAllKeys();
    await txn.completed;
    return keys.map((e) => e.toString()).toList();
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
