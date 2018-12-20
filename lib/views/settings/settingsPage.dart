import 'package:flutter/material.dart';

import '../../services/settings.dart';
import '../../generated/i18n.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final Settings settings = Settings();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).settings),
      ),
      body: bodyData(),
    );
  }

  String _localToString(Locale locale) {
    print(locale);
    if (locale == null)
      return S.of(context).systemDefault;
    if (locale.languageCode == 'en')
      return S.of(context).english;
    if (locale.languageCode == 'zh') {
      if (locale.countryCode == 'TW')
        return S.of(context).traditionalChinese;
    }
    return null;
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
                    subtitle: Text(_localToString(settings.locale)),
                    trailing: Icon(Icons.arrow_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/Settings/Language').then((value) {
                        if (value == null)
                          return;
                        if (value == 'default')
                          value = null;
                        setState(() {
                          settings.locale = value;
                          settings.save();
                        });
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
