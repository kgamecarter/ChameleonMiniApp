import 'package:flutter/material.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

class DeviceInfoDialog extends StatelessWidget {
  const DeviceInfoDialog(this.version, this.rssi, {Key? key}) : super(key: key);

  final String version, rssi;

  void _reset(BuildContext context) {
    Navigator.of(context).pop('reset');
  }

  void _disconnect(BuildContext context) {
    Navigator.of(context).pop('disconnect');
  }

  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: const Icon(Icons.usb_rounded),
      title: Text(localizations.deviceInfo),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _DeviceInfoMetric(
              icon: Icons.memory_outlined,
              label: localizations.firmwareVersion,
              value: version,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            _DeviceInfoMetric(
              icon: Icons.network_cell_rounded,
              label: localizations.signalStrength,
              value: rssi,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => _close(context),
          child: Text(localizations.close),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 48),
            foregroundColor: colorScheme.error,
          ),
          onPressed: () => _reset(context),
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(localizations.reset),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => _disconnect(context),
          icon: const Icon(Icons.usb_off_rounded),
          label: Text(localizations.disconnect),
        ),
      ],
    );
  }
}

class _DeviceInfoMetric extends StatelessWidget {
  const _DeviceInfoMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
