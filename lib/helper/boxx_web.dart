import 'dart:async';
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

  BoxxHelper({required this.mode, this.encryptionKey});

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

    if (data != null && encryptionKey != null && mode != null) {
      if (mode == EncryptionMode.fernet) {
        data = fernet.decryptFernet(data, encryptionKey!);
      } else if (mode == EncryptionMode.aes) {
        data = aes.decryptAES(data, encryptionKey!);
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
  }

  @override
  /// Save to local storage
  Future<void> put(String key, dynamic value) async {
    final db = await _initializedDB;
    final txn = db.transaction(storeName, idbModeReadWrite);
    String dataToStore = value.toString();

    if (encryptionKey != null && mode != null) {
      if (mode == EncryptionMode.fernet) {
        dataToStore = fernet.encryptFernet(dataToStore, encryptionKey!);
      } else if (mode == EncryptionMode.aes) {
        dataToStore = aes.encryptAES(dataToStore, encryptionKey!);
      }
    }

    await txn.objectStore(storeName).put(dataToStore, key);
    await txn.completed;
  }
}
