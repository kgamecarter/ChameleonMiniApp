import 'package:flutter/material.dart';

import '../../generated/i18n.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  final Settings settings = Settings();

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).settings),
      ),
      body: bodyData(),
    );
  }

  String _localToString(Locale local) {
    if (local == null)
      return S.of(context).systemDefault;
    if (local.languageCode == 'en')
      return S.of(context).english;
    if (local.languageCode == 'zh') {
      if (local.countryCode == 'TW')
        return S.of(context).traditionalChinese;
    }
  }

  Widget bodyData() {
    return SingleChildScrollView(
      child: Theme(
        data: ThemeData(
          fontFamily: 'Raleway'
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            //1
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                S.of(context).generalSetting,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            Card(
              color: Colors.white,
              elevation: 2.0,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Colors.grey,
                    ),
                    title: Text(S.of(context).language),
                    subtitle: Text(_localToString(widget.settings.locale)),
                    trailing: Icon(Icons.arrow_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/Settings/Language').then((value) {
                        if (value == null)
                          return;
                        if (value == 'default')
                          setState(() => widget.settings.locale = null);
                        setState(() => widget.settings.locale = value);
                      });
                    },
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class Settings {
  Locale locale = Locale('zh', 'TW');
}