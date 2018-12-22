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
    _prefs = await SharedPreferences.getInstance();
    String str = _prefs.getString('locale');
    if (str == 'en_')
      locale = Locale('en');
    if (str == 'zh_TW')
      locale = Locale('zh', 'TW');
  }

  save() async {
    await _prefs.setString('locale', locale == null ? null : locale.toString());
  }
}