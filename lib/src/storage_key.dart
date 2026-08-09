import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Stable, fixed-length identifier safe for filesystems and IndexedDB keys.
String storageIdentifier(String value) =>
    sha256.convert(utf8.encode(value)).toString();
