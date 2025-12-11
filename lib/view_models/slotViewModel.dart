import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/chameleonClient.dart';
import '../services/crapto1.dart';
import '../services/ffiService.dart';
import '../services/settings.dart';

class Mfkey32Exception implements Exception {
  String cause;
  Mfkey32Exception(this.cause);
}

class SlotViewModel extends ChangeNotifier {
  final Slot slot;
  final ChameleonClient client;
  final Settings settings;

  SlotViewModel(this.slot, this.client) : settings = Settings();

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  void setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  // Local state updates
  void setUid(String uid) {
    slot.uid = uid;
    notifyListeners();
  }

  void setMode(String? mode) {
    slot.mode = mode;
    notifyListeners();
  }

  void setButton(String? button) {
    slot.button = button;
    notifyListeners();
  }

  void setLongPressButton(String? button) {
    slot.longPressButton = button;
    notifyListeners();
  }

  Future<void> refresh() async {
    setBusy(true);
    try {
      var s = await client.refresh(slot.index);
      if (s != null) {
        slot.uid = s.uid;
        slot.mode = s.mode;
        slot.button = s.button;
        slot.longPressButton = s.longPressButton;
        slot.memorySize = s.memorySize;
        notifyListeners();
      }
    } finally {
      setBusy(false);
    }
  }

  Future<void> apply() async {
    setBusy(true);
    try {
      await client.active(slot.index);
      var selectedSlot = await client.getActive();
      if (selectedSlot != slot.index) return;

      if (slot.mode != null) await client.setMode(slot.mode!);
      if (slot.button != null) await client.setButton(slot.button!);
      if (slot.longPressButton != null)
        await client.setLongPressButton(slot.longPressButton!);
      if (slot.uid != null) await client.setUid(slot.uid!);

      await refresh();
    } finally {
      setBusy(false);
    }
  }

  Future<void> upload(Uint8List data) async {
    setBusy(true);
    try {
      await client.active(slot.index);
      await client.upload(data);
      await refresh();
    } finally {
      setBusy(false);
    }
  }

  Future<String> downloadMct() async {
    setBusy(true);
    try {
      await client.active(slot.index);
      var result = await client.download();
      if (result == null) throw Exception("Download failed");

      var data = result.take(slot.memorySize ?? 0).toList();
      return _toMct(data);
    } finally {
      setBusy(false);
    }
  }

  Future<void> clear() async {
    setBusy(true);
    try {
      await client.active(slot.index);
      if (await client.getMode() == 'MF_DETECTION') {
        await client.clearDetection();
      } else {
        await client.clear();
      }
      await refresh();
    } finally {
      setBusy(false);
    }
  }

  Future<List<String>> mfkey32() async {
    setBusy(true);
    try {
      await client.active(slot.index);
      var data = await client.getDetection();
      if (data.length == 0) {
        throw Mfkey32Exception('No data found on device.');
      }
      // no encrypt in 1.4 firmware
      int canary = _toUint64(data, 8);
      if (canary != 0x5245564556312E34) {
        ChameleonClient.decryptData(data, 123321, 208);
      }
      if (!Crc.checkCrc14443(Crc.CRC16_14443_A, data, 210)) {
        throw Mfkey32Exception('Data failed CRC check.');
      }
      var uid = _toUint32(data, 0);
      var nonces = <Nonce>[];
      for (var i = 1; i <= 12; i++) {
        var offset = i * 16;
        var nonce = Nonce()
          ..type = data[offset]
          ..block = data[offset + 1]
          ..nt = _toUint32(data, offset + 4)
          ..nr = _toUint32(data, offset + 8)
          ..ar = _toUint32(data, offset + 12);
        nonce.sector = _toSector(nonce.block);
        if (nonce.type != 0xFF) nonces.add(nonce);
      }
      if (nonces.length == 0) {
        throw Mfkey32Exception('No nonces record.');
      }

      List<String>? list;
      switch (settings.crapto1Implementation) {
        case Crapto1Implementation.Dart:
          list = await compute(keyWork, KeyWorkMessage(mfKey32, uid, nonces));
          break;
        case Crapto1Implementation.Java:
        case Crapto1Implementation.Online:
          list = await keyWork(KeyWorkMessage(mfKey32Java, uid, nonces));
          break;
        case Crapto1Implementation.Native:
          list = await compute(
            keyWork,
            KeyWorkMessage(mfKey32Native, uid, nonces),
          );
          break;
        default:
          break;
      }

      if (list == null || list.length == 0) {
        throw Mfkey32Exception('mfkey32 attack failed, no keys found.');
      }
      return list;
    } finally {
      setBusy(false);
    }
  }

  // Helpers
  static Uint8List stringToBytes(String data) {
    var result = Uint8List(data.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(data.substring(i << 1, i + 1 << 1), radix: 16);
    }
    return result;
  }

  int _toUint32(Uint8List data, int offset) {
    var v = 0;
    for (var i = 0; i < 4; i++) v = v << 8 | data[offset + i];
    return v;
  }

  int _toUint64(Uint8List data, int offset) {
    var v = 0;
    for (var i = 0; i < 8; i++) v = v << 8 | data[offset + i];
    return v;
  }

  int _toSector(int block) {
    if (block < 128) return block ~/ 4;
    return 32 + (block - 128) ~/ 16;
  }

  String _bytesToString(Iterable<int> bytes) {
    var str = '';
    for (var b in bytes)
      str += b.toRadixString(16).padLeft(2, '0').toUpperCase();
    return str;
  }

  String _toMct(List<int> data) {
    var strs = <String>[];
    var is4k = data.length == 4096;
    var size = is4k ? 32 : 16;
    for (var i = 0; i < size; i++) {
      strs.add('+Sector: $i');
      for (var j = 0; j < 4; j++) {
        var block = data.skip(i * 64 + j * 16).take(16);
        strs.add(_bytesToString(block));
      }
    }
    if (is4k) {
      for (var i = 32; i < 40; i++) {
        strs.add('+Sector: $i');
        for (var j = 0; j < 16; j++) {
          var block = data.skip(2048 + (i - 32) * 256 + j * 16).take(16);
          strs.add(_bytesToString(block));
        }
      }
    }
    return strs.join('\n');
  }
}
