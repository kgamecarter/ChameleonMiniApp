import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import '../../../../data/repositories/chameleon_repository.dart';
import '../../../../domain/models/slot.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/slot_view_model.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

class SlotView extends StatefulWidget {
  SlotView({
    super.key,
    required this.slot,
    required this.repository,
    required this.settingsViewModel,
    required this.connected,
    this.modes,
    this.buttonModes,
    this.longPressButtonModes,
  });

  final Slot slot;
  final ChameleonRepository repository;
  final SettingsViewModel settingsViewModel;
  final bool connected;
  final List<String>? modes, buttonModes, longPressButtonModes;

  @override
  _SlotViewState createState() => _SlotViewState();
}

class _SlotViewState extends State<SlotView> {
  late SlotViewModel _viewModel;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _uidFocusNode = FocusNode();
  late final TextEditingController _uidController;
  late final TextEditingController _memorySizeController;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _uidController = TextEditingController(text: widget.slot.uid);
    _memorySizeController = TextEditingController(
      text: widget.slot.memorySize?.toString() ?? '',
    );
    _viewModel = SlotViewModel(
      widget.slot,
      widget.repository,
      widget.settingsViewModel,
    );
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _uidController.dispose();
    _memorySizeController.dispose();
    _uidFocusNode.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final uid = widget.slot.uid ?? '';
    if (!_uidFocusNode.hasFocus && _uidController.text != uid) {
      _uidController.text = uid;
    }
    final memorySize = widget.slot.memorySize?.toString() ?? '';
    if (_memorySizeController.text != memorySize) {
      _memorySizeController.text = memorySize;
    }
    setState(() {});
  }

  _uidChanged(String str) => _viewModel.setUid(str);
  _uidEditingComplete() {
    _uidFocusNode.unfocus();
    print(widget.slot.uid);
  }

  void _modeChanged(String? str) => _viewModel.setMode(str);
  void _buttonModeChanged(String? str) => _viewModel.setButton(str);
  void _longPressButtonModeChanged(String? str) =>
      _viewModel.setLongPressButton(str);

  Future<void> _refresh() async {
    await _viewModel.refresh();
  }

  Future<void> _apply() async {
    await _viewModel.apply();
    if (!mounted) return;
    final snackBar = const SnackBar(content: const Text('Applied'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _upload() async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
    );
    final filePath = await FlutterFileDialog.pickFile(params: params);
    print(filePath);
    if (filePath == null) return;
    var file = File(filePath);
    Uint8List data;
    if (filePath.endsWith('.bin')) {
      data = Uint8List.fromList(await file.readAsBytes());
    } else {
      var str = (await file.readAsLines())
          .where((str) => str.length == 32)
          .map((str) => str.replaceAll('-', 'F'))
          .join();
      data = SlotViewModel.stringToBytes(str);
    }
    await _viewModel.upload(data);
    if (!mounted) return;
    final snackBar = const SnackBar(
      content: const Text('Upload dump file success.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _mfkey32() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                Container(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(AppLocalizations.of(context)!.attacking),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    List<String>? list;
    String? errorMessage;
    try {
      list = await _viewModel.mfkey32();
    } on Mfkey32Exception catch (e) {
      errorMessage = e.cause;
    } finally {
      if (mounted) Navigator.pop(context);
    }
    if (!mounted) return;
    if (errorMessage != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("mfkey32 result"),
            content: Text(errorMessage!),
            actions: <Widget>[
              MaterialButton(
                child: const Text("Close"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
    if (list != null && list.length > 0) {
      final result = list.join('\n');
      var thisContext = context;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("mfkey32 result"),
            content: Text(result),
            actions: <Widget>[
              TextButton(
                child: const Text("Copy and Close"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result));
                  Navigator.pop(context);
                  final snackBar = const SnackBar(
                    content: const Text('Copied to clipboard.'),
                    duration: Duration(seconds: 3),
                  );
                  ScaffoldMessenger.of(thisContext).showSnackBar(snackBar);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _download() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                Container(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(AppLocalizations.of(context)!.downloading),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      var mctFormat = await _viewModel.downloadMct();

      var now = DateTime.now();
      var formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
      var fileName = 'UID_${_viewModel.slot.uid}_${formatter.format(now)}.mct';
      final params = SaveFileDialogParams(
        fileName: fileName,
        data: Uint8List.fromList(utf8.encode(mctFormat)),
      );
      final filePath = await FlutterFileDialog.saveFile(params: params);
      print(filePath);
      if (filePath == null) return;
      if (!mounted) return;
      final snackBar = const SnackBar(content: const Text('Saved'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _nfc() async {
    try {
      final snackBar = SnackBar(
        content: const Text('Start scan card.'),
        duration: const Duration(hours: 1),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () async {
            await NfcManager.instance.stopSession();
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          var nfca = NfcAAndroid.from(tag);
          if (nfca != null) {
            var str = nfca.tag.id
                .map((e) => e.toRadixString(16).toUpperCase().padLeft(2, '0'))
                .join();
            print(str);
            if (mounted) {
              _viewModel.setUid(str);
            }
          }
          if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
          await Future.delayed(const Duration(seconds: 1));
          await NfcManager.instance.stopSession();
        },
      );
    } on PlatformException {}
  }

  Future<void> _clear() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.clear),
          content: Text(AppLocalizations.of(context)!.confirmClear),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.close),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.clear),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _viewModel.clear();
    if (!mounted) return;
    final snackBar = const SnackBar(content: const Text('Cleared'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  Widget _buildActionGrid(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[
      FilledButton.icon(
        icon: const Icon(Icons.check_circle_outline),
        label: Text(localizations.apply),
        onPressed: widget.connected && !_isBusy
            ? () => _runAction(_apply)
            : null,
      ),
      FilledButton.tonalIcon(
        icon: const Icon(Icons.refresh),
        label: Text(localizations.refresh),
        onPressed: widget.connected && !_isBusy
            ? () => _runAction(_refresh)
            : null,
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.file_upload_outlined),
        label: Text(localizations.upload),
        onPressed: widget.connected && !_isBusy
            ? () => _runAction(_upload)
            : null,
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.file_download_outlined),
        label: Text(localizations.download),
        onPressed: widget.connected && !_isBusy
            ? () => _runAction(_download)
            : null,
      ),
      FilledButton.tonalIcon(
        icon: const Icon(Icons.key_outlined),
        label: Text(localizations.mfkey32),
        onPressed: widget.connected && !_isBusy
            ? () => _runAction(_mfkey32)
            : null,
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline),
        label: Text(localizations.clear),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error),
        ),
        onPressed: widget.connected && !_isBusy
            ? () => _runAction(_clear)
            : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columnCount = constraints.maxWidth >= 720 ? 3 : 2;
        final buttonWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(width: buttonWidth, height: 48, child: action),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: _fieldDecoration(
                              context,
                              label: localizations.mode,
                              icon: Icons.functions,
                            ),
                            disabledHint: Text(localizations.notAvailable),
                            initialValue: widget.slot.mode,
                            isExpanded: true,
                            items: widget.modes
                                ?.map(
                                  (str) => DropdownMenuItem(
                                    value: str,
                                    child: Text(str),
                                  ),
                                )
                                .toList(),
                            onChanged: _isBusy ? null : _modeChanged,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            enabled: widget.connected && !_isBusy,
                            focusNode: _uidFocusNode,
                            controller: _uidController,
                            decoration: _fieldDecoration(
                              context,
                              label: localizations.uid,
                              icon: Icons.fingerprint,
                              suffixIcon: IconButton(
                                tooltip: 'NFC',
                                icon: const Icon(Icons.nfc),
                                onPressed: widget.connected && !_isBusy
                                    ? _nfc
                                    : null,
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            autocorrect: false,
                            enableSuggestions: false,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9a-fA-F]'),
                              ),
                              LengthLimitingTextInputFormatter(14),
                            ],
                            onChanged: _uidChanged,
                            onEditingComplete: _uidEditingComplete,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: _fieldDecoration(
                              context,
                              label: localizations.button,
                              icon: Icons.touch_app_outlined,
                            ),
                            disabledHint: Text(localizations.notAvailable),
                            initialValue: widget.slot.button,
                            isExpanded: true,
                            items: widget.buttonModes
                                ?.map(
                                  (str) => DropdownMenuItem(
                                    value: str,
                                    child: Text(str),
                                  ),
                                )
                                .toList(),
                            onChanged: _isBusy ? null : _buttonModeChanged,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: _fieldDecoration(
                              context,
                              label: localizations.longPressButton,
                              icon: Icons.back_hand_outlined,
                            ),
                            disabledHint: Text(localizations.notAvailable),
                            initialValue: widget.slot.longPressButton,
                            isExpanded: true,
                            items: widget.longPressButtonModes
                                ?.map(
                                  (str) => DropdownMenuItem(
                                    value: str,
                                    child: Text(str),
                                  ),
                                )
                                .toList(),
                            onChanged: _isBusy
                                ? null
                                : _longPressButtonModeChanged,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _memorySizeController,
                            readOnly: true,
                            enabled: false,
                            decoration: _fieldDecoration(
                              context,
                              label: localizations.memorySize,
                              icon: Icons.memory,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isBusy
                        ? const Padding(
                            key: ValueKey('progress'),
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: LinearProgressIndicator(minHeight: 3),
                          )
                        : const SizedBox(
                            key: ValueKey('progress-placeholder'),
                            height: 8,
                          ),
                  ),
                  _buildActionGrid(context, localizations),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
