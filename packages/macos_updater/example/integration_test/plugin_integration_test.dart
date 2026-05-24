import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_updater/macos_updater.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MacosUpdater instance test', (WidgetTester tester) async {
    final MacosUpdater plugin = MacosUpdater();
    expect(plugin, isNotNull);
  });
}
