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

Store, retrieve, and protect your data effortlessly with AES or Fernet encryption. Whether you need blazing-fast key-value storage or encrption Boxx has you covered. 

## Features
Boxx is a lightweight storage solution with optional encryption built in. Its simple, powerful, & intuitive API get's you up and running in no time.

✅ Simple – Easy-to-use key-value interface

✅ Secure – Choose between AES-256 or Fernet encryption

✅ Versatile – Perfect for configs, secrets, or sensitive data


## Getting started


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

  initBox();
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
