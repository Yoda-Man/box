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

  group('Boxx Core Features (v0.2.0)', () {
    late Boxx box;

    setUp(() async {
      box = Boxx(mode: EncryptionMode.none);
      await box.initialize();
      await box.clear();
    });

    tearDown(() {
      box.dispose();
    });

    test('Generics Support - get<T>', () async {
      await box.put('count', 42);
      await box.put('is_valid', true);
      await box.put('name', 'Boxx');

      expect(await box.get<int>('count'), 42);
      expect(await box.get<bool>('is_valid'), true);
      expect(await box.get<String>('name'), 'Boxx');
    });

    test('JSON Serialization - Maps and Lists', () async {
      final user = {'name': 'Alice', 'age': 30};
      final tags = ['flutter', 'dart', 'storage'];

      await box.put('user', user);
      await box.put('tags', tags);

      final retrievedUser = await box.get<Map<String, dynamic>>('user');
      final retrievedTags = await box.get<List<dynamic>>('tags');

      expect(retrievedUser?['name'], 'Alice');
      expect(retrievedTags?.length, 3);
      expect(retrievedTags?[1], 'dart');
    });

    test('Reactivity - watch<T>', () async {
      final stream = box.watch<String>('status');

      // Note: First event is the initial get (null)
      expectLater(
        stream,
        emitsInOrder([
          null, // initial
          'loading',
          'ready',
        ]),
      );

      // Trigger changes
      await Future.delayed(Duration(milliseconds: 100));
      await box.put('status', 'loading');
      await Future.delayed(Duration(milliseconds: 100));
      await box.put('status', 'ready');
    });

    test('Exploration - keys, values, all()', () async {
      await box.put('a', 1);
      await box.put('b', 2);

      expect(await box.keys, containsAll(['a', 'b']));
      expect(await box.values, containsAll([1, 2]));

      final allData = await box.all();
      expect(allData['a'], 1);
      expect(allData['b'], 2);
    });

    test('Memory Caching - Fast Access', () async {
      await box.put('fast', 'data');

      // First read goes to disk (mocked here, but populates cache)
      expect(await box.get<String>('fast'), 'data');

      // Subsequent reads should be from cache (logic check)
      // We can't easily "prove" it's cache without a spy, but
      // we can verify it doesn't break.
      expect(await box.get<String>('fast'), 'data');
    });
  });

  group('Boxx Encryption Tests', () {
    test('AES Encryption with Generics', () async {
      final box = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: 'aesEncryptKey12345678901234567890',
      );
      await box.initialize();

      final data = {'secret': 'password123'};
      await box.put('vault', data);

      final decrypted = await box.get<Map<String, dynamic>>('vault');
      expect(decrypted?['secret'], 'password123');

      box.dispose();
    });

    test('Fernet Encryption with Generics', () async {
      final box = Boxx(
        mode: EncryptionMode.fernet,
        encryptionKey: 'fernetEncryptKey1234567890123456',
      );
      await box.initialize();

      await box.put('secret_val', 'topsecret');
      expect(await box.get<String>('secret_val'), 'topsecret');

      box.dispose();
    });
  });
}
