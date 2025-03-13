import 'package:flutter/foundation.dart';

import '../src/enum.dart';
import 'boxx_interface.dart';
import 'boxx_android.dart' as boxx_android;
import 'boxx_web.dart' as boxx_web;

/// Load appropriate Boxx interface for platform
BoxxInterface getBoxxInterface(
    {required String path, String? encryptionKey, EncryptionMode? mode}) {
  if (kIsWeb) {
    return boxx_web.BoxxHelper(
        path: path, encryptionKey: encryptionKey, mode: mode);
  } else {
    return boxx_android.BoxxHelper(
        path: path, encryptionKey: encryptionKey, mode: mode);
  }
}
