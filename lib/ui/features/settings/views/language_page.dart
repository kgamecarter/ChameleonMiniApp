import 'package:chameleon_mini_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatelessWidget {
  static const String name = '/Settings';

  const LanguagePage({super.key});

  void _pop(BuildContext context, Object value) {
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
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
                              AppLocalizations.of(context)!.language,
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
                              _LanguageTile(
                                icon: Icons.settings_suggest_rounded,
                                title: AppLocalizations.of(
                                  context,
                                )!.systemDefault,
                                localeTag: 'default',
                                onTap: () => _pop(context, 'default'),
                              ),
                              _LanguageDivider(
                                color: colorScheme.outlineVariant,
                              ),
                              _LanguageTile(
                                marker: 'EN',
                                title: AppLocalizations.of(context)!.english,
                                localeTag: 'en',
                                onTap: () => _pop(context, const Locale('en')),
                              ),
                              _LanguageDivider(
                                color: colorScheme.outlineVariant,
                              ),
                              _LanguageTile(
                                marker: '繁',
                                title: AppLocalizations.of(
                                  context,
                                )!.traditionalChinese,
                                localeTag: 'zh-Hant-TW',
                                onTap: () => _pop(
                                  context,
                                  const Locale.fromSubtags(
                                    languageCode: 'zh',
                                    scriptCode: 'Hant',
                                    countryCode: 'TW',
                                  ),
                                ),
                              ),
                              _LanguageDivider(
                                color: colorScheme.outlineVariant,
                              ),
                              _LanguageTile(
                                marker: '简',
                                title: AppLocalizations.of(
                                  context,
                                )!.simplifiedChinese,
                                localeTag: 'zh-Hans-CN',
                                onTap: () => _pop(
                                  context,
                                  const Locale.fromSubtags(
                                    languageCode: 'zh',
                                    scriptCode: 'Hans',
                                    countryCode: 'CN',
                                  ),
                                ),
                              ),
                              _LanguageDivider(
                                color: colorScheme.outlineVariant,
                              ),
                              _LanguageTile(
                                marker: 'あ',
                                title: AppLocalizations.of(context)!.japanese,
                                localeTag: 'ja',
                                onTap: () => _pop(context, const Locale('ja')),
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
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.localeTag,
    required this.onTap,
    this.icon,
    this.marker,
  }) : assert(icon != null || marker != null);

  final IconData? icon;
  final String? marker;
  final String title;
  final String localeTag;
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExcludeSemantics(
          child: icon != null
              ? Icon(icon, color: colorScheme.onSecondaryContainer)
              : Text(
                  marker!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
          localeTag,
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

class _LanguageDivider extends StatelessWidget {
  const _LanguageDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 72, color: color);
  }
}
