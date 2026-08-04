import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../../../domain/models/slot.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/home_view_model.dart';
import 'device_info_dialog.dart';
import 'slot_view.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';
import '../../settings/views/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.viewModel,
    required this.settingsViewModel,
  });

  final HomeViewModel viewModel;
  final SettingsViewModel settingsViewModel;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _channel = const MethodChannel('tw.kgame.crapto1/main');
  StreamSubscription<UsbEvent>? _usbEventSubscription;

  static const _slotIcons = <Icon>[
    Icon(Icons.filter_1),
    Icon(Icons.filter_2),
    Icon(Icons.filter_3),
    Icon(Icons.filter_4),
    Icon(Icons.filter_5),
    Icon(Icons.filter_6),
    Icon(Icons.filter_7),
    Icon(Icons.filter_8),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.viewModel.slots.length,
      vsync: this,
    );
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewIntent' &&
          call.arguments == 'android.hardware.usb.action.USB_DEVICE_ATTACHED') {
        await _connect();
      }
    });
    _usbEventSubscription = UsbSerial.usbEventStream?.listen((event) {
      if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        _disconnect(showFeedback: mounted);
      }
    });
    _connect();
  }

  @override
  void dispose() {
    _usbEventSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _pushSettings() => Navigator.of(context).pushNamed(SettingsPage.name);

  Future<void> _disconnect({bool showFeedback = false}) async {
    await widget.viewModel.disconnect();
    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.usbDisconnected),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _connect() async {
    if (widget.viewModel.connected) {
      final version = widget.viewModel.version;
      if (version == null) return;
      final rssi = await widget.viewModel.getRssi();
      final result = await showDialog<String>(
        context: context,
        builder: (_) => DeviceInfoDialog(version, rssi),
      );
      if (result == 'disconnect') await _disconnect();
      if (result == 'reset') widget.viewModel.reset();
      return;
    }

    final connected = await widget.viewModel.connect();
    if (!connected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.usbDeviceNotFound),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;
        final slots = viewModel.slots;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.chameleonMiniApp),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: slots
                  .map(
                    (Slot slot) => Tab(
                      icon: _slotIcons[slot.index],
                      text:
                          '${AppLocalizations.of(context)!.slot} ${slot.index + 1}',
                    ),
                  )
                  .toList(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.usb,
                  color: viewModel.connected ? Colors.blue : null,
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
            children: slots
                .map(
                  (slot) => SlotView(
                    slot: slot,
                    repository: viewModel.repository,
                    settingsViewModel: widget.settingsViewModel,
                    connected: viewModel.connected,
                    modes: viewModel.modes,
                    buttonModes: viewModel.buttonModes,
                    longPressButtonModes: viewModel.longPressButtonModes,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
