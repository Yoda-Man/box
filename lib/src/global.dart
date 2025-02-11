import 'dart:convert';
import 'dart:math';

import 'encryption.dart';

EncryptAES aes = EncryptAES();
EncryptFernet fernet = EncryptFernet();

List<int> padKeyWithZeros(String key, int targetSize) {
  List<int> bytes = utf8.encode(key);
  return List.filled(targetSize, 0)
    ..setRange(0, min(targetSize, bytes.length), bytes);
}
