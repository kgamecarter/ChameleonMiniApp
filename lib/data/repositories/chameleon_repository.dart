import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import '../../domain/models/chameleon_device.dart';
import '../../domain/models/slot.dart';
import '../services/chameleon_client_service.dart';

/// Single source of truth for the USB device and its command protocol.
class ChameleonRepository {
  ChameleonRepository({ChameleonClient? client})
    : _client = client ?? ChameleonClient();

  final ChameleonClient _client;

  bool get connected => _client.connected;

  Future<ChameleonDevice?> connectFirstAvailable() async {
    final devices = await UsbSerial.listDevices();
    if (devices.isEmpty) return null;

    final port = await devices.first.create();
    if (port == null || !await port.open()) return null;

    await port.setDTR(true);
    await port.setRTS(true);
    await port.setPortParameters(
      115200,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    _client.port = port;
    await _client.checkCommand();
    final version = await _client.getVersion();
    final commands = await _client.getCommands();
    final modes = await _client.getModes();
    final buttonModes = await _client.getButtonModes();
    List<String>? longPressButtonModes;
    try {
      longPressButtonModes = await _client.getLongPressButtonModes();
    } catch (_) {
      // Older firmware does not expose long-press button modes.
    }

    return ChameleonDevice(
      version: version,
      commands: commands,
      modes: modes,
      buttonModes: buttonModes,
      longPressButtonModes: longPressButtonModes,
      slots: await _client.refreshAll(),
    );
  }

  Future<void> disconnect() => _client.close();
  Future<String> getRssi() => _client.getRssi();
  void reset() => _client.reset();
  Future<Slot?> refresh(int index) => _client.refresh(index);
  Future<void> activate(int index) => _client.active(index);
  Future<int> getActive() => _client.getActive();
  Future<void> setMode(String mode) => _client.setMode(mode);
  Future<void> setButton(String button) => _client.setButton(button);
  Future<void> setLongPressButton(String button) =>
      _client.setLongPressButton(button);
  Future<void> setUid(String uid) => _client.setUid(uid);
  Future<void> upload(Uint8List data) => _client.upload(data);
  Future<Uint8List?> download() => _client.download();
  Future<String> getMode() => _client.getMode();
  Future<void> clearDetection() => _client.clearDetection();
  Future<void> clear() => _client.clear();
  Future<Uint8List> getDetection() => _client.getDetection();

  void decryptDetectionData(Uint8List data, int key, int size) =>
      ChameleonClient.decryptData(data, key, size);

  bool hasValidDetectionCrc(Uint8List data) =>
      Crc.checkCrc14443(Crc.CRC16_14443_A, data, 210);
}
