import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/i18n.dart';
import 'localizations/myLocalizationsDelegate.dart';
import 'services/settings.dart';
import 'views/home/homePage.dart';
import 'views/settings/settingsPage.dart';
import 'views/settings/languagePage.dart';

class Routes {
  final Settings settings = Settings();

  final routes = <String, WidgetBuilder>{
    SettingsPage.name: (BuildContext context) => new SettingsPage(),
    LanguagePage.name: (BuildContext context) => new LanguagePage(),
  };

  Routes() {
    runApp(
      GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: MaterialApp(
          localizationsDelegates: [
            MyLocalizationsDelegate.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: MyLocalizationsDelegate.delegate.supportedLocales,
          localeResolutionCallback: MyLocalizationsDelegate.delegate
              .resolution(fallback: Locale('en')),
          title: 'Chameleon Mini App',
          onGenerateTitle: (context) => S.of(context).chameleonMiniApp,
          theme: ThemeData(
            primarySwatch: Colors.lime,
          ),
          home: HomePage(),
          routes: routes,
          locale: settings.locale,
        ),
      ),
    );
  }
}
