# Example of usage `boxx`

Without Encryption
```dart
late Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initBox();
}



initBox() async {
  if (kIsWeb) {
    box = Boxx(path: '');
  } else {
    final directory = await getApplicationDocumentsDirectory();
    box = Boxx(path: directory.path);
  }
}

```

With Encryption

```dart
late Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initBox();
}



initBox() async {
  if (kIsWeb) {
    box = Boxx(path: '',encryptionKey: 'xxxxxxxx',mode: EncryptionMode.aes);
  } else {
    final directory = await getApplicationDocumentsDirectory();
    box = Boxx(path: directory.path,encryptionKey: 'xxxxxxxx',mode: EncryptionMode.aes);
  }
}

```

## Usage

Delete

```dart
    box.boxx.delete('UserData');
```

Get
```dart
 final contents = await box.boxx.get('UserData');
```

Put
```dart
box.boxx.put('UserData', response.body);
```
