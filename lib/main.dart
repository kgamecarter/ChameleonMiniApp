import 'package:flutter/material.dart';
import 'services/settings.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings().load();
  Routes();
}
