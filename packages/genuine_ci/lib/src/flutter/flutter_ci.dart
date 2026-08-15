import 'package:genuine_ci/genuine_ci.dart';

class FlutterCi {
  static Future<void> staticAnalysis(String cwd) => runCommand(
    'flutter analyze',
    workingDirectory: cwd,
  );

  static Future<void> unitTests(String cwd) => runCommand(
    'flutter test',
    workingDirectory: cwd,
  );
}
