import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

class DeviceInfoDialog extends StatefulWidget {
  DeviceInfoDialog(
    this.version,
    this.rssi, {
    Key? key,
  }) : super(key: key);

  final String version, rssi;

  @override
  _DeviceInfoDialogState createState() => _DeviceInfoDialogState();
}

class _DeviceInfoDialogState extends State<DeviceInfoDialog> {
  _reset() {
    Navigator.of(context).pop('reset');
  }

  _disconnect() {
    Navigator.of(context).pop('disconnect');
  }

  _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.deviceInfo),
      content: Text('${widget.version}\nRSSI : ${widget.rssi}'),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.reset),
          onPressed: _reset,
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.disconnect),
          onPressed: _disconnect,
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.close),
          onPressed: _close,
        ),
      ],
    );
  }
}
