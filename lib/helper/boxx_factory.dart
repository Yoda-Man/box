import 'package:flutter/foundation.dart';

import '../boxx.dart';
import 'boxx_interface.dart';
import 'boxx_android.dart' as boxx_android;
import 'boxx_web.dart' as boxx_web;

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
