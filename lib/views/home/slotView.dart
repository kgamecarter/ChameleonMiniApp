import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/chameleonClient.dart';
import '../../generated/i18n.dart';

class Slot {
  Slot({this.index});

  final int index;
  String uid;
  int memorySize;
  String mode;
  String button;
  String longPressButton;
}

class SlotView extends StatefulWidget {
  SlotView({Key key, this.slot, this.client, this.modes, this.buttonModes, this.longPressButtonModes}) : super(key: key);

  final Slot slot;
  final ChameleonClient client;
  final List<String> modes, buttonModes, longPressButtonModes;

  @override
  _SlotViewState createState() => _SlotViewState();
}

class _SlotViewState extends State<SlotView> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  FocusNode uidFocusNode = FocusNode();
  _uidChanged(String str) => widget.slot.uid = str;
  _uidEditingComplete() {
    uidFocusNode.unfocus();
    print(widget.slot.uid);
  }
  _modeChanged(String str) => setState(() => widget.slot.mode = str);
  _buttonModeChanged(String str) => setState(() => widget.slot.button = str);
  _longPressButtonModeChanged(String str) => setState(() => widget.slot.longPressButton = str);

  Future<void> _refresh() async {
    var client = widget.client;
    var slot = widget.slot;
    await client.active(slot.index);
    var selectedSlot = await client.getActive();
    if (selectedSlot != slot.index)
      return;
    var uid = await client.getUid();
    var mode = await client.getMode();
    var button = await client.getButton();
    String longPressButton;
    if (widget.longPressButtonModes != null)
      longPressButton = await client.getLongPressButton();
    var memorySize = await client.getMemorySize();
    setState(() {
      slot.uid = uid;
      slot.mode = mode;
      slot.button = button;
      slot.longPressButton = longPressButton;
      slot.memorySize = memorySize;
    });
  }
  
  Future<void> _apply() async {
    var client = widget.client;
    var slot = widget.slot;
    await client.active(slot.index);
    var selectedSlot = await client.getActive();
    if (selectedSlot != slot.index)
      return;
    await client.setMode(slot.mode);
    await client.setButton(slot.button);
    if (widget.longPressButtonModes != null)
      await client.setLongPressButton(slot.longPressButton);
    await client.setUid(slot.uid);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      top: false,
      bottom: false,
      child: Form(
        key: _formKey,
        autovalidate: true,
        child: ListView(
          children: <Widget>[
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.functions),
                    labelText: S.of(context).mode,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      disabledHint: Text(S.of(context).notAvailable),
                      value: widget.slot.mode,
                      isDense: true,
                      items: widget.modes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList(),
                      onChanged: _modeChanged,
                    ),
                  ),
                );
              },
            ),
            TextField(
              enabled: widget.modes != null,
              focusNode: uidFocusNode,
              controller: TextEditingController(text: widget.slot.uid),
              decoration: InputDecoration(
                icon: const Icon(Icons.fingerprint),
                labelText: S.of(context).uid,
              ),
              keyboardType: TextInputType.text,
              inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter(RegExp(r'^[0-9a-fA-F]{0,14}')),
              ],
              onChanged: _uidChanged,
              onEditingComplete: _uidEditingComplete,
            ),
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.touch_app),
                    labelText: S.of(context).button,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      disabledHint: Text(S.of(context).notAvailable),
                      value: widget.slot.button,
                      isDense: true,
                      items: widget.buttonModes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList(),
                      onChanged: _buttonModeChanged,
                    ),
                  ),
                );
              },
            ),
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.touch_app),
                    labelText: S.of(context).longPressButton,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      disabledHint: Text(S.of(context).notAvailable),
                      value: widget.slot.longPressButton,
                      isDense: true,
                      items: widget.longPressButtonModes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList(),
                      onChanged: _longPressButtonModeChanged,
                    ),
                  ),
                );
              },
            ),
            TextField(
              enabled: false,
              controller: TextEditingController(text: widget.slot.memorySize?.toString()),
              decoration: InputDecoration(
                icon: const Icon(Icons.memory),
                labelText: S.of(context).memorySize,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).refresh),
                      onPressed: widget.modes == null ? null : _refresh,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: FlatButton(
                      color: Colors.lime,
                      disabledColor: Colors.grey,
                      child: Text(S.of(context).apply),
                      onPressed: widget.modes == null ? null : _apply,
                    ),
                  ),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}