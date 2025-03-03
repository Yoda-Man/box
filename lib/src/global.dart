import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'encryption.dart';

EncryptAES aes = EncryptAES();
EncryptFernet fernet = EncryptFernet();

List<int> padKeyWithZeros(String key, int targetSize) {
  List<int> bytes = utf8.encode(key);
  return List.filled(targetSize, 0)
    ..setRange(0, min(targetSize, bytes.length), bytes);
}

//Fernet key must be 32 bit url-safe base64-encoded bytes
String fernetKeyGenerator(String text) {
  // Step 1: Convert the input text to bytes
  final textBytes = utf8.encode(text);

  // Step 2: Ensure the byte array is exactly 32 bytes long
  // If it's shorter, pad it with zeros; if it's longer, truncate it
  Uint8List fixedLengthBytes = Uint8List(32);
  for (int i = 0; i < fixedLengthBytes.length; i++) {
    fixedLengthBytes[i] = i < textBytes.length ? textBytes[i] : 0;
  }

  // Step 3: Encode the bytes to a URL-safe Base64 string
  final base64String = base64Url.encode(fixedLengthBytes);

  return base64String;
}
