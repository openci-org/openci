import 'dart:io';

import 'package:args/args.dart';
import 'package:openci_agent/agent_server.dart';
import 'package:openci_agent/vm_manager.dart';
import 'package:relic/relic.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8080')
    ..addOption(
      'golden',
      abbr: 'g',
      help: 'Path to golden VM bundle',
      mandatory: true,
    )
    ..addOption(
      'storage',
      abbr: 's',
      help: 'Directory to store VM clones',
      mandatory: true,
    )
    ..addOption('ssh-user', defaultsTo: 'admin')
    ..addOption('ssh-password', defaultsTo: 'admin');

  final results = parser.parse(args);
  final goldenPath = results['golden'] as String;
  final storagePath = results['storage'] as String;
  final port = int.parse(results['port'] as String);

  if (!Directory(goldenPath).existsSync()) {
    stderr.writeln('❌ Golden image not found: $goldenPath');
    exit(1);
  }
  Directory(storagePath).createSync(recursive: true);

  final vmManager = VMManager(
    goldenImagePath: goldenPath,
    vmStoragePath: storagePath,
    sshUser: results['ssh-user'] as String,
    sshPassword: results['ssh-password'] as String,
  );

  final app = RelicApp()..use('/', logRequests());
  AgentServer(vmManager).mount(app);
  await app.serve(address: InternetAddress.anyIPv4, port: port);

  print('🖥  OpenCI Agent');
  print('   http://0.0.0.0:$port');
  print('   Golden: $goldenPath');
  print('   Storage: $storagePath');

  ProcessSignal.sigint.watch().listen((_) async {
    print('\n🛑 Shutting down...');
    await vmManager.shutdown();
    exit(0);
  });
}
