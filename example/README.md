# Example of usage `boxx`

Without Encryption
```dart
late Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initBox();
}



Future<void> initBox() async {
  box = Boxx(mode: EncryptionMode.none);
  await box.initialize();
}

```

With Encryption

```dart
late Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initBox();
}



Future<void> initBox() async {
  box = Boxx(mode: EncryptionMode.aes,encryptionKey: 'xxxxxxxx');
  await box.initialize();
}

```

## Usage

Delete

```dart
    await box.delete('UserData');
```

Get
```dart
 final contents = await box.get('UserData');
```

Put
```dart
await box.put('UserData', response.body);
```

Encryption/Decryption
```dart
  String t1 = box.encrypt('Hello World');
  debugPrint(t1);
  String t2 = box.decrypt(t1);
  debugPrint(t2);
```