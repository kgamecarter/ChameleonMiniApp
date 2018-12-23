import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
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
                    icon: Icon(Icons.functions),
                    labelText: S.of(context).mode,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.slot.mode,
                      isDense: true,
                      items: widget.modes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList() ?? <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED'),),
                      ],
                      onChanged: _modeChanged,
                    ),
                  ),
                );
              },
            ),
            TextField(
              focusNode: uidFocusNode,
              controller: TextEditingController(text: widget.slot.uid),
              decoration: InputDecoration(
                icon: Icon(Icons.fingerprint),
                labelText: S.of(context).uid,
              ),
              keyboardType: TextInputType.text,
              inputFormatters: [
                WhitelistingTextInputFormatter(RegExp(r'^[0-9a-fA-F]{0,7}')),
              ],
              onChanged: _uidChanged,
              onEditingComplete: _uidEditingComplete,
            ),
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    icon: Icon(Icons.short_text),
                    labelText: S.of(context).button,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.slot.button,
                      isDense: true,
                      items: widget.buttonModes?.map((str) => DropdownMenuItem(value: str, child: Text(str)))?.toList() ?? <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED'),),
                      ],
                      onChanged: _buttonModeChanged,
                    ),
                  ),
                );
              },
            ),
            TextField(
              enabled: false,
              controller: TextEditingController(text: widget.slot.memorySize?.toString()),
              decoration: InputDecoration(
                icon: Icon(Icons.memory),
                labelText: S.of(context).memorySize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}