import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:openci_orchestrator/agent/agent_server.dart';
import 'package:openci_orchestrator/agent/vm_manager.dart';
import 'package:openci_orchestrator/central/agent_registry.dart';
import 'package:openci_orchestrator/central/central_server.dart';
import 'package:relic/relic.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final mode = args.first;
  final rest = args.sublist(1);

  switch (mode) {
    case 'agent':
      await _runAgent(rest);
    case 'central':
      await _runCentral(rest);
    default:
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  print('OpenCI Orchestrator');
  print('');
  print('Usage:');
  print('  orchestrator agent   --golden <path> --storage <path>');
  print('  orchestrator central --config <path>');
}

Future<void> _runAgent(List<String> args) async {
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

Future<void> _runCentral(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '9090')
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to agents config JSON',
      mandatory: true,
    );

  final results = parser.parse(args);
  final port = int.parse(results['port'] as String);
  final configPath = results['config'] as String;

  final configFile = File(configPath);
  if (!configFile.existsSync()) {
    stderr.writeln('❌ Config file not found: $configPath');
    exit(1);
  }

  final config =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final agents = config['agents'] as List;

  final registry = AgentRegistry();
  for (final agent in agents) {
    final a = agent as Map<String, dynamic>;
    registry.register(
      a['id'] as String,
      a['url'] as String,
      maxVMs: a['max_vms'] as int? ?? 4,
    );
  }

  final app = RelicApp()..use('/', logRequests());
  CentralServer(registry).mount(app);
  await app.serve(address: InternetAddress.anyIPv4, port: port);

  print('🚀 OpenCI Central Orchestrator');
  print('   http://0.0.0.0:$port');
  print('   Agents: ${registry.allAgents.length}');
  for (final agent in registry.allAgents) {
    print('     - ${agent.id}: ${agent.url} (max ${agent.maxVMs} VMs)');
  }
  print('');
  print('   POST   /vms                      → Create VM (auto-schedule)');
  print('   GET    /vms                      → List all VMs');
  print('   GET    /agents                   → List agents');
  print('   POST   /vms/:agentId/:vmId/exec  → Exec command');
  print('   DELETE /vms/:agentId/:vmId       → Delete VM');

  ProcessSignal.sigint.watch().listen((_) {
    print('\n🛑 Shutting down...');
    registry.dispose();
    exit(0);
  });
}
