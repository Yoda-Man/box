# Boxx example

```dart
import 'package:boxx/boxx.dart';

late final Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  box = Boxx(
    name: 'example',
    mode: EncryptionMode.none,
  );
  await box.initialize();

  await box.put('user', {'name': 'Alice'});
  final user = await box.get<Map<String, dynamic>>('user');
  debugPrint('$user');
}
```

For encrypted storage, load at least 32 bytes of random key material from
platform-backed secure storage and select `EncryptionMode.aes` or
`EncryptionMode.fernet`. Never commit an application encryption key.
