import 'package:flutter/material.dart';

import '../../generated/i18n.dart';

class DeviceInfoDialog extends StatefulWidget {
  DeviceInfoDialog({Key key, this.version, this.rssi,}) : super(key: key);

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
      title: Text(S.of(context).deviceInfo),
      content: Text('${widget.version}\nRSSI : ${widget.rssi}'),
      actions: <Widget>[
        FlatButton(
          child: Text(S.of(context).reset),
          onPressed: _reset,
        ),
        FlatButton(
          child: Text(S.of(context).disconnect),
          onPressed: _disconnect,
        ),
        FlatButton(
          child: Text(S.of(context).close),
          onPressed: _close,
        ),
      ],
    );
  }
}