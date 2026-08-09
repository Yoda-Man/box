import 'dart:convert';
import 'dart:io';

import 'package:boxx/boxx.dart';
import 'package:boxx/src/global.dart';
import 'package:boxx/src/storage_key.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  var sequence = 0;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('boxx-tests-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => root.path);
  });

  tearDownAll(() async {
    await root.delete(recursive: true);
  });

  String nextName(String prefix) => '$prefix-${sequence++}';

  group('native persistence', () {
    test('preserves exact JSON types after restart', () async {
      final name = nextName('types');
      final writer = Boxx(mode: EncryptionMode.none, name: name);
      await writer.put('string-number', '42');
      await writer.put('string-bool', 'true');
      await writer.put('integer', 42);
      await writer.put('double', 42.5);
      await writer.put('boolean', true);
      await writer.put('map', <String, dynamic>{'nested': 1});
      await writer.put('list', <dynamic>['x', 2]);
      await writer.put('null', null);
      writer.dispose();

      final reader = Boxx(mode: EncryptionMode.none, name: name);
      expect(await reader.get<String>('string-number'), '42');
      expect(await reader.get<String>('string-bool'), 'true');
      expect(await reader.get<int>('integer'), 42);
      expect(await reader.get<double>('double'), 42.5);
      expect(await reader.get<bool>('boolean'), isTrue);
      expect(await reader.get<Map<String, dynamic>>('map'), {'nested': 1});
      expect(await reader.get<List<dynamic>>('list'), ['x', 2]);
      expect(await reader.get<dynamic>('null'), isNull);
      reader.dispose();
    });

    test('stores formerly colliding and Unicode keys independently', () async {
      final box = Boxx(mode: EncryptionMode.none, name: nextName('keys'));
      await box.put('a/b', 'slash');
      await box.put('ab', 'plain');
      await box.put('a?b', 'question');
      await box.put('🔐/用户', 'unicode');

      expect(await box.get<String>('a/b'), 'slash');
      expect(await box.get<String>('ab'), 'plain');
      expect(await box.get<String>('a?b'), 'question');
      expect(await box.get<String>('🔐/用户'), 'unicode');
      expect(await box.keys, ['a/b', 'a?b', 'ab', '🔐/用户']);
      box.dispose();
    });

    test('isolates namespaces and scoped clear', () async {
      final first = Boxx(mode: EncryptionMode.none, name: nextName('first'));
      final second = Boxx(mode: EncryptionMode.none, name: nextName('second'));
      await first.put('same', 'first');
      await second.put('same', 'second');
      await first.clear();

      expect(await first.get<String>('same'), isNull);
      expect(await second.get<String>('same'), 'second');
      first.dispose();
      second.dispose();
    });

    test('returns fresh values instead of mutable cached references', () async {
      final box = Boxx(mode: EncryptionMode.none, name: nextName('fresh'));
      await box.put('map', <String, dynamic>{'value': 1});
      final first = await box.get<Map<String, dynamic>>('map');
      first!['value'] = 99;
      expect(await box.get<Map<String, dynamic>>('map'), {'value': 1});
      box.dispose();
    });

    test(
      'concurrent writes leave one complete record and no temp files',
      () async {
        final name = nextName('concurrent');
        final box = Boxx(mode: EncryptionMode.none, name: name);
        await Future.wait(List.generate(20, (value) => box.put('key', value)));
        box.dispose();

        final reader = Boxx(mode: EncryptionMode.none, name: name);
        expect(await reader.get<int>('key'), inInclusiveRange(0, 19));
        final directory = Directory(
          p.join(root.path, 'boxx', storageIdentifier(name)),
        );
        expect(
          await directory
              .list()
              .where((file) => file.path.contains('.tmp-'))
              .isEmpty,
          isTrue,
        );
        reader.dispose();
      },
    );
  });

  group('encryption', () {
    const firstKey = 'correct horse battery staple 001';
    const secondKey = 'correct horse battery staple 002';

    test('rejects missing and weak encryption keys', () {
      expect(
        () => Boxx(mode: EncryptionMode.aes),
        throwsA(isA<BoxxConfigurationException>()),
      );
      expect(
        () => Boxx(mode: EncryptionMode.fernet, encryptionKey: 'short'),
        throwsA(isA<BoxxConfigurationException>()),
      );
    });

    test(
      'AES-GCM persists, detects tampering, and rejects a wrong key',
      () async {
        final name = nextName('aes');
        final writer = Boxx(
          mode: EncryptionMode.aes,
          encryptionKey: firstKey,
          name: name,
        );
        await writer.put('secret', <String, dynamic>{'token': 'value'});
        writer.dispose();

        final reader = Boxx(
          mode: EncryptionMode.aes,
          encryptionKey: firstKey,
          name: name,
        );
        expect(await reader.get<Map<String, dynamic>>('secret'), {
          'token': 'value',
        });
        reader.dispose();

        final wrongKey = Boxx(
          mode: EncryptionMode.aes,
          encryptionKey: secondKey,
          name: name,
        );
        await expectLater(
          wrongKey.get<dynamic>('secret'),
          throwsA(isA<BoxxEncryptionException>()),
        );
        wrongKey.dispose();

        final file = File(
          p.join(
            root.path,
            'boxx',
            storageIdentifier(name),
            '${storageIdentifier('secret')}.boxx',
          ),
        );
        final outer =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final token = outer['data'] as String;
        outer['data'] =
            '${token.substring(0, token.length - 1)}'
            '${token.endsWith('A') ? 'B' : 'A'}';
        await file.writeAsString(jsonEncode(outer), flush: true);

        final tampered = Boxx(
          mode: EncryptionMode.aes,
          encryptionKey: firstKey,
          name: name,
        );
        await expectLater(
          tampered.get<dynamic>('secret'),
          throwsA(isA<BoxxEncryptionException>()),
        );
        tampered.dispose();
      },
    );

    test('Fernet persists across instances', () async {
      final name = nextName('fernet');
      final writer = Boxx(
        mode: EncryptionMode.fernet,
        encryptionKey: firstKey,
        name: name,
      );
      await writer.put('secret', 'value');
      writer.dispose();

      final reader = Boxx(
        mode: EncryptionMode.fernet,
        encryptionKey: firstKey,
        name: name,
      );
      expect(await reader.get<String>('secret'), 'value');
      reader.dispose();
    });

    test('does not truncate keys after 32 bytes', () {
      final first = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: '${'x' * 32}first',
      );
      final second = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: '${'x' * 32}second',
      );
      final ciphertext = first.encrypt('secret');
      expect(
        () => second.decrypt(ciphertext),
        throwsA(isA<BoxxEncryptionException>()),
      );
      first.dispose();
      second.dispose();
    });

    test('migrates legacy AES records on read', () async {
      const key = 'legacy-aes-key-with-enough-bytes';
      const storageKey = 'legacy';
      final iv = encrypt.IV.fromSecureRandom(16);
      final legacyKey = encrypt.Key.fromUtf8(
        String.fromCharCodes(padKeyWithZeros(key, 32)),
      );
      final encrypter = encrypt.Encrypter(
        encrypt.AES(legacyKey, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt('legacy-value', iv: iv);
      final legacyFile = File(p.join(root.path, '$storageKey.boxx'));
      await legacyFile.writeAsString('${iv.base64}:${encrypted.base64}');

      final box = Boxx(
        mode: EncryptionMode.aes,
        encryptionKey: key,
        legacyMode: EncryptionMode.aes,
        legacyEncryptionKey: key,
      );
      expect(await box.get<String>(storageKey), 'legacy-value');
      expect(await legacyFile.exists(), isFalse);
      expect(await box.get<String>(storageKey), 'legacy-value');
      await box.clear();
      box.dispose();
    });
  });

  group('reactivity and diagnostics', () {
    test('notifies another instance without stale cache', () async {
      final name = nextName('watch');
      final reader = Boxx(mode: EncryptionMode.none, name: name);
      final writer = Boxx(mode: EncryptionMode.none, name: name);
      final values = reader.watch<String>('status').take(2).toList();
      await Future<void>.delayed(Duration.zero);
      await writer.put('status', 'ready');
      expect(await values, [null, 'ready']);
      reader.dispose();
      writer.dispose();
    });

    test('reports structured diagnostics for corrupt records', () async {
      final events = <BoxxDiagnosticEvent>[];
      final name = nextName('diagnostics');
      final box = Boxx(
        mode: EncryptionMode.none,
        name: name,
        diagnostics: events.add,
      );
      await box.initialize();
      final file = File(
        p.join(
          root.path,
          'boxx',
          storageIdentifier(name),
          '${storageIdentifier('bad')}.boxx',
        ),
      );
      await file.writeAsString('{not-valid');

      await expectLater(
        box.get<dynamic>('bad'),
        throwsA(isA<BoxxCorruptDataException>()),
      );
      expect(events.single.operation, 'get');
      expect(events.single.error, isA<BoxxCorruptDataException>());
      box.dispose();
    });

    test('rejects operations after disposal', () {
      final box = Boxx(mode: EncryptionMode.none, name: nextName('disposed'));
      box.dispose();
      expect(
        () => box.get<dynamic>('key'),
        throwsA(isA<BoxxDisposedException>()),
      );
    });
  });

  group('public API edge cases', () {
    test(
      'covers exploration, deletion, validation, and type mismatch',
      () async {
        expect(
          () => Boxx(
            mode: EncryptionMode.none,
            encryptionKey: 'unexpected key material is not allowed',
          ),
          throwsA(isA<BoxxConfigurationException>()),
        );
        final box = Boxx(mode: EncryptionMode.none, name: nextName('api'));
        await box.put('a', 1);
        await box.put('b', 2);
        expect(await box.exists('a'), isTrue);
        expect(await box.values, containsAll(<dynamic>[1, 2]));
        expect(await box.all(), {'a': 1, 'b': 2});
        await expectLater(
          box.get<String>('a'),
          throwsA(isA<BoxxTypeMismatchException>()),
        );
        await box.delete('a');
        await box.delete('missing');
        expect(await box.exists('a'), isFalse);
        await expectLater(
          box.put('', 'value'),
          throwsA(isA<BoxxConfigurationException>()),
        );
        expect(
          () => box.encrypt('value'),
          throwsA(isA<BoxxConfigurationException>()),
        );
        expect(
          () => box.decrypt('value'),
          throwsA(isA<BoxxConfigurationException>()),
        );
        box.dispose();
      },
    );

    test('lists and clears default-namespace legacy files', () async {
      final legacy = File(p.join(root.path, 'orphan.boxx'));
      await legacy.writeAsString('legacy-value');
      final box = Boxx(mode: EncryptionMode.none);
      expect(await box.keys, isNot(contains('orphan')));
      expect(await box.exists('orphan'), isTrue);
      await box.clear();
      expect(await legacy.exists(), isTrue);
      expect(await box.get<String>('orphan'), 'legacy-value');
      expect(await legacy.exists(), isFalse);
      await box.clear();
      box.dispose();
    });

    test(
      'migrates legacy Fernet and contains diagnostic callback failures',
      () async {
        const key = 'legacy-fernet-key-with-enough-bytes';
        const storageKey = 'legacy-fernet';
        final legacyKey = encrypt.Key.fromBase64(fernetKeyGenerator(key));
        final legacyEncrypter = encrypt.Encrypter(encrypt.Fernet(legacyKey));
        final legacyFile = File(p.join(root.path, '$storageKey.boxx'));
        await legacyFile.writeAsString(
          legacyEncrypter.encrypt('legacy-value').base64,
        );
        final box = Boxx(
          mode: EncryptionMode.fernet,
          encryptionKey: key,
          diagnostics: (_) => throw StateError('diagnostics unavailable'),
        );
        expect(await box.get<String>(storageKey), 'legacy-value');
        expect(await legacyFile.exists(), isFalse);

        await box.put('number', 1);
        await expectLater(
          box.watch<String>('number').first,
          throwsA(isA<BoxxTypeMismatchException>()),
        );
        await box.clear();
        box.dispose();
      },
    );
  });
}
