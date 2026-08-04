import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

import 'features/home/view_models/home_view_model.dart';
import 'features/home/views/home_page.dart';
import 'features/settings/view_models/settings_view_model.dart';
import 'features/settings/views/language_page.dart';
import 'features/settings/views/settings_page.dart';

class MyApp extends StatelessWidget {
  final SettingsViewModel settingsViewModel;
  final HomeViewModel homeViewModel;

  const MyApp({
    super.key,
    required this.settingsViewModel,
    required this.homeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsViewModel,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'Chameleon Mini App',
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.chameleonMiniApp,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.lime),
              useMaterial3: true,
            ),
            home: HomePage(
              viewModel: homeViewModel,
              settingsViewModel: settingsViewModel,
            ),
            routes: {
              SettingsPage.name: (context) =>
                  SettingsPage(viewModel: settingsViewModel),
              LanguagePage.name: (context) => LanguagePage(),
            },
            locale: settingsViewModel.locale,
          ),
        );
      },
    );
  }
}
