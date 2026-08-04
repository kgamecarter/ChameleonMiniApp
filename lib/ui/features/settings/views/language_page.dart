import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

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
        title: new Text(AppLocalizations.of(context)!.selectLanguage),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(AppLocalizations.of(context)!.systemDefault),
            subtitle: const Text('default'),
            onTap: _pop('default'),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.english),
            subtitle: const Text('en'),
            onTap: _pop(const Locale('en')),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.traditionalChinese),
            subtitle: const Text('zh-Hant-TW'),
            onTap: _pop(
              const Locale.fromSubtags(
                languageCode: "zh",
                scriptCode: "Hant",
                countryCode: "TW",
              ),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.simplifiedChinese),
            subtitle: const Text('zh-Hans-CN'),
            onTap: _pop(
              const Locale.fromSubtags(
                languageCode: "zh",
                scriptCode: "Hans",
                countryCode: "CN",
              ),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.japanese),
            subtitle: const Text('ja'),
            onTap: _pop(const Locale('ja')),
          ),
        ],
      ),
    );
  }
}
