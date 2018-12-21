import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:usb_serial/usb_serial.dart';

class ChameleonClient {
  final asciiCodec = AsciiCodec();
  UsbPort port;
  StreamSubscription<Uint8List> subcription;

  ChameleonClient([this.port]);

  _emptyEvent(Uint8List data) { }

  Future close() async {
    await port?.close();
    port = null;
    subcription = null;
  }

  Future<String> sendCommand(String cmd) async {
    var data = asciiCodec.encode('$cmd\r\n');
    var c = new Completer<String>();
    if (subcription == null)
      subcription = port.inputStream.listen(_emptyEvent);
    subcription.onData((bytes) {
      var str = asciiCodec.decode(bytes);
      var strs = str.split('\r\n').where((s) => s.isNotEmpty).toList();
      if (strs.length == 1 &&
          str[0] != '100:OK' &&
          str[0] != '101:OK WITH TEXT') {
        c.completeError(str[0]);
      } else {
        c.complete(strs[strs.length - 1]);
      }
      subcription.onData(_emptyEvent);
    });
    await port.write(data);
    return await c.future;
  }

  Future<String> version() => sendCommand('VERSIONMY?');

  Future active(int index) async => await sendCommand('SETTINGMY=$index');

  Future<int> getActive() async {
    var result = await sendCommand('SETTINGMY?');
    return int.parse(result[result.length - 1]);
  }
}