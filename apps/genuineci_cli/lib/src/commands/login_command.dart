import 'package:args/command_runner.dart';

import '../i18n/i18n.dart';

class LoginCommand extends Command<int> {
  @override
  final String name = 'login';

  @override
  String get description => t.login.description;

  LoginCommand() {
    argParser
      ..addFlag('local', abbr: 'l', negatable: false, help: t.login.flags.local)
      ..addOption('server', abbr: 's', help: t.login.flags.server)
      ..addOption('team-id', abbr: 't', help: t.login.flags.teamId)
      ..addOption('profile', abbr: 'p', help: t.login.flags.profile);
  }

  @override
  Future<int> run() async {
    // TODO: Implement login business logic
    return 0;
  }
}
