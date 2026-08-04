import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

import '../../../../domain/models/crapto1_implementation.dart';
import '../view_models/settings_view_model.dart';
import 'language_page.dart';

class SettingsPage extends StatefulWidget {
  static const String name = '/Settings/Language';

  const SettingsPage({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          scrolledUnderElevation: 0,
        ),
        body: _buildBody(context),
      ),
    );
  }

  String _localToString(Locale? locale) {
    if (locale?.languageCode == 'en') {
      return AppLocalizations.of(context)!.english;
    }
    if (locale?.languageCode == 'ja') {
      return AppLocalizations.of(context)!.japanese;
    }
    if (locale?.languageCode == 'zh') {
      if (locale?.scriptCode == 'Hant') {
        return AppLocalizations.of(context)!.traditionalChinese;
      }
      if (locale?.scriptCode == 'Hans') {
        return AppLocalizations.of(context)!.simplifiedChinese;
      }
    }
    return AppLocalizations.of(context)!.systemDefault;
  }

  String _crapto1ImplementationToString(
    Crapto1Implementation crapto1implementation,
  ) {
    switch (crapto1implementation) {
      case Crapto1Implementation.dart:
        return AppLocalizations.of(context)!.crapto1Dart;
      case Crapto1Implementation.java:
        return AppLocalizations.of(context)!.crapto1Java;
      case Crapto1Implementation.online:
        return AppLocalizations.of(context)!.crapto1Online;
      case Crapto1Implementation.native:
        return AppLocalizations.of(context)!.crapto1Native;
    }
  }

  Future<void> _pushLanguagePage() async {
    final value = await Navigator.of(context).pushNamed(LanguagePage.name);
    if (!mounted || value == null) return;

    await widget.viewModel.setLocale(
      value == 'default' ? null : value as Locale,
    );
  }

  Future<void> _showCrapto1ImplementationDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(Icons.memory_rounded, color: colorScheme.primary),
        title: Text(AppLocalizations.of(context)!.crapto1Implementation),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: RadioGroup<Crapto1Implementation>(
            groupValue: widget.viewModel.crapto1Implementation,
            onChanged: _selectCrapto1Implementation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImplementationOption(
                  value: Crapto1Implementation.dart,
                  groupValue: widget.viewModel.crapto1Implementation,
                  label: _crapto1ImplementationToString(
                    Crapto1Implementation.dart,
                  ),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 4),
                _ImplementationOption(
                  value: Crapto1Implementation.java,
                  groupValue: widget.viewModel.crapto1Implementation,
                  label: _crapto1ImplementationToString(
                    Crapto1Implementation.java,
                  ),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 4),
                _ImplementationOption(
                  value: Crapto1Implementation.native,
                  groupValue: widget.viewModel.crapto1Implementation,
                  label: _crapto1ImplementationToString(
                    Crapto1Implementation.native,
                  ),
                  enabled: Platform.version.contains('arm64'),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectCrapto1Implementation(
    Crapto1Implementation? value,
  ) async {
    if (value == null) return;
    await widget.viewModel.setCrapto1Implementation(value);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 720 ? 32.0 : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              24,
            ),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 8,
                            bottom: 12,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.generalSetting,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.language_rounded,
                              title: AppLocalizations.of(context)!.language,
                              subtitle: _localToString(widget.viewModel.locale),
                              onTap: _pushLanguagePage,
                            ),
                            Divider(
                              height: 1,
                              indent: 72,
                              color: colorScheme.outlineVariant,
                            ),
                            _SettingsTile(
                              icon: Icons.memory_rounded,
                              title: AppLocalizations.of(
                                context,
                              )!.crapto1Implementation,
                              subtitle: _crapto1ImplementationToString(
                                widget.viewModel.crapto1Implementation!,
                              ),
                              onTap: _showCrapto1ImplementationDialog,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExcludeSemantics(
          child: Icon(icon, color: colorScheme.onSecondaryContainer),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ),
      trailing: ExcludeSemantics(
        child: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ImplementationOption extends StatelessWidget {
  const _ImplementationOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.colorScheme,
    this.enabled = true,
  });

  final Crapto1Implementation value;
  final Crapto1Implementation? groupValue;
  final String label;
  final ColorScheme colorScheme;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return RadioListTile<Crapto1Implementation>(
      value: value,
      selected: selected,
      enabled: enabled,
      title: Text(label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedTileColor: colorScheme.secondaryContainer,
      tileColor: selected ? colorScheme.secondaryContainer : Colors.transparent,
    );
  }
}
