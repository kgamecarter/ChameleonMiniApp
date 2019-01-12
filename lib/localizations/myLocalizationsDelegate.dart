import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../generated/i18n.dart';

class MyLocalizationsDelegate extends LocalizationsDelegate<S> {
  static MyLocalizationsDelegate delegate = MyLocalizationsDelegate._internal();
  
  const MyLocalizationsDelegate._internal();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant", countryCode: "TW"),
      Locale("zh", "TW"),
      Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant"),
      Locale("zh"),
      Locale("en"),
    ];
  }

  LocaleListResolutionCallback listResolution({Locale fallback}) {
    return (List<Locale> locales, Iterable<Locale> supported) {
      if (locales == null || locales.isEmpty) {
        return fallback ?? supported.first;
      } else {
        return _resolve(locales.first, fallback, supported);
      }
    };
  }

  LocaleResolutionCallback resolution({Locale fallback}) {
    return (Locale locale, Iterable<Locale> supported) {
      return _resolve(locale, fallback, supported);
    };
  }

  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported) {
    if (locale == null)
      return fallback ?? supported.first;

    if (supported.contains(locale)) // maybe languageCode-scriptCode-countryCode
      return locale;

    var superLocale = Locale(locale.languageCode, locale.countryCode); // languageCode-countryCode
    if (supported.contains(superLocale))
      return superLocale;

    superLocale = Locale.fromSubtags(languageCode: locale.languageCode, scriptCode: locale.scriptCode); // languageCode-scriptCode
    if (supported.contains(superLocale))
      return superLocale;

    superLocale = Locale(locale.languageCode);  // languageCode
    if (supported.contains(superLocale))
      return superLocale;

    return fallback ?? supported.first;
  }

  @override
  Future<S> load(Locale locale) {
    final String lang = locale.toString();
    if (lang != null) {
      switch (lang) {
        case "zh_Hant_TW":
        case "zh_TW":
        case "zh_Hant":
        case "zh":
          return SynchronousFuture<S>(const $zh_TW());
        case "en":
          return SynchronousFuture<S>(const $en());
        default:
          // NO-OP.
      }
    }
    return SynchronousFuture<S>(const S());
  }

  @override
  bool isSupported(Locale locale) =>
    locale != null && _resolve(locale, null, supportedLocales) != null;

  @override
  bool shouldReload(MyLocalizationsDelegate old) => false;
}
