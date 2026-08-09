## 0.3.0

* **SECURITY**: Encryption now fails closed and requires at least 32 UTF-8 bytes
  of key material.
* **SECURITY**: New AES records use authenticated AES-256-GCM with per-record
  PBKDF2 salts; Fernet keys are also derived per record.
* **FIX**: Corrected the IndexedDB schema so web writes use out-of-line keys.
* **FIX**: Added versioned JSON envelopes that preserve exact value types.
* **FIX**: Replaced sanitized filenames with fixed-length hashed identifiers.
* **FIX**: Removed the stale in-memory cache and coordinated change streams
  across instances and browser tabs.
* **FIX**: Native writes now use flushed temporary files and atomic replacement.
* **NEW**: Added named namespaces, structured diagnostics, stable exception
  categories, and automatic legacy-record migration on read.
* **BREAKING**: Flutter 3.32 or later is required. Encrypted instances require a
  32-byte key. See README migration guidance.

## 0.2.0

*   **NEW**: Added type-safe generics to `get<T>()` and `put<T>()`.
*   **NEW**: Added reactivity with `watch(key)` returning a `Stream`.
*   **NEW**: Added support for JSON serialization of Maps and Lists automatically.
*   **NEW**: Added `keys`, `values`, and `all()` methods to explore storage.
*   **IMPROVEMENT**: Enhanced memory caching for faster read operations.
*   **API**: Cleaned up internal architecture for better maintainability.

## 0.1.8

* **SECURITY**: Fixed critical Fernet decryption vulnerability.
* **SECURITY**: Implemented random IV for AES encryption (breaking change for previously encrypted data).
* **API**: Added `initialize()` method. Initialization is now explicit and async.
* **Code**: Fixed static state issues for thread safety.
* **Docs**: Updated documentation and examples.

## 0.1.7

Enhanced error diagnostics with comprehensive stack trace capture.

## 0.1.6

Breaking changes to make package easier and simpler to use. Added unit tests.

## 0.1.5

Change web implimentation

## 0.1.4

Change web implimentation

## 0.1.3

Code Clean Up

## 0.1.2

Change initialisation to make it quicker and easier to impliment and consistent accros all platforms.

## 0.1.1

Clean up for web

## 0.1.0

Upgraded dependencies

## 0.0.9

Improve web implimentation

## 0.0.8

Add error handling to web implimentation

## 0.0.7

Tweak to make it easier to implement

## 0.0.6

Breaking changes to enable web support. Upgraded dependencies.

## 0.0.5

Fix enryption. Upgraded dependencies.

## 0.0.4

Added function to convert all AES keys to 256 bits internally. Upgraded dependencies.

## 0.0.3

Added example, upgraded dependencies and added sanitize key function

## 0.0.2

Tweak to make it easier to implement

## 0.0.1

Initial Release
