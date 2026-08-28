import 'package:args/command_runner.dart';

class LoginCommand extends Command<int> {
  @override
  final String name = 'login';

  @override
  final String description = 'Log in to GenuineCI server (Local or Cloud).';

  LoginCommand() {
    argParser
      ..addFlag(
        'local',
        abbr: 'l',
        negatable: false,
        help: 'Log in to local Docker environment (http://localhost:8080).',
      )
      ..addOption('server', abbr: 's', help: 'Server base URL.')
      ..addOption(
        'api-key',
        abbr: 'k',
        help: 'API key / Internal API key for authentication.',
      )
      ..addOption('team-id', abbr: 't', help: 'Target team ID.')
      ..addOption(
        'profile',
        abbr: 'p',
        help: 'Profile name to store credentials under.',
      );
  }

  @override
  Future<int> run() async {
    // TODO: Implement login business logic
    return 0;
  }
}
