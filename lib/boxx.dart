import 'dart:async';
import 'helper/boxx_factory.dart';
import 'helper/boxx_interface.dart';

/// Encryption Modes
/// Modes are placed in this file to make it easier to implement
enum EncryptionMode { aes, fernet, none }

/// Class to handle all local storage
class Boxx {
  final EncryptionMode? mode;
  final String? encryptionKey;
  late final BoxxInterface _platform;

  /// Cache to speed up read operations
  final Map<String, dynamic> _cache = {};

  /// Constructor for Boxx
  /// This will initialize the BoxxInterface based on the platform and encryption mode
  /// It uses the BoxxFactory to get the correct implementation for the current platform
  /// The encryptionKey is optional and can be used for AES or Fernet encryption
  Boxx({required this.mode, this.encryptionKey}) {
    _platform = BoxxFactory.instance.getBoxxInterface(
      mode: mode,
      encryptionKey: encryptionKey,
    );

    // Sync cache on changes
    _platform.onChange.listen((key) {
      if (key == '*') {
        _cache.clear();
      } else {
        _cache.remove(key);
      }
    });
  }

  /// Initialize the storage
  /// This must be called before any other operation
  Future<void> initialize() async {
    await _platform.initialize();
  }

  /// Save to local storage
  /// This will save the value to the local storage with the key
  /// If the key already exists, it will overwrite the value
  Future<void> put(String key, dynamic value) async {
    await _platform.put(key, value);
    _cache[key] = value;
  }

  /// Delete from local storage
  /// This will delete the value from the local storage with the key
  /// If the key does not exist, it will do nothing
  Future<void> delete(String key) async {
    await _platform.delete(key);
    _cache.remove(key);
  }

  /// Check if a key exists in local storage
  /// This will return true if the key exists, false otherwise
  Future<bool> exists(String key) async {
    if (_cache.containsKey(key)) return true;
    return await _platform.exists(key);
  }

  /// Get from local storage
  /// This will return the value stored in the local storage with the key
  /// If the key does not exist, it will return null
  /// You can specify a generic type T to get a casted result
  Future<T?> get<T>(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T?;
    }
    final value = await _platform.get(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value as T?;
  }

  /// Clear all data from local storage
  /// This will delete all data stored in the local storage
  Future<void> clear() async {
    await _platform.clear();
    _cache.clear();
  }

  /// Get all keys
  Future<List<String>> get keys => _platform.getKeys();

  /// Get all values
  Future<List<dynamic>> get values => _platform.getValues();

  /// Get all entries as a Map
  Future<Map<String, dynamic>> all() async {
    final k = await keys;
    final m = <String, dynamic>{};
    for (final key in k) {
      m[key] = await get(key);
    }
    return m;
  }

  /// Watch for changes to a specific key
  /// Returns a stream of the value associated with the key
  /// This will emit the current value immediately upon subscription
  Stream<T?> watch<T>(String key) async* {
    yield await get<T>(key);
    yield* _platform.onChange
        .where((k) => k == key || k == '*')
        .asyncMap((_) => get<T>(key));
  }

  /// Encrypt data using AES/Fernet
  /// This will encrypt the data using AES encryption with the provided encryption key
  String encrypt(String data) {
    /// Check if data is empty
    /// If it is empty, return an empty string
    if (data.isEmpty) {
      return '';
    }
    if (mode == EncryptionMode.aes && encryptionKey != null) {
      return _platform.aes.encryptAES(data, encryptionKey!);
    } else if (mode == EncryptionMode.fernet && encryptionKey != null) {
      return _platform.fernet.encryptFernet(data, encryptionKey!);
    } else {
      throw Exception(
        'Encryption mode is not set to AES/Fernet or encryption key is null',
      );
    }
  }

  /// Decrypt data using AES/Fernet
  /// This will decrypt the data using AES decryption with the provided encryption key
  String decrypt(String data) {
    /// Check if data is empty
    /// If it is empty, return an empty string
    if (data.isEmpty) {
      return '';
    }
    if (mode == EncryptionMode.aes && encryptionKey != null) {
      return _platform.aes.decryptAES(data, encryptionKey!);
    } else if (mode == EncryptionMode.fernet && encryptionKey != null) {
      return _platform.fernet.decryptFernet(data, encryptionKey!);
    } else {
      throw Exception(
        'Encryption mode is not set to AES/Fernet or encryption key is null',
      );
    }
  }

  /// Close the storage and internal resources
  void dispose() {
    _platform.dispose();
  }
}
