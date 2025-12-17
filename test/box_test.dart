import 'package:boxx/boxx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return '.';
      });

  group('Boxx Storage Tests', () {
    test('Fast Storage Tests', () async {
      final boxx = Boxx(mode: EncryptionMode.none);
      await boxx.initialize();

      await boxx.put('2', '2');
      expect(await boxx.get('2'), '2');

      await boxx.delete('2');
      expect(await boxx.get('2'), null);
    });

    test('AES Encryption Storage Tests', () async {
      final boxx = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: 'testpassword',
      );
      await boxx.initialize();

      await boxx.put('key', 'value');
      expect(await boxx.get('key'), 'value');

      await boxx.delete('key');
      expect(await boxx.get('key'), null);
    });

    test('Fernet Encryption Storage Tests', () async {
      final boxx = Boxx(
        mode: EncryptionMode.fernet,
        encryptionKey: 'ferretpass',
      );
      await boxx.initialize();

      await boxx.put('ferretKey', 'ferretValue');
      expect(await boxx.get('ferretKey'), 'ferretValue');

      await boxx.delete('ferretKey');
    });

    test('String Encryption/Decryption Tests - AES', () async {
      final boxx = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: 'stringkey123',
      );
      await boxx.initialize();

      final originalString = 'SensitiveData123!@#';
      await boxx.put('encKey', originalString);

      final retrieved = await boxx.get('encKey');
      expect(retrieved, originalString);
    });

    test('String Encryption/Decryption Tests - Fernet', () async {
      final boxx = Boxx(
        mode: EncryptionMode.fernet,
        encryptionKey: 'fernetstringkey',
      );
      await boxx.initialize();

      final originalString = 'AnotherSensitiveString456%^';
      await boxx.put('fernetEncKey', originalString);

      final retrieved = await boxx.get('fernetEncKey');
      expect(retrieved, originalString);
    });

    test('Unicode String Encryption Test - AES', () async {
      final boxx = Boxx(mode: EncryptionMode.aes, encryptionKey: 'unicodekey');
      await boxx.initialize();

      final unicodeString = 'こんにちは世界🌏';
      await boxx.put('unicodeKey', unicodeString);
      expect(await boxx.get('unicodeKey'), unicodeString);
    });
  });

  group('Boxx Core Encryption Tests', () {
    test('Boxx.encrypt and Boxx.decrypt - AES', () async {
      final boxx = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: 'aesEncryptKey',
      );
      await boxx.initialize();

      final plainText = 'EncryptThisText123!';
      final encrypted = boxx.encrypt(plainText);
      expect(encrypted, isNot(plainText));
      expect(
        encrypted.contains(':'),
        isTrue,
        reason: 'AES should contain IV separator',
      );

      final decrypted = boxx.decrypt(encrypted);
      expect(decrypted, plainText);
    });

    test('AES Random IV Check', () async {
      final boxx = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: 'aesEncryptKey',
      );
      await boxx.initialize();

      final plainText = 'SameText';
      final encrypted1 = boxx.encrypt(plainText);
      final encrypted2 = boxx.encrypt(plainText);

      expect(encrypted1, isNot(plainText));
      expect(
        encrypted1,
        isNot(encrypted2),
        reason: 'AES encryption should be non-deterministic (random IV)',
      );

      // Both should decrypt to same text
      expect(boxx.decrypt(encrypted1), plainText);
      expect(boxx.decrypt(encrypted2), plainText);
    });

    test('Boxx.encrypt and Boxx.decrypt - Fernet', () async {
      final boxx = Boxx(
        mode: EncryptionMode.fernet,
        encryptionKey: 'fernetEncryptKey',
      );
      await boxx.initialize();

      final plainText = 'FernetEncryptionTest456@#';
      final encrypted = boxx.encrypt(plainText);
      expect(encrypted, isNot(plainText));

      final decrypted = boxx.decrypt(encrypted);
      expect(decrypted, plainText);
    });

    test('Fernet Randomness Check', () async {
      // Fernet also includes randomness (IV/timestamp)
      final boxx = Boxx(
        mode: EncryptionMode.fernet,
        encryptionKey: 'fernetEncryptKey',
      );
      await boxx.initialize();

      final plainText = 'SameText';
      final encrypted1 = boxx.encrypt(plainText);
      final encrypted2 = boxx.encrypt(plainText);

      expect(
        encrypted1,
        isNot(encrypted2),
        reason: 'Fernet encryption should be non-deterministic',
      );
      expect(boxx.decrypt(encrypted1), plainText);
      expect(boxx.decrypt(encrypted2), plainText);
    });

    test('Boxx.encrypt and Boxx.decrypt - Unicode String', () async {
      final boxx = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: 'unicodeEncryptKey',
      );
      await boxx.initialize();

      final unicodeText = 'テスト🌟🚀';
      final encrypted = boxx.encrypt(unicodeText);
      final decrypted = boxx.decrypt(encrypted);
      expect(decrypted, unicodeText);
    });
  });
}
