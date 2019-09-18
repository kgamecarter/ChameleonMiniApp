import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  SharedPreferences _prefs;
  static final Settings _settings = Settings._internal();
  Locale locale;
  Crapto1Implementation crapto1Implementation;

  factory Settings() {
    return _settings;
  }

  Settings._internal();

  load() async {
    if (_prefs == null)
      _prefs = await SharedPreferences.getInstance();
    String str = _prefs.getString('locale');
    if (str == 'en')
      locale = Locale('en');
    else if (str == 'zh_Hant_TW')
      locale = Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant", countryCode: "TW");
    else
      locale = null;
    int v = _prefs.getInt('crapto1Implementation');
    if (v == null)
      v = 1;
    crapto1Implementation = Crapto1Implementation.values[v];
  }

  save() async {
    await _prefs.setString('locale', locale?.toString());
    await _prefs.setInt('crapto1Implementation', crapto1Implementation?.index);
  }
}

enum Crapto1Implementation {
   Dart,
   Java
}
