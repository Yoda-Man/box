import 'package:boxx/boxx.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Fast Storage Tests', () {
    final boxx = Boxx(mode: EncryptionMode.none);
    expect(boxx.put('2', '2'), '');
    expect(boxx.get('2'), '2');
    expect(boxx.delete('2'), '');
    expect(boxx.get('2'), null);
  });

  test('AES Encryption Storage Tests', () {
    final boxx = Boxx(mode: EncryptionMode.aes, encryptionKey: 'testpassword');
    expect(boxx.put('key', 'value'), '');
    expect(boxx.get('key'), 'value');
    expect(boxx.delete('key'), '');
    expect(boxx.get('key'), null);
  });

  test('Ferret Encryption Storage Tests', () {
    final boxx = Boxx(mode: EncryptionMode.fernet, encryptionKey: 'ferretpass');
    expect(boxx.put('ferretKey', 'ferretValue'), '');
    expect(boxx.get('ferretKey'), 'ferretValue');
    expect(boxx.delete('ferretKey'), '');
    expect(boxx.get('ferretKey'), null);
  });

  test('String Encryption/Decryption Tests - AES', () {
    final boxx = Boxx(mode: EncryptionMode.aes, encryptionKey: 'stringkey123');
    final originalString = 'SensitiveData123!@#';
    expect(boxx.put('encKey', originalString), '');
    final retrieved = boxx.get('encKey');
    expect(retrieved, originalString);
    expect(boxx.delete('encKey'), '');
    expect(boxx.get('encKey'), null);
  });

  test('String Encryption/Decryption Tests - Fernet', () {
    final boxx = Boxx(
      mode: EncryptionMode.fernet,
      encryptionKey: 'fernetstringkey',
    );
    final originalString = 'AnotherSensitiveString456%^';
    expect(boxx.put('fernetEncKey', originalString), '');
    final retrieved = boxx.get('fernetEncKey');
    expect(retrieved, originalString);
    expect(boxx.delete('fernetEncKey'), '');
    expect(boxx.get('fernetEncKey'), null);
  });

  test('Empty String Storage Test', () {
    final boxx = Boxx(mode: EncryptionMode.none);
    expect(boxx.put('empty', ''), '');
    expect(boxx.get('empty'), '');
    expect(boxx.delete('empty'), '');
    expect(boxx.get('empty'), null);
  });

  test('Unicode String Encryption Test - AES', () {
    final boxx = Boxx(mode: EncryptionMode.aes, encryptionKey: 'unicodekey');
    final unicodeString = 'こんにちは世界🌏';
    expect(boxx.put('unicodeKey', unicodeString), '');
    expect(boxx.get('unicodeKey'), unicodeString);
    expect(boxx.delete('unicodeKey'), '');
    expect(boxx.get('unicodeKey'), null);
  });
  test('Boxx.encrypt and Boxx.decrypt - AES', () {
    final boxx = Boxx(mode: EncryptionMode.aes, encryptionKey: 'aesEncryptKey');
    final plainText = 'EncryptThisText123!';
    final encrypted = boxx.encrypt(plainText);
    expect(encrypted, isNot(plainText));
    final decrypted = boxx.decrypt(encrypted);
    expect(decrypted, plainText);
  });

  test('Boxx.encrypt and Boxx.decrypt - Fernet', () {
    final boxx = Boxx(
      mode: EncryptionMode.fernet,
      encryptionKey: 'fernetEncryptKey',
    );
    final plainText = 'FernetEncryptionTest456@#';
    final encrypted = boxx.encrypt(plainText);
    expect(encrypted, isNot(plainText));
    final decrypted = boxx.decrypt(encrypted);
    expect(decrypted, plainText);
  });

  test('Boxx.encrypt and Boxx.decrypt - Unicode String', () {
    final boxx = Boxx(
      mode: EncryptionMode.aes,
      encryptionKey: 'unicodeEncryptKey',
    );
    final unicodeText = 'テスト🌟🚀';
    final encrypted = boxx.encrypt(unicodeText);
    expect(encrypted, isNot(unicodeText));
    final decrypted = boxx.decrypt(encrypted);
    expect(decrypted, unicodeText);
  });

  test('Boxx.encrypt and Boxx.decrypt - Empty String', () {
    final boxx = Boxx(
      mode: EncryptionMode.aes,
      encryptionKey: 'emptyEncryptKey',
    );
    final encrypted = boxx.encrypt('');
    expect(encrypted, isNotNull);
    final decrypted = boxx.decrypt(encrypted);
    expect(decrypted, '');
  });
}
