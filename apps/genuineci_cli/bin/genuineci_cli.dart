import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:genuineci_cli/genuineci_cli.dart';

Future<void> main(List<String> arguments) async {
  initI18n();

  final runner = GenuineCiCommandRunner();
  try {
    final exitCode = await runner.run(arguments);
    if (exitCode != null && exitCode != 0) {
      exit(exitCode);
    }
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln();
    stderr.writeln(e.usage);
    exit(64); // EX_USAGE
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
