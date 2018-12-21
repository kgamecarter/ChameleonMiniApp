import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:usb_serial/usb_serial.dart';

import 'slotView.dart';
import '../../generated/i18n.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  GlobalKey<ScaffoldState> scaffoldState = new GlobalKey<ScaffoldState>();

  List<Slot> slots = <Slot>[
    Slot(index: 0),
    Slot(index: 1),
    Slot(index: 2),
    Slot(index: 3),
    Slot(index: 4),
    Slot(index: 5),
    Slot(index: 6),
    Slot(index: 7),
  ];
  final List<Icon> slotIcons = const <Icon>[
    const Icon(Icons.filter_1),
    const Icon(Icons.filter_2),
    const Icon(Icons.filter_3),
    const Icon(Icons.filter_4),
    const Icon(Icons.filter_5),
    const Icon(Icons.filter_6),
    const Icon(Icons.filter_7),
    const Icon(Icons.filter_8),
  ];
  bool connected = false;
  UsbPort port;

  _pushSettings() {
    Navigator.of(context).pushNamed('/Settings');
  }

  _disconnected() async {
    await port?.close();
    port = null;
    scaffoldState.currentState.showSnackBar(SnackBar(
      content: Text(S.of(context).usbDisconnected),
      duration: Duration(seconds: 10),
    ));
    setState(() => connected = false);
  }

  _connect() async {
    if (connected) {
      await _disconnected();
      return;
    }
    List<UsbDevice> devices = await UsbSerial.listDevices();
    print(devices);

    if (devices.length == 0) {
      return;
    } 
    port = await devices[0].create();
    
    bool openResult = await port.open();
    if ( !openResult ) {
      print("Failed to open");
      return;
    }
    
    await port.setDTR(true);
    await port.setRTS(true);

    port.setPortParameters(115200, UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    // print first result and close port.
    var decoder = AsciiDecoder();
    port.inputStream.listen((Uint8List event) {
      var str = decoder.convert(event);
      print(str);
      setState(() {
        slots[0].uid = str;
      });
    });
    var encoder = AsciiEncoder();
    var ascii = encoder.convert('VERSIONMY?\r\n');
    port.write(ascii);
    setState(() => connected = true);
  }

  @override
  void initState() {
    super.initState();

    UsbSerial.usbEventStream.listen((UsbEvent msg) {
      print("Usb Event $msg");
      if (msg.event == UsbEvent.ACTION_USB_ATTACHED) {
        _connect();
      }
      if (msg.event == UsbEvent.ACTION_USB_DETACHED) {
        _disconnected();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: slots.length,
        child: Scaffold(
          key: scaffoldState,
          appBar: AppBar(
            title: Text(S.of(context).chameleonMiniApp),
            bottom: TabBar(
              isScrollable: true,
              tabs: slots.map((Slot slot) {
                return Tab(
                  icon: slotIcons[slot.index],
                  text: '${S.of(context).slot} ${slot.index + 1}',
                );
              }).toList(),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.usb, color: connected ? Colors.blue : Colors.black,),
                onPressed: _connect,
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: _pushSettings,
              ),
            ],
          ),
          body: TabBarView(
            children: slots.map((Slot slot) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SlotView(slot: slot),
              );
            }).toList(),
          ),
        ),
      );
  }
}
