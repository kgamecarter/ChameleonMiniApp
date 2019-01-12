import 'dart:typed_data';
import 'dart:async';
import 'dart:collection';

class _ByteReader {
  Queue<int> _queue;
  Stream<Uint8List> _sream;
  StreamSubscription<Uint8List> _subscription;
  Completer<void> _c;

  _ByteReader(this._sream) {
    _queue = Queue();
    _c = Completer();
    _subscription = _sream.listen(_onData);
  }

  void _onData(Uint8List data) {
    _queue.addAll(data);
    _c.complete();
    _c = Completer();
  }

  Future<int> get read async {
    if (_queue.length == 0)
      await _c.future;
    return _queue.removeFirst();
  }

  Future<dynamic> cancel() => _subscription.cancel();
}

class Xmodem {
  static const SOH = 0x01;
  static const EOT = 0x04;
  static const ACK = 0x06;
  static const NAK = 0x15;
  static const CAN = 0x18;

  static const SECTOR_SIZE = 128;
  static const MAX_ERRORS = 10;

  final void Function(Uint8List) output;
  final Stream<Uint8List> input;

  Xmodem(this.input, this.output);

  Future<void> send(Uint8List data) async {
    int errorCount;
    int blockNumber = 0x01;
    int checkSum;
    int nbytes;
    var buffer = Uint8List(SECTOR_SIZE);

    var queue = Queue<int>.from(data);
    int read() {
      var len = 0;
      while (len < buffer.length && queue.length > 0)
        buffer[len++] = queue.removeFirst();
      return len;
    }

    var reader = _ByteReader(input);

    while ((nbytes = read()) > 0) {
      // less 128, padding 0xFF
      if (nbytes < SECTOR_SIZE) {
        for (int i = nbytes; i < SECTOR_SIZE; i++) {
          buffer[i] = 0xFF;
        }
      }

      errorCount = 0;
      while (errorCount < MAX_ERRORS) {
        output(Uint8List.fromList(<int>[
          SOH,
          blockNumber,
          ~blockNumber & 0xFF
        ]));
        output(buffer);
        checkSum = buffer.reduce((v, e) => v + e);
        putData(checkSum);

        // get ACK
        var data = await reader.read;
        if (data == ACK) {
          break;
        } else {
          ++errorCount;
        }
      }
      blockNumber = (blockNumber + 1) & 0xFF;
    }

    // 所有数据发送完成后，发送结束标识
    var isAck = false;
    while (!isAck) {
      putData(EOT);
      isAck = await reader.read == ACK;
    }
    reader.cancel();
  }

  Future<Uint8List> receive() async {
    var output = <int>[];
    var reader = _ByteReader(input);

    int errorCount = 0;
    var blockNumber = 1;
    int data;
    var buffer = Uint8List(SECTOR_SIZE);

    // Checksum type
    putData(NAK);

    while (true) {
      if (errorCount > MAX_ERRORS) {
        return null;
      }

      data = await reader.read;
      if (data != EOT) {
        try {
          if (data != SOH) {
            errorCount++;
            continue;
          }

          // block number
          data = await reader.read;
          // check block number
          if (data != (blockNumber & 0xFF)) {
            errorCount++;
            continue;
          }

          // check ~blockNumber
          int _blockNumber = await reader.read;
          if (data + _blockNumber != 255) {
            errorCount++;
            continue;
          }

          var sum = 0;
          // get data
          for (var i = 0; i < SECTOR_SIZE; i++) {
            buffer[i] = await reader.read;
            sum += buffer[i];
          }

          int checksum = await reader.read;
          if (sum & 0xFF != checksum) {
            errorCount++;
            continue;
          }

          putData(ACK);
          blockNumber = (blockNumber + 1) & 0xFF;
          output.addAll(buffer);
          errorCount = 0;
        } catch (e) {
          print(e);
        } finally {
          if (errorCount != 0) {
            putData(NAK);
          }
        }
      } else {
        break;
      }
    }
    putData(ACK);
    reader.cancel();
    return Uint8List.fromList(output);
  }

  void putData(int data) {
    output(Uint8List.fromList(<int>[data]));
  }
}