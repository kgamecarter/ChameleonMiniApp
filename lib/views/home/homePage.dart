import 'package:flutter/material.dart';
import '../../generated/i18n.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  _pushSettings() {
    Navigator.of(context).pushNamed('/Settings');
  }

  @override
  Widget build(BuildContext context) {
    if (slots == null) {
      slots = <Slot>[
        Slot(title: '${S.of(context).slot} 1', icon: Icons.filter_1),
        Slot(title: '${S.of(context).slot} 2', icon: Icons.filter_2),
        Slot(title: '${S.of(context).slot} 3', icon: Icons.filter_3),
        Slot(title: '${S.of(context).slot} 4', icon: Icons.filter_4),
        Slot(title: '${S.of(context).slot} 5', icon: Icons.filter_5),
        Slot(title: '${S.of(context).slot} 6', icon: Icons.filter_6),
        Slot(title: '${S.of(context).slot} 7', icon: Icons.filter_7),
        Slot(title: '${S.of(context).slot} 8', icon: Icons.filter_8),
      ];
    }
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.orange,
        accentColor: Colors.white
      ),
      home: DefaultTabController(
        length: slots.length,
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).chameleonMiniApp),
            bottom: TabBar(
              isScrollable: true,
              tabs: slots.map((Slot choice) {
                return Tab(
                  text: choice.title,
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
      ),
    );
  }
}

class Slot {
  const Slot({this.title, this.icon});

  final String title;
  final IconData icon;
}

List<Slot> slots;

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