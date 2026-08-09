import 'dart:async';
import 'dart:convert';

import 'helper/boxx_factory.dart';
import 'helper/boxx_interface.dart';
import 'src/encryption_mode.dart';
import 'src/exceptions.dart';

export 'src/encryption_mode.dart';
export 'src/exceptions.dart';

/// Versioned, reactive key-value storage for Flutter.
class Boxx {
  Boxx({
    required this.mode,
    this.encryptionKey,
    this.name = 'default',
    EncryptionMode? legacyMode,
    String? legacyEncryptionKey,
    this.diagnostics,
  }) : legacyMode = legacyMode ?? mode,
       legacyEncryptionKey = (legacyMode ?? mode) == EncryptionMode.none
           ? null
           : (legacyEncryptionKey ?? encryptionKey) {
    _validateConfiguration();
    _platform = BoxxFactory.instance.getBoxxInterface(
      namespace: name,
      mode: mode,
      encryptionKey: encryptionKey,
      legacyMode: this.legacyMode,
      legacyEncryptionKey: this.legacyEncryptionKey,
    );
  }

  final EncryptionMode mode;
  final String? encryptionKey;

  /// Isolates records from other Boxx instances in the same application.
  final String name;

  /// Encryption mode used by pre-v2 records during automatic migration.
  final EncryptionMode legacyMode;
  final String? legacyEncryptionKey;

  /// Optional structured failure callback. Keys and values are never included.
  final BoxxDiagnostics? diagnostics;

  late final BoxxInterface _platform;
  final Set<StreamController<dynamic>> _watchControllers = {};
  Future<void>? _initialization;
  bool _initialized = false;
  bool _disposed = false;

  void _validateConfiguration() {
    if (name.trim().isEmpty || name.length > 128) {
      throw const BoxxConfigurationException(
        'name must contain 1 to 128 characters',
      );
    }
    _validateEncryption(
      mode,
      encryptionKey,
      label: 'current',
      minimumBytes: 32,
    );
    _validateEncryption(
      legacyMode,
      legacyEncryptionKey,
      label: 'legacy',
      minimumBytes: 1,
    );
  }

  static void _validateEncryption(
    EncryptionMode mode,
    String? key, {
    required String label,
    required int minimumBytes,
  }) {
    if (mode == EncryptionMode.none) {
      if (key != null) {
        throw BoxxConfigurationException(
          '$label encryption key must be omitted when mode is none',
        );
      }
      return;
    }
    if (key == null || utf8.encode(key).length < minimumBytes) {
      throw BoxxConfigurationException(
        '$label encryption requires a key of at least $minimumBytes UTF-8 bytes',
      );
    }
  }

  /// Opens the backing store. Operations also initialize lazily.
  Future<void> initialize() {
    _ensureActive();
    if (_initialized) return Future.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _platform.initialize();
      _initialized = true;
    } catch (error, stackTrace) {
      _report('initialize', error, stackTrace);
      _initialization = null;
      _throwStorageFailure('initialize', error, stackTrace);
    }
  }

  Future<void> put(String key, dynamic value) =>
      _run('put', () => _platform.put(_validateKey(key), value));

  Future<void> delete(String key) =>
      _run('delete', () => _platform.delete(_validateKey(key)));

  Future<bool> exists(String key) =>
      _run('exists', () => _platform.exists(_validateKey(key)));

  Future<T?> get<T>(String key) async {
    final value = await _run('get', () => _platform.get(_validateKey(key)));
    try {
      return value as T?;
    } on TypeError catch (error, stackTrace) {
      final exception = BoxxTypeMismatchException(
        expectedType: '$T',
        actualType: value.runtimeType.toString(),
      );
      _report('get', exception, stackTrace);
      Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  Future<void> clear() => _run('clear', _platform.clear);

  Future<List<String>> get keys => _run('keys', _platform.getKeys);

  Future<List<dynamic>> get values => _run('values', _platform.getValues);

  Future<Map<String, dynamic>> all() async {
    final allKeys = await keys;
    final allValues = await Future.wait<dynamic>(
      allKeys.map<Future<dynamic>>((key) => get<dynamic>(key)),
    );
    return Map<String, dynamic>.fromIterables(allKeys, allValues);
  }

  /// Watches changes made by Boxx instances in this isolate and across web tabs.
  Stream<T?> watch<T>(String key) {
    _ensureActive();
    final validKey = _validateKey(key);
    late StreamController<T?> controller;
    StreamSubscription<String>? subscription;
    var initializing = true;
    var changedDuringInitialization = false;
    Future<void> pending = Future.value();

    void enqueueRead() {
      pending = pending.then((_) async {
        try {
          final value = await get<T>(validKey);
          if (!controller.isClosed) controller.add(value);
        } catch (error, stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        }
      });
    }

    controller = StreamController<T?>(
      onListen: () {
        subscription = _platform.onChange
            .where((changedKey) => changedKey == validKey || changedKey == '*')
            .listen((_) {
              if (initializing) {
                changedDuringInitialization = true;
              } else {
                enqueueRead();
              }
            }, onError: controller.addError);
        enqueueRead();
        unawaited(
          pending.whenComplete(() {
            initializing = false;
            if (changedDuringInitialization) enqueueRead();
          }),
        );
      },
      onCancel: () async {
        await subscription?.cancel();
        _watchControllers.remove(controller);
      },
    );
    _watchControllers.add(controller);
    return controller.stream;
  }

  /// Encrypts a standalone string using this instance's configured mode.
  String encrypt(String data) => _runSync('encrypt', () {
    if (data.isEmpty) return '';
    return switch (mode) {
      EncryptionMode.aes => _platform.aes.encryptAES(data, encryptionKey!),
      EncryptionMode.fernet => _platform.fernet.encryptFernet(
        data,
        encryptionKey!,
      ),
      EncryptionMode.none => throw const BoxxConfigurationException(
        'Manual encryption requires AES or Fernet mode',
      ),
    };
  });

  /// Decrypts a standalone string created by [encrypt].
  String decrypt(String data) => _runSync('decrypt', () {
    if (data.isEmpty) return '';
    return switch (mode) {
      EncryptionMode.aes => _platform.aes.decryptAES(data, encryptionKey!),
      EncryptionMode.fernet => _platform.fernet.decryptFernet(
        data,
        encryptionKey!,
      ),
      EncryptionMode.none => throw const BoxxConfigurationException(
        'Manual decryption requires AES or Fernet mode',
      ),
    };
  });

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final controller in _watchControllers.toList()) {
      unawaited(controller.close());
    }
    _watchControllers.clear();
    _platform.dispose();
  }

  String _validateKey(String key) {
    if (key.isEmpty) {
      throw const BoxxConfigurationException('Storage keys must not be empty');
    }
    if (utf8.encode(key).length > 4096) {
      throw const BoxxConfigurationException(
        'Storage keys must not exceed 4096 UTF-8 bytes',
      );
    }
    return key;
  }

  Future<T> _run<T>(String operation, Future<T> Function() action) async {
    _ensureActive();
    await initialize();
    try {
      return await action();
    } on BoxxException catch (error, stackTrace) {
      _report(operation, error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _report(operation, error, stackTrace);
      _throwStorageFailure(operation, error, stackTrace);
    }
  }

  T _runSync<T>(String operation, T Function() action) {
    _ensureActive();
    try {
      return action();
    } on BoxxException catch (error, stackTrace) {
      _report(operation, error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _report(operation, error, stackTrace);
      Error.throwWithStackTrace(
        BoxxEncryptionException('$operation failed', cause: error),
        stackTrace,
      );
    }
  }

  void _ensureActive() {
    if (_disposed) throw const BoxxDisposedException();
  }

  Never _throwStorageFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is BoxxException) Error.throwWithStackTrace(error, stackTrace);
    Error.throwWithStackTrace(
      BoxxStorageException(operation, error),
      stackTrace,
    );
  }

  void _report(String operation, Object error, StackTrace stackTrace) {
    try {
      diagnostics?.call(
        BoxxDiagnosticEvent(
          operation: operation,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (_) {
      // Diagnostics must never alter storage behavior.
    }
  }
}
