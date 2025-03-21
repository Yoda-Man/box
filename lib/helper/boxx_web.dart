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

  @override
  String path;

  final factory = IdbFactory();

  Transaction? transaction;
  static const storeName = 'boxx';

  /// Boxx setup for web
  BoxxHelper({required this.path, this.encryptionKey, this.mode}) {
    setup();
  }

  /// Boxx setup for web
  setup() async {
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

  checkTransaction() async {
    if (transaction == null) {
      await setup();
    }
  }

  @override
  /// Delete from local storage
  Future<void> delete(String key) async {
    try {
      checkTransaction();
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
      checkTransaction();
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
      checkTransaction();
      if (transaction == null) {
        return '';
      }
      if (encryptionKey == null) {
        contents = await transaction!.objectStore(storeName).getObject(key);
      } else {
        contents = await transaction!.objectStore(storeName).getObject(key);
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
      checkTransaction();
      if (transaction == null) {
        return;
      }
      if (encryptionKey == null) {
        transaction!.objectStore(storeName).put(value, key);
      } else {
        if (mode == EncryptionMode.fernet) {
          transaction!
              .objectStore(storeName)
              .put(fernet.encryptFernet(value, encryptionKey!), key);
        }
        {
          transaction!
              .objectStore(storeName)
              .put(aes.encryptAES(value, encryptionKey!), key);
        }
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}
