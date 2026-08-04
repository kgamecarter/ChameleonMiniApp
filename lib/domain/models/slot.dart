/// A snapshot of one emulation slot on the connected Chameleon device.
class Slot {
  Slot(this.index);

  final int index;
  String? uid;
  int? memorySize;
  String? mode;
  String? button;
  String? longPressButton;

  void clear() {
    uid = null;
    memorySize = null;
    mode = null;
    button = null;
    longPressButton = null;
  }
}
