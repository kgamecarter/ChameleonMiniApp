import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../services/chameleonClient.dart';
import 'slotView.dart';
import '../../generated/i18n.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  GlobalKey<ScaffoldState> scaffoldState = new GlobalKey<ScaffoldState>();

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
  bool connected = false;

  _pushSettings() {
    Navigator.of(context).pushNamed('/Settings');
  }

  _disconnected() async {
    await client.close();
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
    await refreshAll();
    setState(() => connected = true);
  }

  String version;
  List<String> commands, modes, buttonModes, longPressButtonModes;

  Future<void> refreshAll() async {
    var selectedSlot = await client.getActive();
    version = await client.version();
    commands = await client.getCommands();
    modes = await client.getModes();
    buttonModes = await client.getButtonModes();
    for (int i = 0; i < 8; i++)
      await refresh(i);
    await client.active(selectedSlot);
  }

  Future<void> refresh(int i) async {
    await client.active(i);
    var selectedSlot = await client.getActive();
    if (selectedSlot != i)
      return;
    var uid = await client.getUid();
    var mode = await client.getMode();
    var button = await client.getButton();
    var slot = slots[i];
    setState(() {
      slot.uid = uid;
      slot.mode = mode;
      slot.button = button;
    });
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
                child: SlotView(
                  slot: slot,
                  modes: modes,
                  buttonModes: buttonModes,
                ),
              );
            }).toList(),
          ),
        ),
      );
  }
}
