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
