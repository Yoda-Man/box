import 'package:boxx/boxx.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fast Storage Tests', () {
    final box = Boxx(mode: EncryptionMode.none);
    expect(box.boxx.put('2', '2'), '');
    expect(box.boxx.get('2'), 2);
    expect(box.boxx.delete('2'), '');
  });
}
