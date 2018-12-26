import 'dart:typed_data';
import 'dart:async';
import 'dart:collection';

class Xmodem {
  static const SOH = 0x01;
  static const EOT = 0x04;
  static const ACK = 0x06;
  static const NAK = 0x15;
  static const CAN = 0x18;

  static const SECTOR_SIZE = 128;
  static const MAX_ERRORS = 10;
  static const PADDING_BYTE = 26;

  void Function(Uint8List) output;
  Stream<Uint8List> intput;

  Xmodem(this.intput, this.output);

  void send(Uint8List data) async {/*
    // 错误包数
    int errorCount;
    // 包序号
    int blockNumber = 0x01;
    // 校验和
    int checkSum;
    // 读取到缓冲区的字节数量
    int nbytes;
    // 初始化数据缓冲区
    var sector = Uint8List(SECTOR_SIZE);

    while ((nbytes = inputStream.read(sector)) > 0) {
        // 如果最后一包数据小于128个字节，以0xff补齐
        if (nbytes < SECTOR_SIZE) {
            for (int i = nbytes; i < SECTOR_SIZE; i++) {
                sector[i] = (byte) 0xff;
            }
        }

        // 同一包数据最多发送10次
        errorCount = 0;
        while (errorCount < MAX_ERRORS) {
            // 组包
            // 控制字符 + 包序号 + 包序号的反码 + 数据 + 校验和
            putData(SOH);
            putData(blockNumber);
            putData(~blockNumber);
            checkSum = CRC16.calc(sector) & 0x00ffff;
            putChar(sector, (short) checkSum);
            outputStream.flush();

            // 获取应答数据
            var data = getData();
            // 如果收到应答数据则跳出循环，发送下一包数据
            // 未收到应答，错误包数+1，继续重发
            if (data == ACK) {
                break;
            } else {
                ++errorCount;
            }
        }
        // 包序号自增
        blockNumber = ((++blockNumber) % 256);
    }

    // 所有数据发送完成后，发送结束标识
    var isAck = false;
    while (!isAck) {
        putData(EOT);
        isAck = getData() == ACK;
    }*/
  }

  Future<Uint8List> receive() async {
    var output = <int>[];
    var queue = Queue<int>();
    Completer c = new Completer();
    var subcription = intput.listen((bytes) {
      queue.addAll(bytes);
      c.complete();
      c = new Completer();
    });

    Future<int> getData() async {
      if (queue.length == 0) {
        await c.future;
      }
      return queue.removeFirst();
    }

    int errorCount = 0;
    var blocknumber = 0x01;
    int data;
    var buffer = Uint8List(SECTOR_SIZE);

    // Checksum type
    putData(NAK);

    while (true) {
        if (errorCount > MAX_ERRORS) {
            return null;
        }

        data = await getData();
        if (data != EOT) {
            try {
                if (data != SOH) {
                    errorCount++;
                    continue;
                }

                // block number
                data = await getData();
                // check block number
                if (data != (blocknumber & 0xFF)) {
                    errorCount++;
                    continue;
                }

                // check ~blockNumber
                int _blocknumber = await getData();
                if (data + _blocknumber != 255) {
                    errorCount++;
                    continue;
                }

                var sum = 0;
                // get data
                for (var i = 0; i < SECTOR_SIZE; i++) {
                    buffer[i] = await getData();
                    sum += buffer[i];
                }

                int checksum = await getData();
                if (sum & 0xFF != checksum) {
                    errorCount++;
                    continue;
                }

                putData(ACK);
                blocknumber++;
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
    subcription.cancel();
    return Uint8List.fromList(output);
  }

  void putData(int data) {
    var list = <int>[];
    list.add(data);
    output(Uint8List.fromList(list));
  }
}