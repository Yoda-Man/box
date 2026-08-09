import 'dart:convert';

import 'encryption.dart';
import 'encryption_mode.dart';
import 'exceptions.dart';

class DecodedRecord {
  const DecodedRecord({
    required this.key,
    required this.value,
    required this.isLegacy,
  });

  final String key;
  final dynamic value;
  final bool isLegacy;
}

/// Encodes versioned records and reads the ambiguous pre-v2 format for migration.
class StoredRecordCodec {
  StoredRecordCodec({
    required this.mode,
    required this.encryptionKey,
    required this.legacyMode,
    required this.legacyEncryptionKey,
  });

  static const int currentVersion = 2;

  final EncryptionMode mode;
  final String? encryptionKey;
  final EncryptionMode legacyMode;
  final String? legacyEncryptionKey;
  final EncryptAES _aes = EncryptAES();
  final EncryptFernet _fernet = EncryptFernet();

  String encode(String key, dynamic value) {
    final payload = jsonEncode(value);
    final inner = jsonEncode(<String, dynamic>{'key': key, 'payload': payload});
    final data = switch (mode) {
      EncryptionMode.aes => _aes.encryptAES(inner, encryptionKey!),
      EncryptionMode.fernet => _fernet.encryptFernet(inner, encryptionKey!),
      EncryptionMode.none => inner,
    };
    return jsonEncode(<String, dynamic>{
      'version': currentVersion,
      'mode': mode.name,
      'data': data,
    });
  }

  DecodedRecord decode(
    String raw, {
    String? expectedKey,
    required bool allowLegacy,
    String? legacyFallbackKey,
  }) {
    dynamic outer;
    try {
      outer = jsonDecode(raw);
    } catch (error) {
      if (!allowLegacy) {
        throw BoxxCorruptDataException(
          'Invalid versioned record',
          cause: error,
        );
      }
    }
    if (outer is Map<String, dynamic> && outer['version'] == currentVersion) {
      return _decodeCurrent(outer, expectedKey);
    }

    if (!allowLegacy || legacyFallbackKey == null) {
      throw const BoxxCorruptDataException(
        'Unsupported storage record version',
      );
    }
    return _decodeLegacy(raw, legacyFallbackKey);
  }

  DecodedRecord _decodeCurrent(
    Map<String, dynamic> outer,
    String? expectedKey,
  ) {
    try {
      if (outer['mode'] != mode.name || outer['data'] is! String) {
        throw BoxxCorruptDataException(
          'Record encryption mode does not match this Boxx instance',
        );
      }
      final data = outer['data'] as String;
      final innerText = switch (mode) {
        EncryptionMode.aes => _aes.decryptAES(data, encryptionKey!),
        EncryptionMode.fernet => _fernet.decryptFernet(data, encryptionKey!),
        EncryptionMode.none => data,
      };
      final inner = jsonDecode(innerText);
      if (inner is! Map<String, dynamic> ||
          inner['key'] is! String ||
          inner['payload'] is! String) {
        throw const FormatException('Invalid record payload');
      }
      final key = inner['key'] as String;
      if (expectedKey != null && key != expectedKey) {
        throw const BoxxCorruptDataException(
          'Stored key does not match lookup key',
        );
      }
      return DecodedRecord(
        key: key,
        value: jsonDecode(inner['payload'] as String),
        isLegacy: false,
      );
    } on BoxxException {
      rethrow;
    } catch (error) {
      throw BoxxCorruptDataException(
        'Unable to decode stored record',
        cause: error,
      );
    }
  }

  DecodedRecord _decodeLegacy(String raw, String key) {
    var payload = raw;
    if (legacyMode == EncryptionMode.aes) {
      payload = _aes.decryptAES(raw, legacyEncryptionKey!);
    } else if (legacyMode == EncryptionMode.fernet) {
      payload = _fernet.decryptFernet(raw, legacyEncryptionKey!);
    }
    dynamic value;
    try {
      value = jsonDecode(payload);
    } catch (_) {
      value = payload;
    }
    return DecodedRecord(key: key, value: value, isLegacy: true);
  }
}
