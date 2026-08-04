import 'slot.dart';

/// Domain data read from a connected Chameleon device.
class ChameleonDevice {
  const ChameleonDevice({
    required this.version,
    required this.commands,
    required this.modes,
    required this.buttonModes,
    required this.longPressButtonModes,
    required this.slots,
  });

  final String version;
  final List<String> commands;
  final List<String> modes;
  final List<String> buttonModes;
  final List<String>? longPressButtonModes;
  final List<Slot> slots;
}
