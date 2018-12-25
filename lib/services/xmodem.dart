import 'dart:typed_data';

class Xmodem {
    static const SOH = 0x01;
    static const EOT = 0x04;
    static const ACK = 0x06;
    static const NAK = 0x15;
    static const CAN = 0x18;

    static const  SECTOR_SIZE = 128;
    static const  MAX_ERRORS = 10;

    void Function(Uint8List) output;
    Stream<Uint8List> intput;

    Xmodem(this.intput, this.output);

    void send(Uint8List data) {
      // TODO
    }

    Uint8List receive() {
      // TODO
      return null;
    }

    void putData(int data) => output(Uint8List.fromList([data]));

    void putChar(Uint8List data, int checkSum) {
        data = Uint8List.fromList(data);
        // Big Endian
        data.add((checkSum >> 8) & 0xFF);
        data.add(checkSum & 0xFF);
        output(data);
    }
}