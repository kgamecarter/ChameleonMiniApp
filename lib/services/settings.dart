import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  SharedPreferences? _prefs;
  static final Settings _settings = Settings._internal();
  Locale? locale;
  Crapto1Implementation? crapto1Implementation;

  factory Settings() {
    return _settings;
  }

  Settings._internal();

  load() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    String? str = _prefs!.getString('locale');
    if (str == 'en')
      locale = Locale('en');
    else if (str == 'zh_Hant_TW')
      locale = Locale.fromSubtags(
          languageCode: "zh", scriptCode: "Hant", countryCode: "TW");
    else
      locale = null;
    int? v = _prefs!.getInt('crapto1Implementation');
    if (v == null) {
      if (Platform.isAndroid) {
        if (Platform.version.contains('arm64')) {
          v = 3;
        } else {
          v = 1;
        }
      } else {
        v = 0;
      }
    }
    crapto1Implementation = Crapto1Implementation.values[v];
  }

  save() async {
    if (locale != null) {
      await _prefs!.setString('locale', locale!.toString());
    } else {
      await _prefs!.remove('locale');
    }
    if (crapto1Implementation != null) {
      await _prefs!
          .setInt('crapto1Implementation', crapto1Implementation!.index);
    }
  }
}

enum Crapto1Implementation {
  Dart,
  Java,
  Online,
  Native,
}
