import 'package:flutter/foundation.dart';

import '../boxx.dart';
import 'boxx_interface.dart';
import 'boxx_android.dart' as boxx_android;
import 'boxx_web.dart' as boxx_web;

/// Factory class to create BoxxInterface instances based on the platform and encryption mode
/// This class ensures that the correct implementation is used for the current platform (web or mobile)
/// and allows for easy extension in the future if more platforms are supported.
/// It follows the singleton pattern to ensure that only one instance of BoxxFactory is created throughout the application.
/// This is useful for managing resources and ensuring consistent behavior across the application.
class BoxxFactory {
  BoxxFactory._internal();
  static final BoxxFactory _instance = BoxxFactory._internal();
  static BoxxFactory get instance => _instance;

  /// Load appropriate Boxx interface for platform
  BoxxInterface getBoxxInterface({
    required EncryptionMode? mode,
    String? encryptionKey,
  }) {
    if (kIsWeb) {
      return boxx_web.BoxxHelper(mode: mode, encryptionKey: encryptionKey);
    } else {
      return boxx_android.BoxxHelper(mode: mode, encryptionKey: encryptionKey);
    }
  }
}
