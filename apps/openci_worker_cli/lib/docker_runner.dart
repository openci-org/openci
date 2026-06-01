import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/logger.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Docker');

String containerName({required String workerId, required String buildJobId}) {
  final shortId = buildJobId.length >= 8
      ? buildJobId.substring(0, 8)
      : buildJobId;
  return 'openci-$workerId-$shortId';
}

Future<void> createContainer(String name) async {
  _log.info('Creating container $name from $dockerImage...');
  final result = await Process.run('docker', [
    'create',
    '--name',
    name,
    '-v',
    '/var/run/docker.sock:/var/run/docker.sock',
    dockerImage,
  ]);
  if (result.exitCode != 0) {
    throw Exception('Failed to create container $name: ${result.stderr}');
  }
}

Future<void> startContainer(String name) async {
  _log.info('Starting container $name...');
  final result = await Process.run('docker', ['start', name]);
  if (result.exitCode != 0) {
    throw Exception('Failed to start container $name: ${result.stderr}');
  }
}

Future<void> execInContainer({
  required String name,
  required String command,
  required String buildJobId,
  required String runId,
  required String token,
}) async {
  final result = await Process.run('docker', [
    'exec',
    name,
    'bash',
    '-c',
    command,
  ]);

  final stdout = result.stdout?.toString().trim();
  final stderr = result.stderr?.toString().trim();

  if (stdout != null && stdout.isNotEmpty) {
    final masked = stdout.replaceAll(token, '***');
    await logInfo(buildJobId, runId, masked);
  }
  if (stderr != null && stderr.isNotEmpty) {
    final masked = stderr.replaceAll(token, '***');
    await logInfo(buildJobId, runId, masked);
  }

  if (result.exitCode != 0) {
    throw Exception('Command failed with exit code ${result.exitCode}');
  }
}

Future<void> copyToContainer(
  String name,
  String localPath,
  String remotePath,
) async {
  final result = await Process.run('docker', [
    'cp',
    localPath,
    '$name:$remotePath',
  ]);
  if (result.exitCode != 0) {
    throw Exception(
      'Failed to copy $localPath to $name:$remotePath: ${result.stderr}',
    );
  }
}

Future<void> writeFileToContainer(
  String name,
  String remotePath,
  String content,
) async {
  // Write to a temp file, then docker cp
  final tmpFile = File(
    '/tmp/openci-tmp-${DateTime.now().millisecondsSinceEpoch}',
  );
  await tmpFile.writeAsString(content);
  try {
    await copyToContainer(name, tmpFile.path, remotePath);
  } finally {
    await tmpFile.delete();
  }
}

final _gitProgressPattern = RegExp(
  r'^(remote: )?(Counting|Compressing|Receiving|Resolving|Updating) objects?:',
);

bool _isNoisyLine(String line) {
  if (_gitProgressPattern.hasMatch(line)) return true;
  if (line.startsWith('remote: Enumerating objects:')) return true;
  return false;
}

bool _isActError(String line) {
  final lower = line.toLowerCase();
  if (lower.contains("'runs-on' key not defined")) return true;
  if (lower.contains('level=error') && !lower.contains('cve-')) return true;
  if (lower.contains('❌')) return true;
  return false;
}

Future<void> execStreamingInContainer(
  String name,
  List<String> command,
  String buildJobId,
  String runId,
  String token, {
  required Future<bool> Function() isCancelled,
}) async {
  final process = await Process.start('docker', ['exec', name, ...command]);

  await process.stdin.close();

  final stdoutCompleter = Completer<void>();
  final stderrCompleter = Completer<void>();
  final outputErrors = <String>[];
  var hasSuccessfulStep = false;

  void processLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || _isNoisyLine(trimmed)) return;

    if (trimmed.contains('✅') || trimmed.contains('Job succeeded')) {
      hasSuccessfulStep = true;
    }

    if (_isActError(trimmed)) {
      outputErrors.add(trimmed);
    }

    logInfo(buildJobId, runId, trimmed);
  }

  process.stdout.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        processLine(line);
      }
    }
  }, onDone: () => stdoutCompleter.complete());

  process.stderr.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        processLine(line);
      }
    }
  }, onDone: () => stderrCompleter.complete());

  final cancelTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (await isCancelled()) {
      process.kill(ProcessSignal.sigterm);
    }
  });

  final exitCode = await process.exitCode;
  cancelTimer.cancel();
  await stdoutCompleter.future;
  await stderrCompleter.future;

  if (exitCode != 0) {
    throw Exception('act exited with code $exitCode');
  }

  if (outputErrors.isNotEmpty) {
    throw Exception('act reported errors:\n${outputErrors.join('\n')}');
  }

  if (!hasSuccessfulStep) {
    throw Exception(
      'act exited with code 0 but no steps were executed. '
      'Check that your workflow has a valid runs-on key.',
    );
  }
}

Future<void> stopAndRemoveContainer(String name) async {
  _log.info('Stopping container $name...');
  await Process.run('docker', ['stop', name]);
  _log.info('Removing container $name...');
  await Process.run('docker', ['rm', '-f', name]);
}

Future<void> cleanupOrphanedContainers(String workerId) async {
  try {
    _log.info('Cleaning orphaned containers...');
    final prefix = 'openci-$workerId-';

    final result = await Process.run('docker', [
      'ps',
      '-a',
      '--format',
      '{{.Names}}',
      '--filter',
      'name=$prefix',
    ]);

    if (result.exitCode != 0) return;

    final containers = LineSplitter.split(
      result.stdout.toString(),
    ).where((name) => name.isNotEmpty).toList();

    for (final container in containers) {
      _log.info('Removing orphaned container: $container');
      await stopAndRemoveContainer(container);
    }

    if (containers.isNotEmpty) {
      _log.info('Removed ${containers.length} orphaned container(s)');
    }
  } catch (e, s) {
    _log.severe('Error cleaning up orphaned containers: $e');
    await Sentry.captureException(e, stackTrace: s);
  }
}

Future<void> pruneStaleContainers(
  String buildJobId,
  String runId, {
  required String workerId,
}) async {
  try {
    final prefix = 'openci-$workerId-';
    final current = containerName(workerId: workerId, buildJobId: buildJobId);

    final result = await Process.run('docker', [
      'ps',
      '-a',
      '--format',
      '{{.Names}}',
      '--filter',
      'name=$prefix',
    ]);

    if (result.exitCode != 0) return;

    final containers = LineSplitter.split(
      result.stdout.toString(),
    ).where((name) => name.isNotEmpty && name != current).toList();

    for (final container in containers) {
      await logInfo(
        buildJobId,
        runId,
        'Removing stale container: $container',
      );
      await stopAndRemoveContainer(container);
    }
  } catch (e) {
    await logWarning(
      buildJobId,
      runId,
      'Error pruning stale containers: $e',
    );
  }
}
