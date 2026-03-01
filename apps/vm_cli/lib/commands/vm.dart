import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_avf/dart_avf.dart';

ArgParser vmSetupParser() {
  return ArgParser()
    ..addOption(
      'bundle',
      abbr: 'b',
      help: 'Path to the VM bundle directory to create',
      mandatory: true,
    )
    ..addOption(
      'disk-size',
      abbr: 'd',
      help: 'Disk size in GB (default: 64)',
      defaultsTo: '64',
    )
    ..addOption('cpu', help: 'Number of CPUs (default: 4)', defaultsTo: '4')
    ..addOption('memory', help: 'Memory in GB (default: 4)', defaultsTo: '4');
}

ArgParser vmCreateParser() {
  return ArgParser()
    ..addOption(
      'bundle',
      abbr: 'b',
      help: 'Path to the VM bundle directory to create',
      mandatory: true,
    )
    ..addOption(
      'ipsw',
      abbr: 'i',
      help: 'Path to the macOS IPSW restore image',
      mandatory: true,
    )
    ..addOption(
      'disk-size',
      abbr: 'd',
      help: 'Disk size in GB (default: 64)',
      defaultsTo: '64',
    );
}

ArgParser vmInstallParser() {
  return ArgParser()
    ..addOption(
      'bundle',
      abbr: 'b',
      help: 'Path to the VM bundle directory',
      mandatory: true,
    )
    ..addOption(
      'ipsw',
      abbr: 'i',
      help: 'Path to the macOS IPSW restore image',
      mandatory: true,
    )
    ..addOption('cpu', help: 'Number of CPUs (default: 4)', defaultsTo: '4')
    ..addOption('memory', help: 'Memory in GB (default: 4)', defaultsTo: '4');
}

ArgParser vmStartParser() {
  return ArgParser()
    ..addOption(
      'bundle',
      abbr: 'b',
      help: 'Path to the VM bundle directory',
      mandatory: true,
    )
    ..addOption('cpu', help: 'Number of CPUs (default: 4)', defaultsTo: '4')
    ..addOption('memory', help: 'Memory in GB (default: 4)', defaultsTo: '4')
    ..addFlag('gui', help: 'Open a GUI window for the VM', defaultsTo: false);
}

ArgParser vmCloneParser() {
  return ArgParser()
    ..addOption(
      'source',
      abbr: 's',
      help: 'Path to the source VM bundle (golden image)',
      mandatory: true,
    )
    ..addOption(
      'dest',
      abbr: 'd',
      help: 'Path for the cloned VM bundle',
      mandatory: true,
    );
}

Future<void> runVmCreate(ArgResults results) async {
  print('🖥  OpenCI VM — Create Bundle');
  print('   Bundle: ${results['bundle']}');
  print('   IPSW:   ${results['ipsw']}');
  print('');

  await MacVM.createBundle(
    bundlePath: results['bundle'] as String,
    ipswPath: results['ipsw'] as String,
    config: VMConfig(diskSizeGB: int.parse(results['disk-size'] as String)),
  );
  print('✅ Bundle created!');
}

Future<void> runVmInstall(ArgResults results) async {
  final vm = MacVM.open(
    results['bundle'] as String,
    config: VMConfig(
      cpuCount: int.parse(results['cpu'] as String),
      memoryGB: int.parse(results['memory'] as String),
    ),
  );
  print('🖥  OpenCI VM — Install');
  print('   Bundle: ${vm.bundlePath}');
  print('');
  await vm.install(
    ipswPath: results['ipsw'] as String,
    onOutput: (line) => stderr.writeln(line),
  );
  print('✅ macOS installed successfully!');
}

Future<void> runVmStart(ArgResults results) async {
  final vm = MacVM.open(
    results['bundle'] as String,
    config: VMConfig(
      cpuCount: int.parse(results['cpu'] as String),
      memoryGB: int.parse(results['memory'] as String),
    ),
  );
  final gui = results['gui'] as bool;
  print('🖥  OpenCI VM — Start${gui ? ' (GUI)' : ''}');
  print('   Bundle: ${vm.bundlePath}');
  print('');

  final process = await vm.start(
    gui: gui,
    onOutput: (line) => stderr.writeln(line),
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0 && exitCode != -1 && exitCode != -2) {
    print('❌ VM failed (exit code: $exitCode)');
    exit(1);
  }
}

Future<void> runVmSetup(ArgResults results) async {
  final bundlePath = results['bundle'] as String;
  final config = VMConfig(
    diskSizeGB: int.parse(results['disk-size'] as String),
    cpuCount: int.parse(results['cpu'] as String),
    memoryGB: int.parse(results['memory'] as String),
  );

  print('🖥  OpenCI VM — Full Setup');
  print('   Bundle: $bundlePath');
  print('');

  print('[1/3] Fetching latest macOS IPSW...');
  final ipswPath = '$bundlePath.ipsw';
  final ipsw = await MacOSRestoreImage.fetchLatest(
    destPath: ipswPath,
    onProgress: (p) {
      final pct = (p * 100).toStringAsFixed(1);
      stdout.write('\r   Downloading: $pct%');
    },
  );
  print('\n   ✅ IPSW ready: ${ipsw.path}');

  print('[2/3] Creating VM bundle and installing macOS...');
  await MacVM.create(
    bundlePath: bundlePath,
    ipswPath: ipsw.path,
    config: config,
    onOutput: (line) => stderr.writeln(line),
  );
  print('✅ VM setup complete!');
}

Future<void> runVmClone(ArgResults results) async {
  final source = MacVM.open(results['source'] as String);
  print('📋 OpenCI VM — Clone');
  print('   Source: ${source.bundlePath}');
  print('   Dest:   ${results['dest']}');
  print('');

  final clone = await source.clone(results['dest'] as String);
  print('✅ Clone created: ${clone.bundlePath}');
  print('   MACAddress: ${clone.macAddress}');
}
