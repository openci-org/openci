import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:openci_orchestrator/central/agent_registry.dart';
import 'package:openci_orchestrator/central/central_server.dart';
import 'package:relic/relic.dart';

Future<void> main(List<String> args) async {
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

  print('🚀 OpenCI Orchestrator');
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
