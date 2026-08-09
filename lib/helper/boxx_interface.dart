import 'dart:async';

import '../src/encryption.dart';
import '../src/encryption_mode.dart';
import '../src/record_codec.dart';

class _ChangeBus {
  final StreamController<String> controller =
      StreamController<String>.broadcast(sync: true);
  int references = 0;
}

/// Platform storage contract shared by native and web implementations.
abstract class BoxxInterface {
  BoxxInterface({
    required this.namespace,
    required this.mode,
    required this.encryptionKey,
    required this.legacyMode,
    required this.legacyEncryptionKey,
  }) : codec = StoredRecordCodec(
         mode: mode,
         encryptionKey: encryptionKey,
         legacyMode: legacyMode,
         legacyEncryptionKey: legacyEncryptionKey,
       ) {
    final bus = _changeBuses.putIfAbsent(namespace, _ChangeBus.new);
    bus.references++;
    _bus = bus;
  }

  static final Map<String, _ChangeBus> _changeBuses = {};

  final String namespace;
  final String? encryptionKey;
  final EncryptionMode mode;
  final String? legacyEncryptionKey;
  final EncryptionMode legacyMode;
  final StoredRecordCodec codec;
  final EncryptAES aes = EncryptAES();
  final EncryptFernet fernet = EncryptFernet();

  late final _ChangeBus _bus;
  bool _disposed = false;

  Stream<String> get onChange => _bus.controller.stream;

  Future<void> initialize();
  Future<void> put(String key, dynamic value);
  Future<void> delete(String key);
  Future<bool> exists(String key);
  Future<dynamic> get(String key);
  Future<void> clear();
  Future<List<String>> getKeys();
  Future<List<dynamic>> getValues();

  /// Emits an in-process change. Web overrides this to broadcast across tabs.
  void notifyListeners(String key) {
    if (!_bus.controller.isClosed) {
      _bus.controller.add(key);
    }
  }

  /// Emits a change received from another process or browser context.
  void notifyRemoteListeners(String key) {
    if (!_bus.controller.isClosed) {
      _bus.controller.add(key);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _bus.references--;
    if (_bus.references == 0) {
      _changeBuses.remove(namespace);
      unawaited(_bus.controller.close());
    }
  }
}
