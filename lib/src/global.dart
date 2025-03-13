import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'encryption.dart';

EncryptAES aes = EncryptAES();
EncryptFernet fernet = EncryptFernet();

///AES encryption. AES keys must be exactly 128, 192, or 256 bits long, which corresponds to byte arrays of lengths
///16, 24, or 32, respectively.
List<int> padKeyWithZeros(String key, int targetSize) {
  List<int> bytes = utf8.encode(key);
  return List.filled(targetSize, 0)
    ..setRange(0, min(targetSize, bytes.length), bytes);
}

///Fernet key must be 32 bit url-safe base64-encoded bytes
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
