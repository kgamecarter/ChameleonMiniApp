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

  var routes = <String, WidgetBuilder>{
    '/Settings': (BuildContext context) => new SettingsPage(),
    '/Settings/Language': (BuildContext context) => new LanguagePage(),
  };

  Routes() {
    runApp(MaterialApp(
      localizationsDelegates: [
        MyLocalizationsDelegate.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: MyLocalizationsDelegate.delegate.supportedLocales,
      localeResolutionCallback: MyLocalizationsDelegate.delegate.resolution(fallback: Locale('en', '')),
      title: 'Chameleon Mini App',
      theme: ThemeData(
        primarySwatch: Colors.lime,
      ),
      home: HomePage(),
      routes: routes,
      locale: settings.locale,
    ));
  }
}