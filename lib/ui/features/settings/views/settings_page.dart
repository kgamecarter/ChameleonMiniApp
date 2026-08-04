import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

import '../../../../domain/models/crapto1_implementation.dart';
import '../view_models/settings_view_model.dart';
import 'language_page.dart';

class SettingsPage extends StatefulWidget {
  static const String name = '/Settings/Language';

  const SettingsPage({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
        body: bodyData(),
      ),
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
      case Crapto1Implementation.dart:
        return AppLocalizations.of(context)!.crapto1Dart;
      case Crapto1Implementation.java:
        return AppLocalizations.of(context)!.crapto1Java;
      case Crapto1Implementation.online:
        return AppLocalizations.of(context)!.crapto1Online;
      case Crapto1Implementation.native:
        return AppLocalizations.of(context)!.crapto1Native;
    }
  }

  void _pushLanguagePage() async {
    var value = await Navigator.of(context).pushNamed(LanguagePage.name);
    print(value);
    if (value == null) return;

    await widget.viewModel.setLocale(
      value == 'default' ? null : value as Locale,
    );
  }

  void _showCrapto1ImplementationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.crapto1Implementation),
        children: <Widget>[
          RadioGroup<Crapto1Implementation>(
            groupValue: widget.viewModel.crapto1Implementation,
            onChanged: _selectCrapto1Implementation,
            child: Column(
              children: [
                RadioListTile<Crapto1Implementation>(
                  selected:
                      widget.viewModel.crapto1Implementation ==
                      Crapto1Implementation.dart,
                  value: Crapto1Implementation.dart,
                  title: Text(
                    _crapto1ImplementationToString(Crapto1Implementation.dart),
                  ),
                ),
                RadioListTile<Crapto1Implementation>(
                  selected:
                      widget.viewModel.crapto1Implementation ==
                      Crapto1Implementation.java,
                  value: Crapto1Implementation.java,
                  title: Text(
                    _crapto1ImplementationToString(Crapto1Implementation.java),
                  ),
                ),
                RadioListTile<Crapto1Implementation>(
                  selected:
                      widget.viewModel.crapto1Implementation ==
                      Crapto1Implementation.native,
                  value: Crapto1Implementation.native,
                  title: Text(
                    _crapto1ImplementationToString(
                      Crapto1Implementation.native,
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

  Future<void> _selectCrapto1Implementation(
    Crapto1Implementation? value,
  ) async {
    if (value == null) return;
    await widget.viewModel.setCrapto1Implementation(value);
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
                subtitle: Text(_localToString(widget.viewModel.locale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pushLanguagePage,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.functions),
                title: Text('Crapto1 & mfkey32 implementation'),
                subtitle: Text(
                  _crapto1ImplementationToString(
                    widget.viewModel.crapto1Implementation!,
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
