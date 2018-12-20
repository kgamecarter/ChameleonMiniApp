import 'services/settings.dart';
import 'routes.dart';

void main() async {
  await Settings().load();
  Routes();
}
