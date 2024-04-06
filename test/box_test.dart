import 'package:boxx/boxx.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fast Storage Tests', () {
    final box = Box(path: '');
    expect(box.put('2', '2'), '');
    expect(box.get('2'), 2);
    expect(box.delete('2'), '');
  });
}
