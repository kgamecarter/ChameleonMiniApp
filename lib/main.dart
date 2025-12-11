import 'package:flutter/material.dart';
import 'services/settings.dart';
import 'myApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = Settings();
  await settings.load();
  runApp(MyApp(settings: settings));
}
