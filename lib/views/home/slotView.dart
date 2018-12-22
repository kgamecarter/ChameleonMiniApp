import 'package:flutter/material.dart';

import '../../generated/i18n.dart';

class Slot {
  Slot({this.index});

  final int index;
  String uid;
  int memorySize;
  String mode = "CLOSED";
  String button = "CLOSED";
  String longPressButton = "CLOSED";
}

class SlotView extends StatefulWidget {
  SlotView({Key key, this.slot, this.modes, this.buttonModes}) : super(key: key);

  final Slot slot;
  final List<String> modes, buttonModes;

  @override
  _SlotViewState createState() => _SlotViewState();
}

class _SlotViewState extends State<SlotView> {
  FocusNode uidFocusNode = FocusNode();
  _uidChanged(String str) => widget.slot.uid = str;
  _uidEditingComplete() {
    uidFocusNode.unfocus();
    print(widget.slot.uid);
  }
  _modeChanged(String str) => setState(() => widget.slot.mode = str);
  _buttonModeChanged(String str) => setState(() => widget.slot.button = str);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            SizedBox(height: 16,),
            TextField(
              focusNode: uidFocusNode,
              controller: TextEditingController(text: widget.slot.uid),
              decoration: InputDecoration(
                labelText: S.of(context).uid,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              ),
              keyboardType: TextInputType.text,
              onChanged: _uidChanged,
              onEditingComplete: _uidEditingComplete,
            ),
            ListTile(
              title: Text(S.of(context).mode),
              trailing: DropdownButton(
                value: widget.slot.mode,
                items: widget.modes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList() ?? <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED'),),
                ],
                onChanged: _modeChanged,
              ),
            ),
            ListTile(
              title: Text(S.of(context).button),
              trailing: DropdownButton(
                value: widget.slot.button,
                items: widget.buttonModes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList() ?? <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED'),),
                ],
                onChanged: _buttonModeChanged,
              ),
            ),
            ListTile(
              title: Text(S.of(context).memorySize),
              trailing: Text(widget.slot.memorySize.toString()),
            ),
          ],
        ),
      ),
    );
  }
}