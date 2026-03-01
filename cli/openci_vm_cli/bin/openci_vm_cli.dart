import 'dart:io';

import 'package:args/args.dart';
import 'package:openci_vm_cli/commands/android_deploy.dart';
import 'package:openci_vm_cli/commands/ios_sign.dart';
import 'package:openci_vm_cli/commands/vm.dart';

const String version = '1.0.13';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Print version')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  parser.addCommand('ios-sign', iosSignParser());
  parser.addCommand('android-deploy', androidDeployParser());
  parser.addCommand('vm-create', vmCreateParser());
  parser.addCommand('vm-install', vmInstallParser());
  parser.addCommand('vm-start', vmStartParser());
  parser.addCommand('vm-setup', vmSetupParser());
  parser.addCommand('vm-clone', vmCloneParser());

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
    case 'android-deploy':
      await runAndroidDeploy(results.command!);
    case 'vm-create':
      await runVmCreate(results.command!);
    case 'vm-install':
      await runVmInstall(results.command!);
    case 'vm-start':
      await runVmStart(results.command!);
    case 'vm-setup':
      await runVmSetup(results.command!);
    case 'vm-clone':
      await runVmClone(results.command!);
    default:
      print('Unknown command: ${results.command!.name}');
      _printUsage(parser);
      exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('''
OpenCI CLI v$version
Usage: openci_vm <command> [arguments]

Available commands:
  ios-sign        Setup iOS code signing, build archive, and export IPA
  android-deploy  Deploy AAB to Google Play Console
  vm-create       Create a new macOS VM bundle from an IPSW
  vm-install      Install macOS into a VM bundle
  vm-start        Start a macOS VM from a bundle
  vm-setup        Full setup: download IPSW + create bundle + install macOS
  vm-clone        Clone a VM bundle (APFS copy-on-write)

Global options:
${parser.usage}
''');
}
