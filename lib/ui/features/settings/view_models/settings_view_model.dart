import 'package:flutter/material.dart';

import '../../../../data/repositories/settings_repository.dart';
import '../../../../domain/models/crapto1_implementation.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SettingsRepository repository})
    : _repository = repository;

  final SettingsRepository _repository;

  Locale? get locale => _repository.locale;
  Crapto1Implementation? get crapto1Implementation =>
      _repository.crapto1Implementation;

  Future<void> load() async {
    await _repository.load();
    notifyListeners();
  }

  Future<void> setLocale(Locale? value) async {
    await _repository.setLocale(value);
    notifyListeners();
  }

  Future<void> setCrapto1Implementation(Crapto1Implementation value) async {
    await _repository.setCrapto1Implementation(value);
    notifyListeners();
  }
}
