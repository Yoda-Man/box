<div align="center">

# 🗃️ Boxx

<img src="https://www.soundcentral.africa/assets/assets/boxx.jpg" alt="Boxx Logo" width="300">

### Secure • Reactive • Type-Safe Storage for Flutter

**The developer-friendly storage solution with AES/Fernet encryption, generics, and real-time streams.**

[![Pub Version](https://img.shields.io/pub/v/boxx?color=blue&label=pub.dev&logo=dart)](https://pub.dev/packages/boxx)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)](https://flutter.dev)

</div>

## ✨ Key Features

Boxx is built to be the most developer-friendly storage plugin for Flutter. It combines simplicity with powerful modern features.

✅ **🛡️ Type-Safe** – Full support for Generics (`get<T>`).  
✅ **📡 Reactive** – Watch any key for changes with standard Streams.  
✅ **📦 JSON Ready** – Automatically handle Maps and Lists.  
✅ **⚡ Blazing Fast** – Built-in memory cache for instant reads.  
✅ **🔐 Secure** – Military-grade AES-256 or Fernet encryption.  
✅ **🌐 Universal** – Consistent API across Mobile, Desktop, and Web.

## 🚀 Getting Started

### Installation

Add Boxx to your `pubspec.yaml`:

```yaml
dependencies:
  boxx: ^0.2.0
```

### Quick Start

```dart
import 'package:boxx/boxx.dart';

late Boxx box;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with AES encryption
  box = Boxx(
    mode: EncryptionMode.aes,
    encryptionKey: 'your-32-character-encryption-key',
  );
  
  await box.initialize();
}
```

## 🛠 Usage

### Basic Operations
```dart
// Store any JSON-serializable data
await box.put('user_profile', {
  'name': 'John Doe',
  'premium': true,
  'joined': 2024,
});

// Retrieve with type safety
final profile = await box.get<Map<String, dynamic>>('user_profile');
print(profile?['name']); // Output: John Doe

// Delete data
await box.delete('user_profile');
```

### 📡 Reactivity
Listen to changes in real-time. Perfect for UI updates or state management.

```dart
box.watch<bool>('is_logged_in').listen((status) {
  print('User login status changed to: $status');
});
```

### 🔍 Storage Exploration
```dart
List<String> keys = await box.keys;
List<dynamic> values = await box.values;
Map<String, dynamic> allData = await box.all();
```

### 🔐 Manual Encryption
Useful for encrypting strings before sending over the network or storing elsewhere.

```dart
String secret = box.encrypt('Hello World');
String original = box.decrypt(secret);
```

## 🔧 API Reference

| Method | Description | Returns |
|--------|-------------|---------|
| `initialize()` | Prepares the storage for use | `Future<void>` |
| `put(key, value)` | Stores data (auto-JSON & encryption) | `Future<void>` |
| `get<T>(key)` | Retrieves and casts data | `Future<T?>` |
| `delete(key)` | Removes data for the key | `Future<void>` |
| `watch<T>(key)` | Stream of data changes | `Stream<T?>` |
| `clear()` | Wipes all storage data | `Future<void>` |
| `keys` | List of all stored keys | `Future<List<String>>` |
| `all()` | Map of all stored data | `Future<Map<String, dynamic>>` |

## 💡 Best Practices

- **🔑 Storage of Secrets**: Always use `EncryptionMode.aes` for sensitive info.
- **🚀 Initialization**: Call `await box.initialize()` before any storage calls.
- **🛡️ Type Casting**: Use generics `box.get<String>('key')` to avoid manual casting.
- **🔒 Key Management**: Securely store your encryption keys (e.g., using `flutter_secure_storage` or environment variables).

## 📄 License
This project is licensed under the MIT License.

<div align="center">
Made with ❤️ for the Flutter community
</div>