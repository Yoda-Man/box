import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:indexed_db/indexed_db.dart' as idb;
import '../src/encryption.dart';
import '../src/enum.dart';
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

  @override
  String path;

  final factory = idb.IdbFactory();
  late idb.OpenCreateResult result;
  late idb.Database database;
  late idb.Transaction transaction;
  static const storeName = 'boxx';

  /// Boxx setup for web
  BoxxHelper({required this.path, this.encryptionKey, this.mode}) {
    setup();
  }

  /// Boxx setup for web
  setup() async {
    String dbName = 'boxx';
    result = await factory.openCreate(dbName, storeName);
    database = result.database;
    transaction = database.transactionList([storeName], 'readwrite');
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    try {
      await transaction.objectStore(storeName).delete(key);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    try {
      int ressult = await transaction.objectStore(storeName).count(key);
      if (ressult < 0) {
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
      dynamic contents = '';

      if (encryptionKey == null) {
        contents = await transaction.objectStore(storeName).getObject(key);
      } else {
        contents = await transaction.objectStore(storeName).getObject(key);
        if (mode == EncryptionMode.fernet) {
          contents = fernet.decryptFernet(contents, encryptionKey!);
        } else {
          contents = aes.decryptAES(contents, encryptionKey!);
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
    //This is not available for web
    return '';
  }

  @override
  /// Save to local storage
  Future<void> put(String key, value) async {
    try {
      if (encryptionKey == null) {
        transaction.objectStore(storeName).put(value, key);
      } else {
        if (mode == EncryptionMode.fernet) {
          transaction
              .objectStore(storeName)
              .put(fernet.encryptFernet(value, encryptionKey!), key);
        }
        {
          transaction
              .objectStore(storeName)
              .put(aes.encryptAES(value, encryptionKey!), key);
        }
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}
