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

  /// Constructor for Boxx
  /// This will initialize the BoxxInterface based on the platform and encryption mode
  /// It uses the BoxxFactory to get the correct implementation for the current platform
  /// The encryptionKey is optional and can be used for AES or Fernet encryption
  Boxx({required this.mode, this.encryptionKey}) {
    _platform = BoxxFactory.instance.getBoxxInterface(
      mode: mode,
      encryptionKey: encryptionKey,
    );
  }

  /// Save to local storage
  /// This will save the value to the local storage with the key
  /// If the key already exists, it will overwrite the value
  Future<void> put(String key, dynamic value) async {
    await _platform.put(key, value);
  }

  /// Delete from local storage
  /// This will delete the value from the local storage with the key
  /// If the key does not exist, it will do nothing
  Future<void> delete(String key) async {
    await _platform.delete(key);
  }

  /// Check if a key exists in local storage
  /// This will return true if the key exists, false otherwise
  Future<bool> exists(String key) async {
    return await _platform.exists(key);
  }

  /// Get from local storage
  /// This will return the value stored in the local storage with the key
  /// If the key does not exist, it will return null
  Future<dynamic> get(String key) async {
    return await _platform.get(key);
  }

  /// Clear all data from local storage
  /// This will delete all data stored in the local storage
  Future<void> clear() async {
    await _platform.clear();
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
}
