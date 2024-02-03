import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../services/chameleonClient.dart';
import 'slotView.dart';
import 'deviceInfoDialog.dart';
import '../../generated/i18n.dart';
import '../settings/settingsPage.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  GlobalKey<ScaffoldMessengerState> scaffoldState =
      GlobalKey<ScaffoldMessengerState>();
  final channel = const MethodChannel('tw.kgame.crapto1/main');

  final ChameleonClient client = ChameleonClient();
  List<Slot> slots = <Slot>[
    Slot(0),
    Slot(1),
    Slot(2),
    Slot(3),
    Slot(4),
    Slot(5),
    Slot(6),
    Slot(7),
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
    scaffoldState.currentState?.showSnackBar(SnackBar(
      content: Text(S.of(context).usbDisconnected),
      duration: Duration(seconds: 10),
    ));
  }

  Future<void> _connect() async {
    if (client.connected) {
      var rssi = await client.getRssi();
      var result = await showDialog(
        context: context,
        builder: (_) => DeviceInfoDialog(
          version!,
          rssi,
        ),
      );
      if (result == 'disconnect') {
        await _disconnected();
      } else if (result == 'reset') {
        client.reset();
      }
      return;
    }
    List<UsbDevice> devices = await UsbSerial.listDevices();
    print(devices);

    if (devices.length == 0) {
      scaffoldState.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).usbDeviceNotFound),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    var port = await devices[0].create();

    if (port == null) {
      print("Failed to create");
      return;
    }

    bool openResult = await port.open();
    if (!openResult) {
      print("Failed to open");
      return;
    }

    await port.setDTR(true);
    await port.setRTS(true);

    port.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    client.port = port;
    await client.checkCommand();
    version = await client.getVersion();
    commands = await client.getCommands();
    modes = await client.getModes();
    buttonModes = await client.getButtonModes();
    try {
      longPressButtonModes = await client.getLongPressButtonModes();
    } catch (e) {}
    slots = await client.refreshAll();
    setState(() => client.connected);
  }

  String? version;
  List<String>? commands, modes, buttonModes, longPressButtonModes;
  StreamSubscription<UsbEvent>? usbEventStreamSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: slots.length, vsync: this);

    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onNewIntent':
          if (call.arguments ==
              'android.hardware.usb.action.USB_DEVICE_ATTACHED') _connect();
          break;
        default:
          break;
      }
    });

    usbEventStreamSubscription =
        UsbSerial.usbEventStream?.listen((UsbEvent msg) {
      print("Usb Event $msg");
      if (msg.event == UsbEvent.ACTION_USB_DETACHED) {
        _disconnected();
      }
    });
    _connect();
  }

  @override
  void dispose() {
    usbEventStreamSubscription?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        title: Text(S.of(context).chameleonMiniApp),
        bottom: TabBar(
          controller: _tabController,
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
            icon: Icon(
              Icons.usb,
              color: client.connected ? Colors.blue : null,
            ),
            onPressed: _connect,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _pushSettings,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: slots.map((Slot slot) {
          return SlotView(
            slot,
            client,
            modes: modes,
            buttonModes: buttonModes,
            longPressButtonModes: longPressButtonModes,
          );
        }).toList(),
      ),
    );
  }
}
