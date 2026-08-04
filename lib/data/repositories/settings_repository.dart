import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/crapto1_implementation.dart';

class SettingsRepository {
  SettingsRepository({SharedPreferences? preferences}) : _prefs = preferences;

  SharedPreferences? _prefs;

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> setLocale(Locale? value) async {
    if (_locale == value) return;
    _locale = value;
    await _saveLocale();
  }

  Crapto1Implementation? _crapto1Implementation;
  Crapto1Implementation? get crapto1Implementation => _crapto1Implementation;

  Future<void> setCrapto1Implementation(Crapto1Implementation value) async {
    if (_crapto1Implementation == value) return;
    _crapto1Implementation = value;
    await _saveCrapto1Implementation();
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    // Load Locale
    final String? localeStr = _prefs?.getString('locale');
    if (localeStr == 'en') {
      _locale = const Locale('en');
    } else if (localeStr == 'zh_Hant_TW') {
      _locale = const Locale.fromSubtags(
        languageCode: "zh",
        scriptCode: "Hant",
        countryCode: "TW",
      );
    } else {
      _locale = null;
    }

    // Load Crapto1Implementation
    int? v = _prefs?.getInt('crapto1Implementation');
    if (v == null) {
      if (Platform.isAndroid) {
        if (Platform.version.contains('arm64')) {
          v = Crapto1Implementation.native.index;
        } else {
          v = Crapto1Implementation.java.index;
        }
      } else {
        v = Crapto1Implementation.dart.index;
      }
    }

    if (v >= 0 && v < Crapto1Implementation.values.length) {
      _crapto1Implementation = Crapto1Implementation.values[v];
    } else {
      _crapto1Implementation = Crapto1Implementation.dart;
    }
  }

  Future<void> _saveLocale() async {
    if (_prefs == null) return;
    if (_locale != null) {
      await _prefs!.setString('locale', _locale.toString());
    } else {
      await _prefs!.remove('locale');
    }
  }

  Future<void> _saveCrapto1Implementation() async {
    if (_prefs == null || _crapto1Implementation == null) return;
    await _prefs!.setInt(
      'crapto1Implementation',
      _crapto1Implementation!.index,
    );
  }
}
