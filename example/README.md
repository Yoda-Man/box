# Example of usage `boxx`

Storage Without Encryption
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

Storage With Encryption

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

AES encrption
```dart
  String t1 = box.aes.encryptAES('Hello World', box.encryptionKey!);
  debugPrint(t1);
  String t2 = box.aes.decryptAES(t1, box.encryptionKey!);
  debugPrint(t2);
```

Fernet encryption
```dart
  String t3 = box.fernet.encryptFernet('Hello World', box.encryptionKey!);
  debugPrint(t3);
  String t4 = box.fernet.decryptFernet(t1, box.encryptionKey!);
  debugPrint(t4);
```