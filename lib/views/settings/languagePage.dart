import 'package:flutter/material.dart';

import '../../generated/i18n.dart';

class LanguagePage extends StatefulWidget {
  static const String name = '/Settings';

  LanguagePage({Key? key}) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {

  Function() _pop(Object value) {
    return () => Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).selectLanguage),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(S.of(context).systemDefault),
            subtitle: const Text('default'),
            onTap: _pop('default'),
          ),
          ListTile(
            title: Text(S.of(context).english),
            subtitle: const Text('en'),
            onTap: _pop(const Locale('en')),
          ),
          ListTile(
            title: Text(S.of(context).traditionalChinese),
            subtitle: const Text('zh-Hant-TW'),
            onTap: _pop(const Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant", countryCode: "TW")),
          ),
        ],
      )
    );
  }
}