import 'dart:async';

import 'package:boxx/boxx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var sequence = 0;
  String nextName(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${sequence++}';

  test('web IndexedDB supports CRUD and exact types', () async {
    final box = Boxx(mode: EncryptionMode.none, name: nextName('web-crud'));
    await box.put('string', '42');
    await box.put('map', <String, dynamic>{'value': true});
    expect(await box.get<String>('string'), '42');
    expect(await box.get<Map<String, dynamic>>('map'), {'value': true});
    expect(await box.exists('string'), isTrue);
    expect(await box.keys, ['map', 'string']);
    expect(await box.all(), {
      'map': {'value': true},
      'string': '42',
    });
    await box.delete('string');
    expect(await box.exists('string'), isFalse);
    await box.clear();
    expect(await box.keys, isEmpty);
    box.dispose();
  }, skip: !kIsWeb);

  test('web AES-GCM persists after reopening', () async {
    const key = 'web encryption key with enough bytes';
    final name = nextName('web-aes');
    final writer = Boxx(
      mode: EncryptionMode.aes,
      encryptionKey: key,
      name: name,
    );
    await writer.put('secret', 'value');
    writer.dispose();

    final reader = Boxx(
      mode: EncryptionMode.aes,
      encryptionKey: key,
      name: name,
    );
    expect(await reader.get<String>('secret'), 'value');
    await reader.clear();
    reader.dispose();
  }, skip: !kIsWeb);

  test(
    'web namespaces and formerly colliding keys remain independent',
    () async {
      final first = Boxx(
        mode: EncryptionMode.none,
        name: nextName('web-first'),
      );
      final second = Boxx(
        mode: EncryptionMode.none,
        name: nextName('web-second'),
      );
      await first.put('a/b', 'slash');
      await first.put('ab', 'plain');
      await second.put('a/b', 'other');
      expect(await first.get<String>('a/b'), 'slash');
      expect(await first.get<String>('ab'), 'plain');
      expect(await second.get<String>('a/b'), 'other');
      await first.clear();
      await second.clear();
      first.dispose();
      second.dispose();
    },
    skip: !kIsWeb,
  );

  test('web BroadcastChannel notifies another instance', () async {
    final name = nextName('web-watch');
    final reader = Boxx(mode: EncryptionMode.none, name: name);
    final writer = Boxx(mode: EncryptionMode.none, name: name);
    final values = <String?>[];
    final initialValue = Completer<void>();
    final subscription = reader.watch<String>('status').listen((value) {
      values.add(value);
      if (!initialValue.isCompleted) initialValue.complete();
    });
    await initialValue.future;
    await writer.put('status', 'ready');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(values, [null, 'ready']);
    await subscription.cancel();
    await writer.clear();
    reader.dispose();
    writer.dispose();
  }, skip: !kIsWeb);
}
