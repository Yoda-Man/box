# Boxx

Boxx is versioned key-value storage for Flutter on Android, iOS, Linux, macOS,
Windows, and web. It supports exact JSON value persistence, named namespaces,
change streams, and optional authenticated encryption.

## Requirements

- Dart 3.8.1 or later
- Flutter 3.32.0 or later
- JSON-encodable values

## Install

```yaml
dependencies:
  boxx: ^0.3.0
```

## Basic usage

```dart
import 'package:boxx/boxx.dart';

final box = Boxx(
  name: 'application-settings',
  mode: EncryptionMode.none,
);

await box.initialize();
await box.put('theme', 'dark');
final theme = await box.get<String>('theme');
await box.delete('theme');
box.dispose();
```

Operations initialize lazily, but explicit initialization is recommended so an
unavailable storage backend fails during application startup.

## Authenticated encryption

AES mode uses AES-256-GCM. Fernet mode uses authenticated Fernet tokens. Both
derive per-record keys with PBKDF2-HMAC-SHA256 and a random salt.

Supply at least 32 UTF-8 bytes of high-entropy random key material. Store the
key in platform-backed secure storage. Do not embed it in source code, build
arguments, or environment files shipped with the application.

```dart
final vault = Boxx(
  name: 'user-vault',
  mode: EncryptionMode.aes,
  encryptionKey: keyLoadedFromSecureStorage,
);

await vault.put('profile', {'name': 'Alice', 'roles': ['support']});
final profile = await vault.get<Map<String, dynamic>>('profile');
```

Encrypted modes fail at construction when the key is absent or shorter than 32
UTF-8 bytes. Boxx never silently falls back to plaintext.

## Namespaces

The `name` parameter isolates independent stores. Use a stable name and do not
reuse a namespace with different current encryption settings.

```dart
final preferences = Boxx(name: 'preferences', mode: EncryptionMode.none);
final cache = Boxx(name: 'cache', mode: EncryptionMode.none);
```

`clear()` affects only versioned records in the instance namespace. Legacy
pre-0.3.0 records are removed individually after they are read and migrated;
Boxx never bulk-deletes root-level files it cannot identify safely.

## Values and keys

Boxx accepts JSON values: strings, numbers, booleans, null, lists, and maps with
string keys. Types are preserved across application restarts. Storage keys may
contain path separators, punctuation, or Unicode and are limited to 4096 UTF-8
bytes.

```dart
await box.put('literal-number', '42');
await box.put('counter', 42);

final keys = await box.keys;
final values = await box.values;
final entries = await box.all();
```

Requesting the wrong generic type throws `BoxxTypeMismatchException`.

## Change streams

```dart
final subscription = box.watch<String>('status').listen((status) {
  // The current value is emitted first, followed by committed changes.
});
```

Changes are shared between Boxx instances in the same Dart isolate. On web they
are also propagated to same-origin tabs through `BroadcastChannel`. Native
changes performed outside the process are visible on the next read but cannot
produce an in-process stream event.

## Legacy migration

Version 0.3.0 reads known pre-v2 keys in the default namespace and rewrites each
record into the current format when it is read. Legacy records are not included
in `keys` until migrated because old filenames cannot safely preserve original
keys. Applications should read their known keys explicitly. When changing
encryption mode or key, provide the previous settings:

```dart
final box = Boxx(
  mode: EncryptionMode.aes,
  encryptionKey: newKey,
  legacyMode: EncryptionMode.fernet,
  legacyEncryptionKey: oldKey,
);
```

Legacy string values such as `"42"` were stored ambiguously by versions before
0.3.0 and may already decode as a number. That lost type information cannot be
recovered automatically; validate migrated application data before removing the
old application version.

## Diagnostics and errors

Boxx does not log keys or values. Connect the diagnostics callback to the host
application's logging or error-reporting system:

```dart
final box = Boxx(
  mode: EncryptionMode.none,
  diagnostics: (event) {
    logger.error(event.operation, event.error, event.stackTrace);
  },
);
```

Stable exception categories include `BoxxConfigurationException`,
`BoxxEncryptionException`, `BoxxCorruptDataException`, `BoxxStorageException`,
`BoxxTypeMismatchException`, and `BoxxDisposedException`.

See [SUPPORT.md](SUPPORT.md) for recovery and troubleshooting and
[RELEASE.md](RELEASE.md) for release and rollback procedures.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
