<div align="center">

# 🗃️ Boxx

<img src="https://www.soundcentral.africa/assets/assets/boxx.jpg" alt="Boxx Logo" width="300">

### Secure • Simple • Fast Flutter Storage

**Store, retrieve, and protect your data effortlessly with AES or Fernet encryption**

[![Pub Version](https://img.shields.io/pub/v/boxx?color=blue&label=pub.dev&logo=dart)](https://pub.dev/packages/boxx)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)](https://flutter.dev)

</div>

## ✨ Features

Boxx is a lightweight storage solution with optional encryption built in. Its simple, powerful, & intuitive API gets you up and running in no time.

✅ **Simple** – Easy-to-use key-value interface  
✅ **Secure** – Choose between AES-256 or Fernet encryption  
✅ **Fast** – Optimized for performance with minimal overhead  
✅ **Versatile** – Perfect for configs, secrets, or sensitive data  

## 🚀 Getting Started

### Installation

Add Boxx to your `pubspec.yaml`:

```yaml
dependencies:
  boxx: ^0.1.7


## Import
```dart
import 'package:boxx/boxx.dart';

```
## Getting started
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
  box = Boxx(
    mode: EncryptionMode.aes,
    encryptionKey: 'your-32-character-encryption-key',
  );
  await box.initialize();
}

```

## Usage

Delete Data
```dart
await box.delete('UserData');
```

Retrieve Data
```dart
final contents = await box.get('UserData');
```

Store Data
```dart
await box.put('UserData', response.body);
```

Encryption Utilities
```dart
// Encrypt any string
String encrypted = box.encrypt('Hello World');
debugPrint(encrypted);

// Decrypt back to original
String decrypted = box.decrypt(encrypted);
debugPrint(decrypted); // Output: Hello World
```

🔧 API Reference
### Core Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `put(String key, dynamic value)` | Stores data with the given key | `Future<void>` |
| `get(String key)` | Retrieves data for the given key | `Future<dynamic>` |
| `delete(String key)` | Removes data for the given key | `Future<void>` |
| `encrypt(String plaintext)` | Encrypts a string | `String` |
| `decrypt(String ciphertext)` | Decrypts an encrypted string | `String` |

### Encryption Modes

| Mode | Security Level | Key Length | Use Case |
|------|----------------|------------|----------|
| `EncryptionMode.none` | No encryption | - | Non-sensitive data |
| `EncryptionMode.aes` | AES-256 | 32 chars | Highly sensitive data |
| `EncryptionMode.fernet` | Fernet | 32 chars | General purpose encryption |


Alternatively, for a more concise version:

## 💡 Best Practices

| Practice | Description | Example |
|----------|-------------|---------|
| **🔑 Secure Keys** | Never hardcode encryption keys | Use environment variables |
| **🚀 Proper Init** | Always initialize after binding | `WidgetsFlutterBinding.ensureInitialized()` |
| **🛡️ Error Handling** | Wrap operations in try-catch | `try { await box.get(); } catch(e) {}` |
| **📊 Data Types** | Store JSON-serializable data | Strings, Maps, Lists, numbers |
| **🔒 Mode Selection** | Choose encryption based on sensitivity | Use AES for sensitive data |

🤝 Contributing
We welcome contributions! Please feel free to submit issues and pull requests.

📄 License
This project is licensed under the MIT License.

<div align="center">
Made with ❤️ for the Flutter community

</div>