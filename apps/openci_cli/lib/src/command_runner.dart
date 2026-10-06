import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import 'commands/dev/dev_command.dart';
import 'commands/list/list_command.dart';
import 'commands/login_command.dart';
import 'commands/register/register_command.dart';
import 'commands/setup/setup_command.dart';
import 'commands/status_command.dart';
import 'commands/switch/switch_command.dart';
import 'commands/sync/sync_command.dart';
import 'commands/update_command.dart';
import 'commands/use_command.dart';
import 'completion/genuineci_completion_command.dart';
import 'credential_store/credential_store.dart';
import 'i18n/i18n.dart';
import 'update/cli_updater.dart';
import 'update/prompt_for_update.dart';
import 'version.dart';

export 'version.dart' show genuineCIVersion;

class GenuineCICommandRunner extends CompletionCommandRunner<int> {
  static const _completionCommands = {
    HandleCompletionRequestCommand.commandName,
    InstallCompletionFilesCommand.commandName,
    UnistallCompletionFilesCommand.commandName,
  };

  final CredentialStore _completionCredentialStore;
  final Logger _logger;
  final CliUpdater _updater;
  final bool Function() _confirmUpdate;
  final bool _hasTerminal;
  final Map<String, String> _environment;

  GenuineCICommandRunner({
    Logger? logger,
    CliUpdater? updater,
    @visibleForTesting CredentialStore? completionCredentialStore,
    @visibleForTesting bool Function() confirmUpdate = promptForUpdate,
    @visibleForTesting bool? hasTerminal,
    @visibleForTesting Map<String, String>? environment,
  }) : _completionCredentialStore =
           completionCredentialStore ?? CredentialStore(),
       _logger = logger ?? Logger.standard(),
       _updater = updater ?? CliUpdater(),
       _confirmUpdate = confirmUpdate,
       _hasTerminal =
           hasTerminal ??
           (stdin.hasTerminal && stdout.hasTerminal && stderr.hasTerminal),
       _environment = environment ?? Platform.environment,
       super('genuineci', t.cli.description) {
    environmentOverride = _environment;
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: t.cli.flags.version,
      )
      ..addFlag('verbose', negatable: false, help: t.cli.flags.verbose)
      ..addFlag(
        'check-updates',
        defaultsTo: true,
        help: t.cli.flags.checkUpdates,
      );

    addCommand(LoginCommand(logger: _logger));
    addCommand(StatusCommand(logger: _logger));
    addCommand(ListCommand(logger: _logger));
    addCommand(RegisterCommand(logger: _logger));
    addCommand(SetupCommand(logger: _logger));
    addCommand(SwitchCommand(logger: _logger));
    addCommand(UseCommand(logger: _logger));
    addCommand(DevCommand(logger: _logger));
    addCommand(SyncCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger, updater: _updater));
  }

  @override
  void addCommand(Command<int> command) {
    super.addCommand(
      command is HandleCompletionRequestCommand<int>
          ? GenuineCICompletionCommand(
              readCredentials: () => _completionCredentialStore.get(),
            )
          : command,
    );
  }

  @override
  bool get enableAutoInstall =>
      _hasTerminal && !_environment.containsKey('CI') && systemShell != null;

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _logger.stdout(t.cli.version(version: genuineCIVersion));
      return 0;
    }
    if (_shouldCheckForUpdate(topLevelResults)) {
      String? version;
      try {
        version = await _updater.getLatestUpdate();
      } catch (_) {
        // An optional update check must not prevent the requested command.
      }
      if (version != null) {
        _logger.stderr(
          t.update.available(current: _updater.currentVersion, latest: version),
        );
        if (_confirmUpdate()) {
          final code = await _updater.install(version, _logger);
          if (code == 0) _logger.stderr(t.update.rerunCommand);
          return code;
        }
      }
    }
    return await super.runCommand(topLevelResults);
  }

  bool _shouldCheckForUpdate(ArgResults results) {
    if (!_hasTerminal ||
        _environment.containsKey('CI') ||
        results['check-updates'] != true ||
        results.command == null ||
        results.command!.name == 'help' ||
        results.command!.name == 'update' ||
        _completionCommands.contains(results.command!.name)) {
      return false;
    }
    for (
      ArgResults? current = results;
      current != null;
      current = current.command
    ) {
      if (current['help'] == true) return false;
    }
    return true;
  }
}
