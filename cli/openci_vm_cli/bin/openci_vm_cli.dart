import 'dart:io';

import 'package:args/args.dart';
import 'package:openci_vm_cli/commands/ios_sign.dart';

const String version = '1.0.7';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Print version')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  // Add subcommands
  parser.addCommand('ios-sign', iosSignParser());

  final results = parser.parse(arguments);

  if (results['version'] as bool) {
    print('openci $version');
    return;
  }

  if (results['help'] as bool || results.command == null) {
    _printUsage(parser);
    return;
  }

  switch (results.command!.name) {
    case 'ios-sign':
      await runIosSign(results.command!);
    default:
      print('Unknown command: ${results.command!.name}');
      _printUsage(parser);
      exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('''
OpenCI CLI v$version
Usage: openci <command> [arguments]

Available commands:
  ios-sign    Setup iOS code signing, build archive, and export IPA

Global options:
${parser.usage}
''');
}
