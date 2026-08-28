import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'commands/login_command.dart';

const String genuineCiVersion = '0.0.1';

class GenuineCiCommandRunner extends CommandRunner<int> {
  GenuineCiCommandRunner()
    : super(
        'genuineci',
        'GenuineCI command-line tool for managing CI/CD and secrets.',
      ) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current tool version.',
      )
      ..addFlag(
        'verbose',
        negatable: false,
        help: 'Enable verbose logging output.',
      );

    addCommand(LoginCommand());
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      stdout.writeln('genuineci version: $genuineCiVersion');
      return 0;
    }
    return await super.runCommand(topLevelResults);
  }
}
