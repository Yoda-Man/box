# Example of usage `boxx`

Without Encryption
```dart
late Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initBox();
}



initBox() {
  box = Boxx(mode: EncryptionMode.none);
}

```

With Encryption

```dart
late Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initBox();
}



initBox() {
  box = Boxx(mode: EncryptionMode.aes,encryptionKey: 'xxxxxxxx');
}

```

## Usage

Delete

```dart
    box.delete('UserData');
```

Get
```dart
 final contents = await box.get('UserData');
```

Put
```dart
box.put('UserData', response.body);
```

encrption/decryption
```dart
  String t1 = box.encrypt('Hello World');
  debugPrint(t1);
  String t2 = box.decrypt(t1);
  debugPrint(t2);
```