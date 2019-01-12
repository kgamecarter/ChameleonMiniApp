import 'package:flutter/material.dart';

import '../../services/settings.dart';
import '../../generated/i18n.dart';
import 'languagePage.dart';

class SettingsPage extends StatefulWidget {
  static const String name = '/Settings/Language';

  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  GlobalKey<ScaffoldState> scaffoldState = new GlobalKey<ScaffoldState>();

  final Settings settings = Settings();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldState,
      appBar: new AppBar(
        title: new Text(S.of(context).settings),
      ),
      body: bodyData(),
    );
  }

  String _localToString(Locale locale) {
    if (locale == null)
      return S.of(context).systemDefault;
    if (locale.languageCode == 'en')
      return S.of(context).english;
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant')
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
                      Navigator.of(context).pushNamed(LanguagePage.name).then((value) {
                        if (value == null)
                          return;
                        if (value == 'default')
                          value = null;
                        S.delegate.load(value).then((trans) {
                          scaffoldState.currentState.showSnackBar(SnackBar(
                            content: Text(trans.effectiveAfterRestartingTheApp),
                          ));
                        });
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
