// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  print('==================================================');
  print('🚀 Starting OpenCI Local Development Environment');
  print('==================================================');

  final rootDir = Directory.current;

  // 1. Check & Setup Tart base-macos image
  print('\n📦 Step 1: Checking Tart VM base image...');
  final tartListResult = await Process.run('tart', ['list'], runInShell: true);
  if (!tartListResult.stdout.toString().contains('base-macos')) {
    print(
      '⚠️ base-macos image not found. Creating from ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5...',
    );
    await _run('tart', ['pull', 'ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5']);
    await _run('tart', [
      'clone',
      'ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5',
      'base-macos',
    ]);
    print('✅ base-macos image created.');
  } else {
    print('✅ base-macos image exists.');
  }

  // 2. Start Docker Compose core services
  print(
    '\n🐳 Step 2: Starting Docker containers (db, orchard, server, build-job-dispatcher)...',
  );
  final composeEnv = {
    ...Platform.environment,
    'BASE_VM_NAME': Platform.environment['BASE_VM_NAME'] ?? 'base-macos',
    'INTERNAL_API_KEY':
        Platform.environment['INTERNAL_API_KEY'] ?? 'genuineci-local-dev-key',
    'ORCHARD_API_URL': 'https://orchard-controller:6120',
  };

  await _run(
    'docker',
    [
      'compose',
      'up',
      '-d',
      '--build',
      'db',
      'orchard-controller',
      'server',
      'build-job-dispatcher',
    ],
    environment: composeEnv,
  );

  // 3. Wait for Orchard Controller to be ready
  print('\n⏳ Step 3: Waiting for Orchard Controller to initialize...');
  await Future<void>.delayed(const Duration(seconds: 3));

  print('\n🔑 Step 4: Registering Orchard CLI context...');
  final tokenResult = await Process.run(
    'docker',
    [
      'exec',
      'openci-orchard-controller',
      'orchard',
      'get',
      'bootstrap-token',
      'bootstrap-admin',
    ],
  );

  final bootstrapToken = tokenResult.stdout.toString().trim();
  if (bootstrapToken.isNotEmpty && tokenResult.exitCode == 0) {
    await Process.run('orchard', [
      'context',
      'create',
      'https://127.0.0.1:6120',
      '--bootstrap-token',
      bootstrapToken,
      '--no-pki',
      '--force',
    ]);
    await Process.run('orchard', ['context', 'default', 'default']);
    print('✅ Orchard CLI context authenticated.');

    // Extract serviceAccountToken from ~/.orchard/orchard.yml
    final home = Platform.environment['HOME'] ?? '';
    final orchardConfigFile = File('$home/.orchard/orchard.yml');
    if (await orchardConfigFile.exists()) {
      final configContent = await orchardConfigFile.readAsString();
      final match = RegExp(
        r'serviceAccountToken:\s*([^\s\n]+)',
      ).firstMatch(configContent);
      final contextToken = match?.group(1);

      if (contextToken != null && contextToken.isNotEmpty) {
        print('🔄 Updating build-job-dispatcher with Orchard credentials...');

        // Update .env file if present
        final envFile = File('${rootDir.path}/.env');
        if (await envFile.exists()) {
          final lines = await envFile.readAsLines();
          var updated = false;
          final newLines = lines.map((line) {
            if (line.startsWith('ORCHARD_SERVICE_ACCOUNT_TOKEN=')) {
              updated = true;
              return 'ORCHARD_SERVICE_ACCOUNT_TOKEN=$contextToken';
            }
            return line;
          }).toList();

          if (!updated) {
            newLines.add('ORCHARD_SERVICE_ACCOUNT_TOKEN=$contextToken');
          }
          await envFile.writeAsString('${newLines.join('\n')}\n');
        }

        final updatedEnv = {
          ...composeEnv,
          'ORCHARD_SERVICE_ACCOUNT_NAME': 'bootstrap-admin',
          'ORCHARD_SERVICE_ACCOUNT_TOKEN': contextToken,
        };

        await _run(
          'docker',
          ['compose', 'up', '-d', '--force-recreate', 'build-job-dispatcher'],
          environment: updatedEnv,
        );
        print('✅ build-job-dispatcher authenticated with Orchard Controller.');
      }
    }
  } else {
    print(
      '⚠️ Could not auto-fetch Orchard bootstrap token. Context registration skipped.',
    );
  }

  // 4. Seed Database Test Data
  print('\n🌱 Step 5: Seeding test data to Database...');
  await _run('dart', ['run', 'tool/seed_local_data.dart']);

  print('\n==================================================');
  print('🎉 OpenCI Local Environment is Fully Ready!');
  print('==================================================\n');
  print(
    'All components (Server, DB, Orchard, Dispatcher) are running in Docker Compose!',
  );
  print('Dispatcher worker is automatically polling for queued jobs.\n');
  print('💡 To run local Orchard worker with multi-VM concurrency, execute:');
  print(
    'TOKEN=\$(docker exec openci-orchard-controller orchard get bootstrap-token bootstrap-admin) && orchard worker run https://127.0.0.1:6120 --bootstrap-token "\$TOKEN" --no-pki --default-cpu 2 --default-memory 4096 --resources org.cirruslabs.tart-vms=2\n',
  );
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    environment: environment,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      'Command failed with exit code $exitCode',
      exitCode,
    );
  }
}
