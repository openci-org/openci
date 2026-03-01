import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:openci_worker_cli/src/executor.dart';
import 'package:openci_worker_cli/src/supabase_client.dart';

const String version = '0.5.0';
const Duration pollingInterval = Duration(seconds: 10);

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('version', negatable: false)
    ..addOption('config', abbr: 'c', help: 'Path to config JSON or inline JSON')
    ..addOption(
      'golden',
      abbr: 'g',
      help: 'Path to golden VM bundle',
      mandatory: true,
    )
    ..addOption(
      'storage',
      abbr: 's',
      help: 'VM clone storage directory',
      mandatory: true,
    )
    ..addOption('ssh-user', defaultsTo: 'admin')
    ..addOption('ssh-password', defaultsTo: 'admin');

  final results = parser.parse(arguments);

  if (results.flag('help')) {
    print('OpenCI Worker v$version');
    print('');
    print(
      'Usage: openci_worker --config <json> --golden <path> --storage <path>',
    );
    print(parser.usage);
    return;
  }
  if (results.flag('version')) {
    print('openci_worker v$version');
    return;
  }

  final configArg = results['config'] as String?;
  if (configArg == null) {
    stderr.writeln('Error: --config is required');
    print(parser.usage);
    exit(1);
  }

  final config = _parseConfig(configArg);
  final supabaseUrl = config['supabaseUrl'] as String?;
  final supabaseKey = config['supabaseKey'] as String?;
  final workerId = config['workerId'] as String?;

  if (supabaseUrl == null || supabaseKey == null || workerId == null) {
    stderr.writeln(
      'Error: config must contain supabaseUrl, supabaseKey, workerId',
    );
    exit(1);
  }

  final goldenPath = results['golden'] as String;
  final storagePath = results['storage'] as String;

  if (!Directory(goldenPath).existsSync()) {
    stderr.writeln('❌ Golden image not found: $goldenPath');
    exit(1);
  }
  Directory(storagePath).createSync(recursive: true);

  final supabase = SupabaseWorkerClient(url: supabaseUrl, key: supabaseKey);
  final executor = BuildExecutor(
    goldenImagePath: goldenPath,
    vmStoragePath: storagePath,
    workerId: workerId,
    supabase: supabase,
    sshUser: results['ssh-user'] as String,
    sshPassword: results['ssh-password'] as String,
  );

  print('🚀 OpenCI Worker v$version');
  print('   Worker ID: $workerId');
  print('   Golden: $goldenPath');
  print('   Storage: $storagePath');
  print('   Host: ${Platform.localHostname}');
  print('');

  print('Cleaning up orphaned VMs...');
  final cleaned = await executor.cleanupOrphanedVMs();
  if (cleaned.isNotEmpty) {
    print('  Cleaned ${cleaned.length} orphaned VM(s)');
  }

  print('Polling for jobs...');

  final spinnerChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  var spinnerIndex = 0;
  var waitingStart = DateTime.now();
  var completedCount = 0;

  ProcessSignal.sigint.watch().listen((_) {
    print('\n🛑 Shutting down...');
    supabase.dispose();
    exit(0);
  });

  while (true) {
    try {
      final builds = await supabase.fetchQueuedBuilds();

      if (builds.isNotEmpty) {
        final build = await supabase.claimNextBuild(workerId);

        if (build != null) {
          print('\n📦 Build claimed: ${build.githubOwner}/${build.githubRepo}');
          print('   ID: ${build.id.substring(0, 8)}');
          if (build.branch != null) print('   Branch: ${build.branch}');
          if (build.commitSha != null) {
            print('   Commit: ${build.commitSha!.substring(0, 7)}');
          }
          print('');

          final result = await executor.execute(
            build,
            onLog: (msg) {
              print('  $msg');
            },
          );

          completedCount++;
          final icon = result == 'success' ? '✅' : '❌';
          print('\n$icon Build ${build.id.substring(0, 8)}: $result');
          print('   Completed: $completedCount total');
          print('');
          waitingStart = DateTime.now();
          continue;
        }
      }
    } catch (e) {
      print('\n⚠️  Error: $e');
    }

    final elapsed = DateTime.now().difference(waitingStart);
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    stdout.write(
      '\r${spinnerChars[spinnerIndex]} [$workerId] Waiting for jobs... (${m}m ${s}s) | Completed: $completedCount  ',
    );
    spinnerIndex = (spinnerIndex + 1) % spinnerChars.length;

    await Future<void>.delayed(pollingInterval);
  }
}

Map<String, dynamic> _parseConfig(String arg) {
  try {
    if (arg.trim().startsWith('{')) {
      return jsonDecode(arg) as Map<String, dynamic>;
    }
    final file = File(arg);
    if (!file.existsSync()) {
      stderr.writeln('Config file not found: $arg');
      exit(1);
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('Error parsing config: $e');
    exit(1);
  }
}
