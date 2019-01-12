import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:queries/collections.dart';
import 'package:flutter_nfc_reader/flutter_nfc_reader.dart';

import '../../services/chameleonClient.dart';
import '../../services/crapto1.dart';
import '../../generated/i18n.dart';

class SlotView extends StatefulWidget {
  SlotView({Key key, this.slot, this.client, this.modes, this.buttonModes, this.longPressButtonModes}) : super(key: key);

  final Slot slot;
  final ChameleonClient client;
  final List<String> modes, buttonModes, longPressButtonModes;

  @override
  _SlotViewState createState() => _SlotViewState();
}

class _SlotViewState extends State<SlotView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FocusNode uidFocusNode = FocusNode();
  _uidChanged(String str) => widget.slot.uid = str;
  _uidEditingComplete() {
    uidFocusNode.unfocus();
    print(widget.slot.uid);
  }
  _modeChanged(String str) => setState(() => widget.slot.mode = str);
  _buttonModeChanged(String str) => setState(() => widget.slot.button = str);
  _longPressButtonModeChanged(String str) => setState(() => widget.slot.longPressButton = str);

  Future<void> _refresh() async {
    var s = await widget.client.refresh(widget.slot.index);
    var slot = widget.slot;
    setState(() {
      slot.uid = s.uid;
      slot.mode = s.mode;
      slot.button = s.button;
      slot.longPressButton = s.longPressButton;
      slot.memorySize = s.memorySize;
    });
  }
  
  Future<void> _apply() async {
    var client = widget.client;
    var slot = widget.slot;
    await client.active(slot.index);
    var selectedSlot = await client.getActive();
    if (selectedSlot != slot.index)
      return;
    await client.setMode(slot.mode);
    await client.setButton(slot.button);
    if (widget.longPressButtonModes != null)
      await client.setLongPressButton(slot.longPressButton);
    await client.setUid(slot.uid);
    await _refresh();
  }

  Uint8List stringToBytes(String data) {
    var result = Uint8List(data.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(data.substring(i << 1, i + 1 << 1), radix: 16);
    }
    return result;
  }

  Future<void> _upload() async {
    var client = widget.client;
    var slot = widget.slot;
    
    final permissionStatus = await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
    if (permissionStatus == PermissionStatus.authorized) {
      var filePath = await FilePicker.getFilePath(type: FileType.ANY);
      if (filePath == null)
        return;
      var file = File(filePath);
      var str = (await file.readAsLines())
        .where((str) => str.length == 32)
        .map((str) => str.replaceAll('-', 'F'))
        .join();
      var data = stringToBytes(str);
      await client.active(slot.index);
      await client.upload(data);
      await _refresh();
      final snackBar = SnackBar(content: Text('Upload MCT file success.'));
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _mfkey32() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                Container(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(S.of(context).attacking),
                ),
              ],
            ),
          ),
        ),
      )
    );
    List<String> list;
    try {
      var client = widget.client;
      var slot = widget.slot;

      await client.active(slot.index);
      var data = await client.getDetection();
      if (data == null || data.length == 0) {
        final snackBar = SnackBar(content: Text('No data found on device.'));
        Scaffold.of(context).showSnackBar(snackBar);
        return;
      }
      ChameleonClient.decryptData(data, 123321, 208);
      if (!Crc.checkCrc14443(Crc.CRC16_14443_A, data, 210)) {
        final snackBar = SnackBar(content: Text('Data failed CRC check.'));
        Scaffold.of(context).showSnackBar(snackBar);
        return;
      }
      var uid = _toUint32(data, 0);
      var nonces = Collection<Nonce>();
      for (var i = 1; i <= 12; i++)
      {
        var offset = i * 16;
        var nonce = Nonce()
          ..type = data[offset]
          ..block = data[offset + 1]                 
          ..nt = _toUint32(data, offset + 4)
          ..nr = _toUint32(data, offset + 8)
          ..ar = _toUint32(data, offset + 12);
        nonce.sector = _toSector(nonce.block);
        if (nonce.block < 40)
          nonces.add(nonce);
      }
      /*var receivePort = ReceivePort();
      await Isolate.spawn(
        keyWork,
        KeyWorkMessage()
          ..sendPort=receivePort.sendPort
          ..uid=uid
          ..nonces=nonces,
      );
      list = await receivePort.first;*/
      list = await keyWorkn(
        KeyWorkMessage()
          ..uid=uid
          ..nonces=nonces
      );
      if (list.length == 0) {
        final snackBar = SnackBar(content: Text('mfkey32 attack failed, no keys found.'));
        Scaffold.of(context).showSnackBar(snackBar);
        return;
      }
    } finally {
      Navigator.pop(context);
    }
    if (list != null) {
      final result = list.join('\n');
      var thisContext = context;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("mfkey32 result"),
            content: Text(result),
            actions: <Widget>[
              FlatButton(
                child: Text("Copy and Close"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result));
                  Navigator.pop(context);
                  final snackBar = SnackBar(content: Text('Copied to clipboard.'), duration: Duration(seconds: 3),);
                  Scaffold.of(thisContext).showSnackBar(snackBar);
                },
              ),
            ],
          );
        },
      );
    }
  }

  int _toUint32(Uint8List data, int offset) {
    var v = 0;
    for (var i = 0; i < 4; i++)
      v = v << 8 | data[offset + i];
    return v;
  }

  int _toSector(int block)
  {
    if (block < 128)
      return  block ~/ 4;
    return 32 + (block - 128) ~/ 16;
  }

  String bytesToString(Iterable<int> bytes) {
    var str = '';
    for (var b in bytes)
      str += b.toRadixString(16).padLeft(2, '0').toUpperCase();
    return str;
  }

  String toMct(List<int> data) {
    var strs = <String>[];
    var is4k = data.length == 4096;
    var size = is4k ? 32 : 16;
    for (var i = 0; i < size; i++) {
      strs.add('+Sector: $i');
      for (var j = 0; j < 4; j++) {
        var block = data.skip(i * 64 + j * 16).take(16);
        strs.add(bytesToString(block));
      }
    }
    if (is4k) {
      for (var i = 32; i < 40; i++) {
        strs.add('+Sector: $i');
        for (var j = 0; j < 16; j++) {
          var block = data.skip(2048 + (i - 32) * 256 + j * 16).take(16);
          strs.add(bytesToString(block));
        }
      }
    }
    return strs.join('\n');
  }

  Future<void> _download() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                Container(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(S.of(context).downloading),
                ),
              ],
            ),
          ),
        ),
      )
    );
    try {
      var client = widget.client;
      var slot = widget.slot;
      await client.active(slot.index);
      var uid = await client.getUid();
      var result = await client.download();
      var data = result.take(slot.memorySize).toList();
      var mctFormat = toMct(data);
      final permissionStatus = await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
      if (permissionStatus == PermissionStatus.authorized) {
        var d = Directory('${(await getExternalStorageDirectory()).path}/MifareClassicTool/dump-files');
        if (!await d.exists())
          await d.create(recursive: true);
              
        var now = DateTime.now();
        var formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
        var f = File('${(await getExternalStorageDirectory()).path}/MifareClassicTool/dump-files/UID_${uid}_${formatter.format(now)}');
        await f.writeAsString(mctFormat);
        final snackBar = SnackBar(content: Text('Saved to MCT folder.'));
        Scaffold.of(context).showSnackBar(snackBar);
      }
    } finally {
      Navigator.pop(context);
    }
  }

  Future<void> _nfc() async {
    String response;
    try {
      final snackBar = SnackBar(
        content: Text('Start scan card.'),
        duration: Duration(hours: 1),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () async {
            await FlutterNfcReader.stop;
          },
        ),
      );
      Scaffold.of(context).showSnackBar(snackBar);
      response = await FlutterNfcReader.read;
      print(response);
      if (response != null) {
        setState(() {
          widget.slot.uid = response.substring(2).toUpperCase(); 
        });
      }
      Scaffold.of(context).hideCurrentSnackBar();
      await Future.delayed(Duration(seconds: 1));
      await FlutterNfcReader.stop;
    } on PlatformException {
      response = '';
    }
  }
  
  Future<void> _clear() async {
    var client = widget.client;
    var slot = widget.slot;
    await client.active(slot.index);
    await client.clear();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Form(
        key: _formKey,
        autovalidate: true,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.functions),
                    labelText: S.of(context).mode,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      disabledHint: Text(S.of(context).notAvailable),
                      value: widget.slot.mode,
                      isDense: true,
                      items: widget.modes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList(),
                      onChanged: _modeChanged,
                    ),
                  ),
                );
              },
            ),
            TextField(
              enabled: widget.client.connected,
              focusNode: uidFocusNode,
              controller: TextEditingController(text: widget.slot.uid),
              decoration: InputDecoration(
                icon: const Icon(Icons.fingerprint),
                labelText: S.of(context).uid,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.nfc),
                  onPressed: _nfc,
                )
              ),
              keyboardType: TextInputType.text,
              inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter(RegExp(r'^[0-9a-fA-F]{0,14}')),
              ],
              onChanged: _uidChanged,
              onEditingComplete: _uidEditingComplete,
            ),
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.touch_app),
                    labelText: S.of(context).button,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      disabledHint: Text(S.of(context).notAvailable),
                      value: widget.slot.button,
                      isDense: true,
                      items: widget.buttonModes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList(),
                      onChanged: _buttonModeChanged,
                    ),
                  ),
                );
              },
            ),
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.touch_app),
                    labelText: S.of(context).longPressButton,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      disabledHint: Text(S.of(context).notAvailable),
                      value: widget.slot.longPressButton,
                      isDense: true,
                      items: widget.longPressButtonModes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList(),
                      onChanged: _longPressButtonModeChanged,
                    ),
                  ),
                );
              },
            ),
            TextField(
              enabled: false,
              controller: TextEditingController(text: widget.slot.memorySize?.toString()),
              decoration: InputDecoration(
                icon: const Icon(Icons.memory),
                labelText: S.of(context).memorySize,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).refresh),
                      onPressed: widget.client.connected ? _refresh : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).apply),
                      onPressed: widget.client.connected ? _apply : null,
                    ),
                  ),
                ],
              )
            ),
            Container(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).upload),
                      onPressed: widget.client.connected ? _upload : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).download),
                      onPressed: widget.client.connected ? _download : null,
                    ),
                  ),
                ],
              )
            ),
            Container(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).clear),
                      onPressed: widget.client.connected ? _clear : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).mfkey32),
                      onPressed: widget.client.connected ? _mfkey32 : null,
                    ),
                  ),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}