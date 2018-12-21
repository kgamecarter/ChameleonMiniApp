import 'package:flutter/material.dart';

import 'slotView.dart';
import '../../generated/i18n.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Slot> slots;

  _pushSettings() {
    Navigator.of(context).pushNamed('/Settings');
  }

  @override
  Widget build(BuildContext context) {
    if (slots == null) {
      slots = <Slot>[
        Slot(index: 0),
        Slot(index: 1),
        Slot(index: 2),
        Slot(index: 3),
        Slot(index: 4),
        Slot(index: 5),
        Slot(index: 6),
        Slot(index: 7),
      ];
    }
    return DefaultTabController(
        length: slots.length,
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).chameleonMiniApp),
            bottom: TabBar(
              isScrollable: true,
              tabs: slots.map((Slot slot) {
                return Tab(
                  text: '${S.of(context).slot} ${slot.index + 1}',
                );
              }).toList(),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: _pushSettings,
              )
            ],
          ),
          body: TabBarView(
            children: slots.map((Slot slot) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SlotView(slot: slot),
              );
            }).toList(),
          ),
        ),
      );
  }
}
