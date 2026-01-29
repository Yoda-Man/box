import 'dart:async';
import '../src/encryption.dart';
import '../boxx.dart';

/// Blueprint for boxx platform classes, providing the structure that must be followed by boxx subclasses
/// to maintain a consistent API. This ensures that developers using boxx have a predictable and standardized interface to work with
abstract class BoxxInterface {
  final String? encryptionKey;
  final EncryptionMode? mode;

  final EncryptAES aes = EncryptAES();
  final EncryptFernet fernet = EncryptFernet();

  /// Stream controller to notify listeners of changes
  final StreamController<String> _changeController =
      StreamController<String>.broadcast();

  /// Stream of altered keys
  Stream<String> get onChange => _changeController.stream;

  BoxxInterface({required this.mode, this.encryptionKey});

  Future<void> initialize();

  /// Save to local storage
  Future<void> put(String key, dynamic value);

  /// Delete from local storage
  Future<void> delete(String key);

  /// Check if key exists in local storage
  Future<bool> exists(String key);

  /// Get from local storage
  Future<dynamic> get(String key);

  /// Clear all data from local storage
  Future<void> clear();

  /// Get all keys
  Future<List<String>> getKeys();

  /// Get all values
  Future<List<dynamic>> getValues();

  /// Notify listeners that a key has changed
  void notifyListeners(String key) {
    _changeController.add(key);
  }

  /// Close the stream controller
  void dispose() {
    _changeController.close();
  }
}
