<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Boxx is a lightweight and blazing fast key-value database written in pure Dart. 

## Features
Boxx is a lightweight storage solution with optional encryption built in. Its simple, powerful, & intuitive API get's you up and running in no time.

## Getting started


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



## Additional information

Box supports 2 Encryption Algorithms 1) AES Algorithms 2) Fernet Algorithms
