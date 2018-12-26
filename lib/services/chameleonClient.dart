import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:usb_serial/usb_serial.dart';

import 'xmodem.dart';

class Slot {
  Slot({this.index});

  final int index;
  String uid;
  int memorySize;
  String mode;
  String button;
  String longPressButton;
}

class ChameleonClient {
  final asciiCodec = AsciiCodec();
  UsbPort port;
  StreamSubscription<Uint8List> subcription;

  ChameleonClient([this.port]);

  Future close() async {
    await subcription?.cancel();
    subcription = null;
    await port?.close();
    port = null;
  }

  Future<Xmodem> sendCommandXmodem(String cmd) async {
    var xmodem = Xmodem(port.inputStream, port.write);
    await sendCommand(cmd);
    return xmodem;
  }

  Future<Uint8List> sendCommandRaw(String cmd) async {
    print(cmd);
    var data = asciiCodec.encode('$cmd\r\n');
    var c = new Completer<Uint8List>();
    if (subcription == null)
      subcription = port.inputStream.listen(null);
    subcription.onData((bytes) {
      c.complete(bytes);
      subcription.onData(null);
    });
    await port.write(data);
    return await c.future;
  }

  Future<String> sendCommand(String cmd) async {
    var bytes = await sendCommandRaw(cmd);
    var str = asciiCodec.decode(bytes);
    print(str);
    var strs = str.split('\r\n').where((s) => s.isNotEmpty).toList();
    if (strs[0].startsWith('100:') || // 100:OK
        strs[0].startsWith('110:')) { // 110:WAITING FOR XMODEM
      return null;
    } else if (strs[0].startsWith('101:')) { // 101:OK WITH TEXT
      return strs[strs.length - 1];
    } else {
      throw str[0];
    }
  }

  bool get connected => port != null;

  Future<String> version() => sendCommand('VERSIONMY?');

  Future<void> active(int index) async => await sendCommand('SETTINGMY=$index');

  Future<int> getActive() async {
    var result = await sendCommand('SETTINGMY?');
    return int.parse(result[result.length - 1]);
  }

  Future<List<String>> getCommands() async {
    var result = await sendCommand('HELPMY');
    return result.split(',');
  }

  Future<List<String>> getModes() async {
    var result = await sendCommand('CONFIGMY');
    return result.split(',');
  }

  Future<List<String>> getButtonModes() async {
    var result = await sendCommand('BUTTONMY');
    return result.split(',');
  }

  Future<List<String>> getLongPressButtonModes() async {
    var result = await sendCommand('BUTTON_LONGMY');
    return result.split(',');
  }

  Future<int> getMemorySize() async => int.parse(await sendCommand('MEMSIZEMY?'));

  Future<int> getUidSize() async => int.parse(await sendCommand('UIDSIZEMY?'));

  Future<String> getUid() => sendCommand('UIDMY?');

  Future<void> setUid(String uid) => sendCommand('UIDMY=$uid');

  Future<String> getMode() => sendCommand('CONFIGMY?');

  Future<void> setMode(String mode) => sendCommand('CONFIGMY=$mode');

  Future<String> getButton() => sendCommand('BUTTONMY?');

  Future<void> setButton(String mode) => sendCommand('BUTTONMY=$mode');

  Future<String> getLongPressButton() => sendCommand('BUTTON_LONGMY?');

  Future<void> setLongPressButton(String mode) => sendCommand('BUTTON_LONGMY=$mode');

  Future<bool> getReadOnly() async => (await sendCommand('READONLYMY?') == '1' ? true : false);

  Future<void> setReadOnly(bool state) => sendCommand('READONLYMY=${state ? 1 : 0}');

  Future<Uint8List> getDetection() => sendCommandRaw('DETECTIONMY?');

  Future<void> reset() => sendCommand('RESETMY');

  Future<void> clear() => sendCommand('CLEARMY');

  Future<String> getRssi() => sendCommand('RSSIMY?');

  Future<Uint8List> download() async {
    var xmodem = await sendCommandXmodem('DOWNLOADMY');
    return await xmodem.receive();
  }

  Future<void> upload(Uint8List data) async {
    var xmodem = await sendCommandXmodem('UPLOADMY');
    await xmodem.send(data);
  }

  Future<List<Slot>> refreshAll() async {
    var selectedSlot = await getActive();
    var slots = <Slot>[];
    for (int i = 0; i < 8; i++)
      slots.add(await refresh(i));
    await active(selectedSlot);
    return slots;
  }

  Future<Slot> refresh(int i) async {
    await active(i);
    var selectedSlot = await getActive();
    if (selectedSlot != i)
      return null;
    var slot = Slot(index: i);
    slot.uid = await getUid();
    slot.mode = await getMode();
    slot.button = await getButton();
    try {
      slot.longPressButton = await getLongPressButton();
    } catch (e) { }
    slot.memorySize = await getMemorySize();
    return slot;
  }
}