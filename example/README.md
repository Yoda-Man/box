# Example of usage `boxx`

Without Encryption
```dart
late Box box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initBox();
}



initBox() async {
  if (kIsWeb) {
    box = Box(path: '');
  } else {
    final directory = await getApplicationDocumentsDirectory();
    box = Box(path: directory.path);
  }
}

```

With Encryption

```dart
late Box box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initBox();
}



initBox() async {
  if (kIsWeb) {
    box = Box(path: '',encryptionKey: 'xxxxxxxx',mode: EncryptionMode.aes);
  } else {
    final directory = await getApplicationDocumentsDirectory();
    box = Box(path: directory.path,encryptionKey: 'xxxxxxxx',mode: EncryptionMode.aes);
  }
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
