import 'package:flutter/material.dart';
import 'data/repositories/chameleon_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'ui/app.dart';
import 'ui/features/home/view_models/home_view_model.dart';
import 'ui/features/settings/view_models/settings_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsViewModel = SettingsViewModel(repository: SettingsRepository());
  await settingsViewModel.load();
  runApp(
    MyApp(
      settingsViewModel: settingsViewModel,
      homeViewModel: HomeViewModel(repository: ChameleonRepository()),
    ),
  );
}
