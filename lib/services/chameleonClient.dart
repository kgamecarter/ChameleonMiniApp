import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:usb_serial/usb_serial.dart';

import 'xmodem.dart';

class Slot {
  Slot(this.index);

  final int index;
  String? uid;
  int? memorySize;
  String? mode;
  String? button;
  String? longPressButton;
}

class ChameleonCommands {
  static var v1_0 = ChameleonCommands();
  static var v1_3 = ChameleonCommandsV1_3(); 

  String get getVersion => 'VERSIONMY?';
  String get active => 'SETTINGMY=';
  String get getActive => 'SETTINGMY?';
  String get getCommands => 'HELPMY';
  String get getModes => 'CONFIGMY';
  String get getButtonModes => 'BUTTONMY';
  String get getLongPressButtonModes => 'BUTTON_LONGMY';
  String get getMemorySize => 'MEMSIZEMY?';
  String get getUidSize => 'UIDSIZEMY?';
  String get getUid => 'UIDMY?';
  String get setUid => 'UIDMY=';
  String get getMode => 'CONFIGMY?';
  String get setMode => 'CONFIGMY=';
  String get getButton => 'BUTTONMY?';
  String get setButton => 'BUTTONMY=';
  String get getLongPressButton => 'BUTTON_LONGMY?';
  String get setLongPressButton => 'BUTTON_LONGMY=';
  String get getReadOnly => 'READONLYMY?';
  String get setReadOnly => 'READONLYMY=';
  String get getDetection => 'DETECTIONMY?';
  String get clearDetection => 'DETECTIONMY=';
  String get reset => 'RESETMY';
  String get clear => 'CLEARMY';
  String get getRssi => 'RSSIMY?';
  String get download => 'DOWNLOADMY';
  String get upload => 'UPLOADMY';
}

class ChameleonCommandsV1_3 extends ChameleonCommands {
  @override
  String get getVersion => 'VERSION?';
  @override
  String get active => 'SETTING=';
  @override
  String get getActive => 'SETTING?';
  @override
  String get getCommands => 'HELP';
  @override
  String get getModes => 'CONFIG';
  @override
  String get getButtonModes => 'BUTTON';
  @override
  String get getLongPressButtonModes => 'BUTTON_LONG';
  @override
  String get getMemorySize => 'MEMSIZE?';
  @override
  String get getUidSize => 'UIDSIZE?';
  @override
  String get getUid => 'UID?';
  @override
  String get setUid => 'UID=';
  @override
  String get getMode => 'CONFIG?';
  @override
  String get setMode => 'CONFIG=';
  @override
  String get getButton => 'BUTTON?';
  @override
  String get setButton => 'BUTTON=';
  @override
  String get getLongPressButton => 'BUTTON_LONG?';
  @override
  String get setLongPressButton => 'BUTTON_LONG=';
  @override
  String get getReadOnly => 'READONLY?';
  @override
  String get setReadOnly => 'READONLY=';
  @override
  String get getDetection => 'DETECTION?';
  @override
  String get clearDetection => 'DETECTION=';
  @override
  String get reset => 'RESET';
  @override
  String get clear => 'CLEAR';
  @override
  String get getRssi => 'RSSI?';
  @override
  String get download => 'DOWNLOAD';
  @override
  String get upload => 'UPLOAD';
}

class ChameleonClient {
  ChameleonCommands commands = ChameleonCommands.v1_0;
  final asciiCodec = AsciiCodec();
  UsbPort? port;
  StreamSubscription<Uint8List>? subcription;

  ChameleonClient([this.port]);

  Future close() async {
    await subcription?.cancel();
    subcription = null;
    await port?.close();
    port = null;
  }

  Future<Xmodem> sendCommandXmodem(String cmd) async {
    var xmodem = Xmodem(port!.inputStream, port!.write);
    await sendCommand(cmd);
    return xmodem;
  }

  void sendCommandWithoutWait(String cmd) {
    print(cmd);
    var data = asciiCodec.encode('$cmd\r\n');
    port!.write(data);
  }

  Future<Uint8List> sendCommandRaw(String cmd) async {
    print(cmd);
    var data = asciiCodec.encode('$cmd\r\n');
    var c = new Completer<Uint8List>();
    if (subcription == null)
      subcription = port!.inputStream.listen(null);
    subcription!.onData((bytes) {
      c.complete(bytes);
      subcription!.onData(null);
    });
    await port!.write(data);
    return await c.future;
  }

  Future<String> sendCommand(String cmd) async {
    var bytes = await sendCommandRaw(cmd);
    var str = asciiCodec.decode(bytes);
    print(str);
    var strs = str.split('\r\n').where((s) => s.isNotEmpty).toList();
    if (strs[0].startsWith('100:') || // 100:OK
        strs[0].startsWith('110:')) { // 110:WAITING FOR XMODEM
      return '';
    } else if (strs[0].startsWith('101:')) { // 101:OK WITH TEXT
      return strs[strs.length - 1];
    } else {
      throw str[0];
    }
  }

  bool get connected => port != null;

  Future<String> getVersion() => sendCommand(commands.getVersion);

  Future<void> active(int index) async => await sendCommand(commands.active + index.toString());

  Future<int> getActive() async {
    var result = await sendCommand(commands.getActive);
    return int.parse(result[result.length - 1]);
  }

  Future<List<String>> getCommands() async {
    var result = await sendCommand(commands.getCommands);
    return result.split(',');
  }

  Future<List<String>> getModes() async {
    var result = await sendCommand(commands.getModes);
    return result.split(',');
  }

  Future<List<String>> getButtonModes() async {
    var result = await sendCommand(commands.getButtonModes);
    return result.split(',');
  }

  Future<List<String>> getLongPressButtonModes() async {
    var result = await sendCommand(commands.getLongPressButtonModes);
    return result.split(',');
  }

  Future<int> getMemorySize() async => int.parse(await sendCommand(commands.getMemorySize));

  Future<int> getUidSize() async => int.parse(await sendCommand(commands.getUidSize));

  Future<String> getUid() => sendCommand(commands.getUid);

  Future<void> setUid(String uid) => sendCommand(commands.setUid + uid);

  Future<String> getMode() => sendCommand(commands.getMode);

  Future<void> setMode(String mode) => sendCommand(commands.setMode + mode);

  Future<String> getButton() => sendCommand(commands.getButton);

  Future<void> setButton(String mode) => sendCommand(commands.setButton + mode);

  Future<String> getLongPressButton() => sendCommand(commands.getLongPressButton);

  Future<void> setLongPressButton(String mode) => sendCommand(commands.setLongPressButton + mode);

  Future<bool> getReadOnly() async => (await sendCommand(commands.getReadOnly) == '1' ? true : false);

  Future<void> setReadOnly(bool state) => sendCommand(commands.setReadOnly + (state ? '1' : '0'));

  Future<Uint8List> getDetection() => sendCommandRaw(commands.getDetection);

  Future<void> clearDetection() => sendCommand(commands.clearDetection);

  void reset() => sendCommandWithoutWait(commands.reset);

  Future<void> clear() => sendCommand(commands.clear);

  Future<String> getRssi() => sendCommand(commands.getRssi);

  Future<Uint8List?> download() async {
    var xmodem = await sendCommandXmodem(commands.download);
    return await xmodem.receive();
  }

  Future<void> upload(Uint8List data) async {
    var xmodem = await sendCommandXmodem(commands.upload);
    await xmodem.send(data);
  }

  Future<List<Slot>> refreshAll() async {
    var selectedSlot = await getActive();
    var slots = <Slot>[];
    for (int i = 0; i < 8; i++)
      slots.add((await refresh(i))!);
    await active(selectedSlot);
    return slots;
  }

  Future<Slot?> refresh(int i) async {
    await active(i);
    var selectedSlot = await getActive();
    if (selectedSlot != i)
      return null;
    var slot = Slot(i);
    slot.uid = await getUid();
    slot.mode = await getMode();
    slot.button = await getButton();
    try {
      slot.longPressButton = await getLongPressButton();
    } catch (e) { }
    slot.memorySize = await getMemorySize();
    return slot;
  }
  
  Future<void> checkCommand() async {
    try {
      this.commands = ChameleonCommands.v1_0;
      await this.getVersion();
    } catch (e) {
      this.commands = ChameleonCommands.v1_3;
    }
  }

  static void decryptData(Uint8List arr, int key, int size)
  {
    for (int i = 0; i < size; i++)
      arr[i] = size + key + i - size ~/ key ^ arr[i];
  }
}

class Crc
{
  static const CRC16_14443_A = 0x6363;
  static const CRC16_14443_B = 0xFFFF;

  static int _updateCrc14443(int b, int crc)
  {
    int ch = b ^ (crc & 0x00ff);
    ch = (ch ^ (ch << 4)) & 0xFF;
    return ((crc >> 8) ^ (ch << 8) ^ (ch << 3) ^ (ch >> 4)) & 0xFFFF;
  }

  static int _computeCrc14443(int crcType, Uint8List bytes, int len)
  {
    if (len < 2)
      return -1;
    var res = crcType;

    for (int i = 0; i < len; i++)
      res = _updateCrc14443(bytes[i], res);

    if (crcType == CRC16_14443_B)
      res = ~res & 0xFFFF;                /* ISO/IEC 13239 (formerly ISO/IEC 3309) */
    return res;
  }

  static bool checkCrc14443(int crcType, Uint8List bytes, int len)
  {
    if (len < 3) return false;

    var res = _computeCrc14443(crcType, bytes, len - 2);
    if (res == (bytes[len - 2] | bytes[len - 1] << 8))
      return true;
    return false;
  }
}
