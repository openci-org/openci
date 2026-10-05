import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/parser.dart';

import '../commands/use_command.dart';
import '../credential_store/credential_config.dart';

class GenuineCICompletionCommand extends HandleCompletionRequestCommand<int> {
  GenuineCICompletionCommand({required this.readCredentials});

  final Future<CredentialConfig> Function() readCredentials;

  @override
  Future<int> run() async {
    try {
      final state = CompletionState.fromEnvironment(runner.environmentOverride);
      if (state == null || state.args.isEmpty) return 0;

      // Resolve only complete words so an exact command name under the cursor
      // is still completed as a command, rather than as its first option.
      final words = state.args.toList();
      final current = words.removeLast();
      final context = CompletionLevel.find(
        words,
        runner.argParser,
        runner.commands,
      );
      if (context == null) return 0;
      final path = _commandPath(runner.commands, context.grammar) ?? [];
      if (path.any((command) => command.hidden && command.name != 'help')) {
        return 0;
      }

      final options = {
        ...runner.argParser.options,
        for (final command in path) ...command.argParser.options,
      };
      final rawArgs = context.rawArgs.where((word) => word.isNotEmpty).toList();
      var pattern = current;
      var valuePrefix = '';
      if (current.startsWith('--') && current.contains('=')) {
        final separator = current.indexOf('=');
        valuePrefix = current.substring(0, separator + 1);
        rawArgs.add(current.substring(0, separator));
        pattern = current.substring(separator + 1);
      }

      final grammar = _copyOptions(options.values);
      final level = CompletionLevel.find(rawArgs, grammar, const {})!;
      final command = path.lastOrNull;
      final pendingOption = rawArgs.lastOrNull;
      final valueOption = pendingOption == null
          ? null
          : _valueOption(grammar, pendingOption);
      final values = <String, List<String>>{};
      if (command?.name == 'login' && valueOption != null) {
        values[valueOption.name] = await _loginValues(
          options[valueOption.name]!,
          level.parsedOptions,
          options,
        );
      }

      var subcommands = command?.subcommands ?? runner.commands;
      final positional = level.parsedOptions?.rest ?? rawArgs;
      if (command?.name == 'help') {
        subcommands = runner.commands;
        for (final name in positional) {
          final target = subcommands[name];
          if (target == null || target.hidden) return 0;
          subcommands = target.subcommands;
        }
      }

      // This grammar is used only for completion. Suggested values do not
      // restrict the values accepted by the actual commands.
      final completionLevel = CompletionLevel.find(
        [...rawArgs, pattern],
        _copyOptions(options.values, values: values),
        subcommands,
      )!;
      final results = pattern.startsWith('--') && valueOption == null
          ? [
              MatchingOptionsCompletionResult(
                completionLevel: level,
                pattern: pattern.substring(2),
              ),
            ]
          : CompletionParser(completionLevel: completionLevel).parse();
      final suggestions = <String, String?>{
        for (final result in results) ...result.completions,
      };
      if (command is UseCommand && positional.isEmpty && valueOption == null) {
        for (final entry in UseCommand.languages.entries) {
          if (entry.key.startsWith(pattern.toLowerCase())) {
            suggestions[entry.key] = entry.value.name;
          }
        }
      }
      if (path.isEmpty && 'help'.startsWith(pattern)) {
        suggestions['help'] = runner.commands['help']?.description;
      }
      // Readline retains the prefix through ':' and '='. Bash 3 can keep
      // those separators inside COMP_WORDS, so use the input word itself.
      var retainedPrefix = '';
      if (runner.systemShell == SystemShell.bash) {
        final separator = current.lastIndexOf(RegExp('[:=]'));
        retainedPrefix = current.substring(0, separator + 1);
      }
      runner.renderCompletionResult(
        _Suggestions({
          for (final entry in suggestions.entries)
            _replaceablePart('$valuePrefix${entry.key}', retainedPrefix):
                entry.value,
        }),
      );
    } on Exception {
      // Shells treat all output as candidates, including error messages.
    }
    return 0;
  }

  Future<List<String>> _loginValues(
    Option option,
    ArgResults? parsed,
    Map<String, Option> options,
  ) async {
    final values = <String>{
      if (option.defaultsTo case final String value) value,
    };
    try {
      final config = await readCredentials();
      final server = _serverUrl(
        parsed?['server'] as String? ?? options['server']!.defaultsTo as String,
      );
      for (final profile in config.profiles.values) {
        final profileServer = _serverUrl(profile.serverUrl);
        if (profileServer == null) continue;
        if (option.name == 'server') {
          values.add(profileServer);
        } else if (profileServer == server) {
          if (option.name == 'team-id') values.add(profile.teamId);
          if (option.name == 'firebase-api-key') {
            values.add(profile.firebaseApiKey);
          }
        }
      }
    } catch (_) {
      // Missing or unreadable saved settings must not break completion.
    }
    return values
        .where(
          (value) =>
              value.isNotEmpty && !RegExp(r'[\s\x00-\x1f\x7f]').hasMatch(value),
        )
        .toList();
  }
}

List<Command<dynamic>>? _commandPath(
  Map<String, Command<dynamic>> commands,
  ArgParser grammar,
) {
  for (final command in commands.values) {
    if (identical(command.argParser, grammar)) return [command];
    final descendants = _commandPath(command.subcommands, grammar);
    if (descendants != null) return [command, ...descendants];
  }
  return null;
}

ArgParser _copyOptions(
  Iterable<Option> options, {
  Map<String, List<String>> values = const {},
}) {
  final parser = ArgParser();
  for (final option in options) {
    if (option.isFlag) {
      parser.addFlag(
        option.name,
        abbr: option.abbr,
        help: option.help,
        defaultsTo: option.defaultsTo as bool?,
        negatable: option.negatable ?? false,
        hide: option.hide,
        aliases: option.aliases,
      );
    } else if (option.isMultiple) {
      parser.addMultiOption(
        option.name,
        abbr: option.abbr,
        help: option.help,
        allowed: values[option.name] ?? option.allowed,
        allowedHelp: option.allowedHelp,
        hide: option.hide,
        aliases: option.aliases,
      );
    } else {
      parser.addOption(
        option.name,
        abbr: option.abbr,
        help: option.help,
        allowed: values[option.name] ?? option.allowed,
        allowedHelp: option.allowedHelp,
        hide: option.hide,
        aliases: option.aliases,
      );
    }
  }
  return parser;
}

Option? _valueOption(ArgParser parser, String word) {
  final option = word.startsWith('--')
      ? parser.findByNameOrAlias(word.substring(2))
      : word.length == 2 && word.startsWith('-')
      ? parser.findByAbbreviation(word.substring(1))
      : null;
  return option != null && !option.isFlag ? option : null;
}

String _replaceablePart(String candidate, String retainedPrefix) =>
    candidate.startsWith(retainedPrefix)
    ? candidate.substring(retainedPrefix.length)
    : candidate;

String? _serverUrl(String value) {
  final url = Uri.tryParse(value.trim());
  if (url == null ||
      url.scheme != 'https' ||
      url.host.isEmpty ||
      url.userInfo.isNotEmpty ||
      url.hasQuery ||
      url.hasFragment) {
    return null;
  }
  return url.toString().replaceFirst(RegExp(r'/+$'), '');
}

class _Suggestions extends CompletionResult {
  const _Suggestions(this.completions);

  @override
  final Map<String, String?> completions;
}
