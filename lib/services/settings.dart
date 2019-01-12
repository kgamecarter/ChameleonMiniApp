import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  SharedPreferences _prefs;
  static final Settings _settings = Settings._internal();
  Locale locale;

  factory Settings() {
    return _settings;
  }

  Settings._internal();

  load() async {
    if (_prefs == null)
      _prefs = await SharedPreferences.getInstance();
    String str = _prefs.getString('locale');
    if (str == 'en_')
      locale = Locale('en');
    else if (str == 'zh_Hant_TW')
      locale = Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant", countryCode: "TW");
    else
      locale = null;
  }

  save() async {
    await _prefs.setString('locale', locale == null ? null : locale.toString());
  }
}