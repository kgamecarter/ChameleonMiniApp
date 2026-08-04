import 'package:flutter_test/flutter_test.dart';

import 'package:chameleon_mini_app/domain/models/slot.dart';

void main() {
  test('clearing a slot resets its device state but preserves its index', () {
    final slot = Slot(3)
      ..uid = 'A1B2C3D4'
      ..memorySize = 1024
      ..mode = 'MF_CLASSIC_1K'
      ..button = 'NEXT'
      ..longPressButton = 'PREV';

    slot.clear();

    expect(slot.index, 3);
    expect(slot.uid, isNull);
    expect(slot.memorySize, isNull);
    expect(slot.mode, isNull);
    expect(slot.button, isNull);
    expect(slot.longPressButton, isNull);
  });
}
