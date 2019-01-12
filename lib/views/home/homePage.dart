import 'dart:async';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../services/chameleonClient.dart';
import 'slotView.dart';
import '../../generated/i18n.dart';
import '../settings/settingsPage.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  GlobalKey<ScaffoldState> scaffoldState = GlobalKey<ScaffoldState>();

  final ChameleonClient client = ChameleonClient();
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

  void _pushSettings() {
    Navigator.of(context).pushNamed(SettingsPage.name);
  }

  Future<void> _disconnected() async {
    await client.close();
    setState(() {
      version = null;
      commands = null;
      modes = null;
      buttonModes = null;
      longPressButtonModes = null;
      for (var slot in slots) {
        slot.uid = null;
        slot.memorySize = null;
        slot.mode = null;
        slot.button = null;
        slot.longPressButton = null;
      }
    });
    scaffoldState.currentState.showSnackBar(SnackBar(
      content: Text(S.of(context).usbDisconnected),
      duration: Duration(seconds: 10),
    ));
  }

   Future<void> _connect() async {
    if (client.connected) {
      await _disconnected();
      return;
    }
    List<UsbDevice> devices = await UsbSerial.listDevices();
    print(devices);

    if (devices.length == 0) {
      scaffoldState.currentState.showSnackBar(SnackBar(
        content: Text(S.of(context).usbDeviceNotFound),
        duration: Duration(seconds: 3),
      ));
      return;
    } 
    var port = await devices[0].create();
    
    bool openResult = await port.open();
    if ( !openResult ) {
      print("Failed to open");
      return;
    }
    
    await port.setDTR(true);
    await port.setRTS(true);

    port.setPortParameters(115200, UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    client.port = port;
    version = await client.version();
    commands = await client.getCommands();
    modes = await client.getModes();
    buttonModes = await client.getButtonModes();
    try {
      longPressButtonModes = await client.getLongPressButtonModes();
    } catch (e) { }
    slots = await client.refreshAll();
    setState(() => client.connected);
  }

  String version;
  List<String> commands, modes, buttonModes, longPressButtonModes;
  StreamSubscription<UsbEvent> usbEventStreamSubscription;

  @override
  void initState() {
    super.initState();

    usbEventStreamSubscription = UsbSerial.usbEventStream.listen((UsbEvent msg) {
      print("Usb Event $msg");
      if (msg.event == UsbEvent.ACTION_USB_ATTACHED) {
        _connect();
      }
      if (msg.event == UsbEvent.ACTION_USB_DETACHED) {
        _disconnected();
      }
    });
    _connect();
  }

  @override
  void dispose() {
    usbEventStreamSubscription?.cancel();
    super.dispose();
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
              icon: Icon(Icons.usb, color: client.connected ? Colors.blue : Colors.black,),
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
            return SlotView(
              slot: slot,
              client: client,
              modes: modes,
              buttonModes: buttonModes,
              longPressButtonModes: longPressButtonModes,
            );
          }).toList(),
        ),
      ),
    );
  }
}
