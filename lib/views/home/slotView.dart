import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import '../../services/chameleonClient.dart';
import '../../view_models/slotViewModel.dart';
import 'package:chameleon_mini_app/l10n/app_localizations.dart';

class SlotView extends StatefulWidget {
  SlotView(
    this.slot,
    this.client, {
    Key? key,
    this.modes,
    this.buttonModes,
    this.longPressButtonModes,
  }) : super(key: key);

  final Slot slot;
  final ChameleonClient client;
  final List<String>? modes, buttonModes, longPressButtonModes;

  @override
  _SlotViewState createState() => _SlotViewState();
}

class _SlotViewState extends State<SlotView> {
  late SlotViewModel _viewModel;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FocusNode uidFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = SlotViewModel(widget.slot, widget.client);
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  _uidChanged(String str) => _viewModel.setUid(str);
  _uidEditingComplete() {
    uidFocusNode.unfocus();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  icon: const Icon(Icons.functions),
                  labelText: AppLocalizations.of(context)!.mode,
                ),
                disabledHint: Text(AppLocalizations.of(context)!.notAvailable),
                initialValue: widget.slot.mode,
                isDense: true,
                items: widget.modes
                    ?.map(
                      (str) => DropdownMenuItem(value: str, child: Text(str)),
                    )
                    .toList(),
                onChanged: _modeChanged,
              ),
              const SizedBox(height: 8.0),
              TextField(
                enabled: widget.client.connected,
                focusNode: uidFocusNode,
                controller: TextEditingController(text: widget.slot.uid),
                decoration: InputDecoration(
                  icon: const Icon(Icons.fingerprint),
                  labelText: AppLocalizations.of(context)!.uid,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.nfc),
                    onPressed: _nfc,
                  ),
                ),
                keyboardType: TextInputType.text,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9a-fA-F]{0,14}'),
                  ),
                ],
                onChanged: _uidChanged,
                onEditingComplete: _uidEditingComplete,
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  icon: const Icon(Icons.touch_app),
                  labelText: AppLocalizations.of(context)!.button,
                ),
                disabledHint: Text(AppLocalizations.of(context)!.notAvailable),
                initialValue: widget.slot.button,
                isDense: true,
                items: widget.buttonModes
                    ?.map(
                      (str) => DropdownMenuItem(value: str, child: Text(str)),
                    )
                    .toList(),
                onChanged: _buttonModeChanged,
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  icon: const Icon(Icons.touch_app),
                  labelText: AppLocalizations.of(context)!.longPressButton,
                ),
                disabledHint: Text(AppLocalizations.of(context)!.notAvailable),
                initialValue: widget.slot.longPressButton,
                isDense: true,
                items: widget.longPressButtonModes
                    ?.map(
                      (str) => DropdownMenuItem(value: str, child: Text(str)),
                    )
                    .toList(),
                onChanged: _longPressButtonModeChanged,
              ),
              const SizedBox(height: 8.0),
              TextField(
                enabled: false,
                controller: TextEditingController(
                  text: widget.slot.memorySize?.toString(),
                ),
                decoration: InputDecoration(
                  icon: const Icon(Icons.memory),
                  labelText: AppLocalizations.of(context)!.memorySize,
                ),
              ),
              const SizedBox(height: 16.0),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context)!.refresh),
                          onPressed: widget.client.connected ? _refresh : null,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(AppLocalizations.of(context)!.apply),
                          onPressed: widget.client.connected ? _apply : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.file_upload_outlined),
                          label: Text(AppLocalizations.of(context)!.upload),
                          onPressed: widget.client.connected ? _upload : null,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.file_download_outlined),
                          label: Text(AppLocalizations.of(context)!.download),
                          onPressed: widget.client.connected ? _download : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: Text(AppLocalizations.of(context)!.clear),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.errorContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          onPressed: widget.client.connected ? _clear : null,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.key),
                          label: Text(AppLocalizations.of(context)!.mfkey32),
                          onPressed: widget.client.connected ? _mfkey32 : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
