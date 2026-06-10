import 'package:args/args.dart';

ArgParser get argParser {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.')
    ..addFlag(
      'update',
      abbr: 'u',
      negatable: false,
      help: 'Update to the latest version.',
    )
    ..addOption(
      'email',
      abbr: 'e',
      help: 'The Firebase Auth email for this worker.',
    )
    ..addOption(
      'password',
      abbr: 'p',
      help: 'The Firebase Auth password for this worker.',
    )
    ..addOption(
      'project-id',
      help: 'The Firebase project ID (defaults to openci-b1b91).',
      defaultsTo: 'openci-b1b91',
    )
    ..addOption(
      'api-key',
      help: 'The Firebase Web API key.',
    )
    ..addOption('sentry-dsn', help: 'Sentry DSN for error reporting.')
    ..addFlag(
      'supervised',
      negatable: false,
      help:
          'Run in supervised mode. The process will manage a child worker '
          'and handle auto-updates and crash recovery.',
    );
}

void printArgsUsage() {
  print('Usage: openci_worker <flags> [arguments]');
  print(argParser.usage);
}
