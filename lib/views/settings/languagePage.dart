import 'package:flutter/material.dart';

import '../../generated/i18n.dart';

class LanguagePage extends StatefulWidget {
  LanguagePage({Key key}) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {

  @override
  Widget build(BuildContext context) {
    return  new Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).selectLanguage),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(S.of(context).systemDefault),
            subtitle: Text('default'),
            onTap: () => Navigator.of(context).pop('default'),
          ),
          ListTile(
            title: Text(S.of(context).english),
            subtitle: Text('en'),
            onTap: () => Navigator.of(context).pop(Locale('en')),
          ),
          ListTile(
            title: Text(S.of(context).traditionalChinese),
            subtitle: Text('zh-TW'),
            onTap: () => Navigator.of(context).pop(Locale('zh', 'TW')),
          ),
        ],
      )
    );
  }
}