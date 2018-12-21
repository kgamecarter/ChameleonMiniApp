import 'package:flutter/material.dart';

class Slot {
  const Slot({this.title, this.icon});

  final String title;
  final IconData icon;
}

class SlotView extends StatelessWidget {
  const SlotView({Key key, this.slot}) : super(key: key);

  final Slot slot;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Card(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(slot.icon, size: 128.0, color: textStyle.color),
            Text(slot.title, style: textStyle),
          ],
        ),
      ),
    );
  }
}