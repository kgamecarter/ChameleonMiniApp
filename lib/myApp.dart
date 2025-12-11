import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

import 'services/settings.dart';
import 'views/home/homePage.dart';
import 'views/settings/settingsPage.dart';
import 'views/settings/languagePage.dart';

class MyApp extends StatelessWidget {
  final Settings settings;

  const MyApp({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'Chameleon Mini App',
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.chameleonMiniApp,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.lime),
              useMaterial3: true,
            ),
            home: HomePage(),
            routes: {
              SettingsPage.name: (BuildContext context) => new SettingsPage(),
              LanguagePage.name: (BuildContext context) => new LanguagePage(),
            },
            locale: settings.locale,
          ),
        );
      },
    );
  }
}
