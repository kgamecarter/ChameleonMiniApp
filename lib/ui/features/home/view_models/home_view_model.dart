import 'package:flutter/foundation.dart';

import '../../../../data/repositories/chameleon_repository.dart';
import '../../../../domain/models/chameleon_device.dart';
import '../../../../domain/models/slot.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required ChameleonRepository repository})
    : _repository = repository,
      _slots = List.generate(8, Slot.new);

  final ChameleonRepository _repository;
  List<Slot> _slots;
  String? _version;
  List<String>? _commands;
  List<String>? _modes;
  List<String>? _buttonModes;
  List<String>? _longPressButtonModes;

  bool get connected => _repository.connected;
  List<Slot> get slots => List.unmodifiable(_slots);
  String? get version => _version;
  List<String>? get commands => _commands;
  List<String>? get modes => _modes;
  List<String>? get buttonModes => _buttonModes;
  List<String>? get longPressButtonModes => _longPressButtonModes;
  ChameleonRepository get repository => _repository;

  Future<bool> connect() async {
    final device = await _repository.connectFirstAvailable();
    if (device == null) return false;
    _applyDevice(device);
    notifyListeners();
    return true;
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    _version = null;
    _commands = null;
    _modes = null;
    _buttonModes = null;
    _longPressButtonModes = null;
    for (final slot in _slots) {
      slot.clear();
    }
    notifyListeners();
  }

  Future<String> getRssi() => _repository.getRssi();
  void reset() => _repository.reset();

  void _applyDevice(ChameleonDevice device) {
    _version = device.version;
    _commands = device.commands;
    _modes = device.modes;
    _buttonModes = device.buttonModes;
    _longPressButtonModes = device.longPressButtonModes;
    _slots = device.slots;
  }
}
