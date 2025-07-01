import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:indexed_db/indexed_db.dart';
import 'package:web/web.dart';
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

  final factory = IdbFactory();

  Transaction? transaction;
  static const storeName = 'boxx';

  /// Boxx setup for web
  BoxxHelper({required this.mode, this.encryptionKey}) {
    setup();
  }

  /// Boxx setup for web
  Future<void> setup() async {
    try {
      String dbName = 'boxx';
      Database database;
      // Await the JSPromise and convert it to a JSArray
      JSArray<IDBDatabaseInfo> jsArray =
          await factory.idbObject.databases().toDart;

      // Convert the JSArray to a Dart List of Strings
      List<String> databases =
          jsArray.toDart.map((dbInfo) {
            // Assuming IDBDatabaseInfo has a 'name' property
            return dbInfo.name;
          }).toList();

      if (databases.contains(dbName)) {
        database = await factory.open(dbName);
        transaction = database.transactionList([storeName], 'readwrite');
      } else {
        OpenCreateResult result;
        result = await factory.openCreate(dbName, storeName);
        database = result.database;
        transaction = database.transactionList([storeName], 'readwrite');
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> checkTransaction() async {
    if (transaction == null) {
      await setup();
    }
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    try {
      await checkTransaction();
      if (transaction == null) {
        return;
      }
      await transaction!.objectStore(storeName).delete(key);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  /// Check if key exists in local storage
  Future<bool> exists(String key) async {
    try {
      await checkTransaction();
      if (transaction == null) {
        return false;
      }
      int ressult = await transaction!.objectStore(storeName).count(key);
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
      await checkTransaction();
      if (transaction == null) {
        return '';
      }
      contents = await transaction!.objectStore(storeName).getObject(key);
      if (mode == EncryptionMode.fernet && encryptionKey != null) {
        contents = fernet.decryptFernet(contents, encryptionKey!);
      } else if (mode == EncryptionMode.aes && encryptionKey != null) {
        contents = aes.decryptAES(contents, encryptionKey!);
      }
      return contents;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return '';
    }
  }

  @override
  /// Clear all data from local storage
  Future<void> clear() async {
    try {
      await checkTransaction();
      if (transaction == null) {
        return;
      }
      transaction!.objectStore(storeName).clear();
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  /// Save to local storage
  Future<void> put(String key, value) async {
    try {
      await checkTransaction();
      if (transaction == null) {
        return;
      }
      if (mode == EncryptionMode.fernet && encryptionKey != null) {
        transaction!
            .objectStore(storeName)
            .put(fernet.encryptFernet(value, encryptionKey!), key);
      } else if (mode == EncryptionMode.aes && encryptionKey != null) {
        transaction!
            .objectStore(storeName)
            .put(aes.encryptAES(value, encryptionKey!), key);
      } else {
        transaction!.objectStore(storeName).put(value, key);
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}
