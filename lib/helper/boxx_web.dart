import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import '../src/encryption.dart';
import '../boxx.dart';
import 'boxx_interface.dart';

/// Boxx helper for web
class BoxxHelper implements BoxxInterface {
  @override
  EncryptAES aes = EncryptAES();

  @override
  String? encryptionKey;

  @override
  EncryptFernet fernet = EncryptFernet();

  @override
  EncryptionMode? mode;

  static const storeName = 'boxx';
  static const dbName = 'boxx';

  /// Boxx setup for web
  BoxxHelper({required this.mode, this.encryptionKey}) {
    try {
      _initDB();
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<Database> _initDB() async {
    // Open the database (creates it if it doesn't exist)
    final factory = getIdbFactory();
    final db = await factory!.open(
      dbName,
      version: 1,
      onUpgradeNeeded: (VersionChangeEvent e) {
        // Create object stores (tables) if they don't exist
        final db = (e.target as OpenDBRequest).result;
        if (!db.objectStoreNames.contains(storeName)) {
          db.createObjectStore(storeName, keyPath: 'id');
        }
      },
    );
    return db;
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    try {
      final db = await _initDB();
      final transaction = db.transaction(storeName, 'readwrite');
      final store = transaction.objectStore(storeName);

      await store.delete(key);
      await transaction.completed;
      db.close();
    } catch (e) {
      debugPrint(e.toString());
      //rethrow;
    }
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    try {
      final db = await _initDB();
      final transaction = db.transaction(storeName, 'readonly');
      final store = transaction.objectStore(storeName);

      final data = await store.getObject(key);

      if (data == null) {
        return false;
      } else {
        return true;
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  @override
  /// Get from local storage
  Future<dynamic> get(String key) async {
    try {
      final db = await _initDB();
      final transaction = db.transaction(storeName, 'readonly');
      final store = transaction.objectStore(storeName);

      dynamic data = await store.getObject(key);

      if (data != null) {
        if (mode == EncryptionMode.fernet && encryptionKey != null) {
          data = fernet.decryptFernet(data, encryptionKey!);
        } else if (mode == EncryptionMode.aes && encryptionKey != null) {
          data = aes.decryptAES(data, encryptionKey!);
        }
      }

      await transaction.completed;
      db.close();
      return data;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  @override
  /// Clear all data from local storage
  Future<void> clear() async {
    try {
      final db = await _initDB();
      final transaction = db.transaction(storeName, 'readwrite');
      final store = transaction.objectStore(storeName);
      store.clear();
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  /// Save to local storage
  Future<void> put(String key, value) async {
    try {
      final db = await _initDB();
      final transaction = db.transaction(storeName, 'readwrite');
      final store = transaction.objectStore(storeName);

      if (mode == EncryptionMode.fernet && encryptionKey != null) {
        await store.put(fernet.encryptFernet(value, encryptionKey!), key);
      } else if (mode == EncryptionMode.aes && encryptionKey != null) {
        await store.put(aes.encryptAES(value, encryptionKey!), key);
      } else {
        await store.put(value, key);
      }

      await transaction.completed;
      db.close();
    } catch (e) {
      debugPrint(e.toString());
      //rethrow;
    }
  }
}
