import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

import '../../services/settings.dart';
import 'languagePage.dart';

class SettingsPage extends StatefulWidget {
  static const String name = '/Settings/Language';

  SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Settings settings = Settings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: bodyData(),
    );
  }

  String _localToString(Locale? locale) {
    if (locale?.languageCode == 'en')
      return AppLocalizations.of(context)!.english;
    if (locale?.languageCode == 'zh') {
      if (locale?.scriptCode == 'Hant')
        return AppLocalizations.of(context)!.traditionalChinese;
    }
    return AppLocalizations.of(context)!.systemDefault;
  }

  String _crapto1ImplementationToString(
    Crapto1Implementation crapto1implementation,
  ) {
    switch (crapto1implementation) {
      case Crapto1Implementation.Dart:
        return 'Dart with Single-Thread';
      case Crapto1Implementation.Java:
        return 'Java with Multi-Thread';
      case Crapto1Implementation.Online:
        return 'Online (Server maybe offline)';
      case Crapto1Implementation.Native:
        return '.NET8 NativeAOT (ARM64 only)';
    }
  }

  void _pushLanguagePage() async {
    var value = await Navigator.of(context).pushNamed(LanguagePage.name);
    print(value);
    if (value == null) return;

    setState(() {
      settings.locale = value == 'default' ? null : value as Locale;
    });
  }

  void _showCrapto1ImplementationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text('Select implementation'),
        children: <Widget>[
          RadioGroup<Crapto1Implementation>(
            groupValue: settings.crapto1Implementation,
            onChanged: _selectCrapto1Implementation,
            child: Column(
              children: [
                RadioListTile<Crapto1Implementation>(
                  selected:
                      settings.crapto1Implementation ==
                      Crapto1Implementation.Dart,
                  value: Crapto1Implementation.Dart,
                  title: Text(
                    _crapto1ImplementationToString(Crapto1Implementation.Dart),
                  ),
                ),
                RadioListTile<Crapto1Implementation>(
                  selected:
                      settings.crapto1Implementation ==
                      Crapto1Implementation.Java,
                  value: Crapto1Implementation.Java,
                  title: Text(
                    _crapto1ImplementationToString(Crapto1Implementation.Java),
                  ),
                ),
                RadioListTile<Crapto1Implementation>(
                  selected:
                      settings.crapto1Implementation ==
                      Crapto1Implementation.Native,
                  value: Crapto1Implementation.Native,
                  title: Text(
                    _crapto1ImplementationToString(
                      Crapto1Implementation.Native,
                    ),
                  ),
                  enabled: Platform.version.contains('arm64'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectCrapto1Implementation(Crapto1Implementation? value) {
    setState(() {
      settings.crapto1Implementation = value!;
    });
    Navigator.pop(context);
  }

  Widget bodyData() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            AppLocalizations.of(context)!.generalSetting,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 2.0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.language),
                subtitle: Text(_localToString(settings.locale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pushLanguagePage,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.functions),
                title: Text('Crapto1 & mfkey32 implementation'),
                subtitle: Text(
                  _crapto1ImplementationToString(
                    settings.crapto1Implementation!,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showCrapto1ImplementationDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
