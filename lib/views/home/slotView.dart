import 'package:flutter/material.dart';

import '../../generated/i18n.dart';

class Slot {
  Slot({this.index});

  final int index;
  String mode = "NONE";
  String uid = "12345678";
  String button = "NONE";
}

class SlotView extends StatefulWidget {
  SlotView({Key key, this.slot}) : super(key: key);

  final Slot slot;

  @override
  _SlotViewState createState() => _SlotViewState();
}

class _SlotViewState extends State<SlotView> {

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            TextField(
              controller: TextEditingController(text: widget.slot.uid),
              decoration: InputDecoration(
                labelText: S.of(context).uid,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              ),
              keyboardType: TextInputType.text,
              onChanged: (str) {
                widget.slot.uid = str;
              },
            ),
            ListTile(
              title: Text(S.of(context).mode),
              trailing: DropdownButton(
                value: widget.slot.mode,
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'NONE', child: Text('NONE'),),
                  DropdownMenuItem(value: 'MF_DETECTOIN', child: Text('MF_DETECTOIN'),),
                ],
                onChanged: (str) {
                  setState(() {
                    widget.slot.mode = str;
                  });
                },
              ),
            ),
            ListTile(
              title: Text(S.of(context).button),
              trailing: DropdownButton(
                value: widget.slot.button,
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'NONE', child: Text('NONE'),),
                  DropdownMenuItem(value: 'SWITCH_CARD', child: Text('SWITCH_CARD'),),
                ],
                onChanged: (str) {
                  setState(() {
                    widget.slot.button = str;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}