import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>('genuineci register', 'Terminal test')
    ..addCommand(
      RegisterSecretFileCommand(
        logger: Logger.standard(),
        credentialStore: CredentialStore(customFilePath: arguments.single),
      ),
    );
  exitCode = await runner.run(['secretFile']) ?? 0;
}
