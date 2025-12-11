import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

class DeviceInfoDialog extends StatelessWidget {
  const DeviceInfoDialog(this.version, this.rssi, {Key? key}) : super(key: key);

  final String version, rssi;

  void _reset(BuildContext context) {
    Navigator.of(context).pop('reset');
  }

  void _disconnect(BuildContext context) {
    Navigator.of(context).pop('disconnect');
  }

  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.deviceInfo),
      content: Text('$version\nRSSI : $rssi'),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.reset),
          onPressed: () => _reset(context),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.disconnect),
          onPressed: () => _disconnect(context),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.close),
          onPressed: () => _close(context),
        ),
      ],
    );
  }
}
