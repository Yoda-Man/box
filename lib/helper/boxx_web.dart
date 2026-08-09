import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

import 'package:idb_shim/idb_browser.dart';
import 'package:web/web.dart' as web;

import '../src/storage_key.dart';
import 'boxx_interface.dart';

/// IndexedDB implementation used by Flutter web.
class BoxxHelper extends BoxxInterface {
  BoxxHelper({
    required super.namespace,
    required super.mode,
    required super.encryptionKey,
    required super.legacyMode,
    required super.legacyEncryptionKey,
  });

  static const String _dbName = 'boxx';
  static const String _recordStore = 'records';
  static const String _legacyStore = 'boxx';
  static const int _dbVersion = 2;
  static final LinkedHashSet<String> _seenChangeIds = LinkedHashSet<String>();

  Database? _db;
  web.BroadcastChannel? _channel;
  final String _instanceId =
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(4294967296)}';
  int _changeSequence = 0;

  String get _namespacePrefix => '${storageIdentifier(namespace)}:';
  String _recordId(String key) => '$_namespacePrefix${storageIdentifier(key)}';

  @override
  Future<void> initialize() async {
    if (_db != null) return;
    final factory = getIdbFactory();
    if (factory == null) {
      throw StateError('IndexedDB is unavailable in this browser context');
    }
    _db = await factory.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (event) {
        final database = (event.target as OpenDBRequest).result;
        if (!database.objectStoreNames.contains(_recordStore)) {
          // Out-of-line keys: callers provide the stable record identifier.
          database.createObjectStore(_recordStore);
        }
      },
    );
    _channel = web.BroadcastChannel('boxx:${storageIdentifier(namespace)}');
    _channel!.onmessage = ((web.Event event) {
      final data = (event as web.MessageEvent).data.dartify();
      if (data is! String) return;
      dynamic message;
      try {
        message = jsonDecode(data);
      } on FormatException {
        return;
      }
      if (message is! Map<String, dynamic> ||
          message['id'] is! String ||
          message['key'] is! String) {
        return;
      }
      final id = message['id'] as String;
      if (_rememberChange(id)) {
        notifyRemoteListeners(message['key'] as String);
      }
    }).toJS;
  }

  Future<Database> get _database async {
    await initialize();
    return _db!;
  }

  bool get _hasLegacyStore =>
      _db?.objectStoreNames.contains(_legacyStore) ?? false;

  @override
  void notifyListeners(String key) {
    final id = '$_instanceId-${_changeSequence++}';
    _rememberChange(id);
    super.notifyListeners(key);
    _channel?.postMessage(jsonEncode({'id': id, 'key': key}).toJS);
  }

  static bool _rememberChange(String id) {
    if (!_seenChangeIds.add(id)) return false;
    if (_seenChangeIds.length > 256) {
      _seenChangeIds.remove(_seenChangeIds.first);
    }
    return true;
  }

  @override
  Future<void> put(String key, dynamic value) async {
    final database = await _database;
    final transaction = database.transaction(_recordStore, idbModeReadWrite);
    await transaction
        .objectStore(_recordStore)
        .put(codec.encode(key, value), _recordId(key));
    await transaction.completed;
    if (namespace == 'default' && _hasLegacyStore) {
      final legacy = database.transaction(_legacyStore, idbModeReadWrite);
      await legacy.objectStore(_legacyStore).delete(key);
      await legacy.completed;
    }
    notifyListeners(key);
  }

  @override
  Future<dynamic> get(String key) async {
    final database = await _database;
    final transaction = database.transaction(_recordStore, idbModeReadOnly);
    final raw = await transaction
        .objectStore(_recordStore)
        .getObject(_recordId(key));
    await transaction.completed;
    if (raw != null) {
      if (raw is! String) {
        throw const FormatException('IndexedDB record is not a string');
      }
      return codec.decode(raw, expectedKey: key, allowLegacy: false).value;
    }

    if (namespace != 'default' || !_hasLegacyStore) return null;
    final legacyTransaction = database.transaction(
      _legacyStore,
      idbModeReadOnly,
    );
    final legacyRaw = await legacyTransaction
        .objectStore(_legacyStore)
        .getObject(key);
    await legacyTransaction.completed;
    if (legacyRaw == null) return null;
    if (legacyRaw is! String) {
      throw const FormatException('Legacy IndexedDB record is not a string');
    }
    final decoded = codec.decode(
      legacyRaw,
      expectedKey: key,
      allowLegacy: true,
      legacyFallbackKey: key,
    );
    final migration = database.transactionList([
      _recordStore,
      _legacyStore,
    ], idbModeReadWrite);
    await migration
        .objectStore(_recordStore)
        .put(codec.encode(key, decoded.value), _recordId(key));
    await migration.objectStore(_legacyStore).delete(key);
    await migration.completed;
    notifyListeners(key);
    return decoded.value;
  }

  @override
  Future<void> delete(String key) async {
    final database = await _database;
    final stores = <String>[_recordStore];
    if (namespace == 'default' && _hasLegacyStore) stores.add(_legacyStore);
    final transaction = database.transactionList(stores, idbModeReadWrite);
    await transaction.objectStore(_recordStore).delete(_recordId(key));
    if (stores.contains(_legacyStore)) {
      await transaction.objectStore(_legacyStore).delete(key);
    }
    await transaction.completed;
    notifyListeners(key);
  }

  @override
  Future<bool> exists(String key) async {
    final database = await _database;
    final transaction = database.transaction(_recordStore, idbModeReadOnly);
    final value = await transaction
        .objectStore(_recordStore)
        .getObject(_recordId(key));
    await transaction.completed;
    if (value != null) return true;
    if (namespace != 'default' || !_hasLegacyStore) return false;
    final legacy = database.transaction(_legacyStore, idbModeReadOnly);
    final legacyValue = await legacy.objectStore(_legacyStore).getObject(key);
    await legacy.completed;
    return legacyValue != null;
  }

  @override
  Future<void> clear() async {
    final database = await _database;
    final keysTransaction = database.transaction(_recordStore, idbModeReadOnly);
    final recordIds = await keysTransaction
        .objectStore(_recordStore)
        .getAllKeys();
    await keysTransaction.completed;
    final matchingIds = recordIds
        .where((id) => id.toString().startsWith(_namespacePrefix))
        .toList();
    final transaction = database.transaction(_recordStore, idbModeReadWrite);
    for (final id in matchingIds) {
      await transaction.objectStore(_recordStore).delete(id);
    }
    await transaction.completed;
    notifyListeners('*');
  }

  @override
  Future<List<String>> getKeys() async {
    final database = await _database;
    final idsTransaction = database.transaction(_recordStore, idbModeReadOnly);
    final recordIds = await idsTransaction
        .objectStore(_recordStore)
        .getAllKeys();
    await idsTransaction.completed;
    final keys = <String>{};
    final matchingIds = recordIds.where(
      (id) => id.toString().startsWith(_namespacePrefix),
    );
    final transaction = database.transaction(_recordStore, idbModeReadOnly);
    final store = transaction.objectStore(_recordStore);
    final records = await Future.wait<dynamic>(
      matchingIds.map<Future<dynamic>>(store.getObject),
    );
    await transaction.completed;
    for (final raw in records) {
      if (raw is! String) {
        throw const FormatException('IndexedDB record is not a string');
      }
      keys.add(codec.decode(raw, allowLegacy: false).key);
    }
    return keys.toList()..sort();
  }

  @override
  Future<List<dynamic>> getValues() async {
    final keys = await getKeys();
    return Future.wait(keys.map(get));
  }

  @override
  void dispose() {
    _channel?.close();
    _channel = null;
    _db?.close();
    _db = null;
    super.dispose();
  }
}
