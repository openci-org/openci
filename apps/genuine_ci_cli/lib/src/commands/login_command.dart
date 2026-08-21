import 'package:args/command_runner.dart';
import 'package:genuine_ci_cli/src/config/cli_config.dart';
import 'package:genuine_ci_cli/src/config/config_storage.dart';
import 'package:mason_logger/mason_logger.dart';

class LoginCommand extends Command<int> {
  LoginCommand({
    required Logger logger,
    ConfigStorage? configStorage,
  }) : _logger = logger,
       _configStorage = configStorage ?? ConfigStorage() {
    argParser
      ..addOption(
        'server-url',
        help: 'OpenCI Server URL',
        defaultsTo: CliConfig.defaultServerUrl,
      )
      ..addOption(
        'token',
        abbr: 't',
        help: 'Personal Access Token or API Key',
      )
      ..addOption(
        'team-id',
        help: 'Default Team ID to use',
      );
  }

  @override
  String get name => 'login';

  @override
  String get description => 'Log in and configure Genuine CI credentials.';

  final Logger _logger;
  final ConfigStorage _configStorage;

  @override
  Future<int> run() async {
    final currentConfig = _configStorage.loadGlobalConfig();

    final serverUrl =
        argResults?['server-url'] as String? ?? currentConfig.serverUrl;
    var token = argResults?['token'] as String?;
    var teamId = argResults?['team-id'] as String?;

    if (token == null || token.isEmpty) {
      final defaultMsg =
          currentConfig.token != null && currentConfig.token!.isNotEmpty
          ? ' (leave blank to keep current)'
          : '';
      final input = _logger
          .prompt('Enter OpenCI API Token or Key$defaultMsg:')
          .trim();
      token = input.isNotEmpty ? input : currentConfig.token;
    }

    if (token == null || token.isEmpty) {
      _logger.err('Token cannot be empty.');
      return ExitCode.usage.code;
    }

    if (teamId == null || teamId.isEmpty) {
      final defaultTeam = currentConfig.teamId ?? '';
      final input = _logger
          .prompt(
            'Enter Team ID (optional, press Enter to skip):',
            defaultValue: defaultTeam,
          )
          .trim();
      teamId = input.isNotEmpty ? input : currentConfig.teamId;
    }

    final newConfig = currentConfig.copyWith(
      serverUrl: serverUrl,
      token: token,
      teamId: teamId,
    );

    _configStorage.saveGlobalConfig(newConfig);

    _logger
      ..success('Logged in successfully!')
      ..info('Server URL: $serverUrl');

    if (teamId != null && teamId.isNotEmpty) {
      _logger.info('Team ID: $teamId');
    }

    _logger.info('Config saved to ${_configStorage.globalConfigFile.path}');

    return ExitCode.success.code;
  }
}
