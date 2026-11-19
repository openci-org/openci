import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../ios_simulator.dart';
import '../virtual_ble/virtual_ble.dart';

Future<Directory> runVirtualBlePatrol({
  required Directory directory,
  required String target,
  required String bundleId,
  required String serviceUuid,
  required String characteristicUuid,
  required String? resultJsonFile,
  required String pythonExecutable,
}) async {
  final artifacts = Directory.fromUri(
    directory.uri.resolve('build/virtual_ble/'),
  );
  await artifacts.create(recursive: true);
  final output = await artifacts.createTemp('round-trip-');
  final radio = await startVirtualBle(
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    pythonExecutable: pythonExecutable,
  );
  final simulators = <VirtualBlePeer, IosSimulator>{};
  final active = <Process>{};
  final reports = <Future<void>>[];

  Future<Process> start(VirtualBlePeer peer) async {
    final device = simulators[peer]!;
    stdout.writeln(
      'Running Patrol on ${peer.name.toUpperCase()} (${device.id})',
    );
    final process = await Process.start(
      'dart',
      [
        'run',
        'patrol_cli:main',
        'test-without-building',
        '--device',
        device.id,
        '--only',
        target,
      ],
      workingDirectory: directory.path,
    );
    active.add(process);
    unawaited(
      process.exitCode.then((_) {
        active.remove(process);
      }),
    );
    return process;
  }

  Future<void> report(VirtualBlePeer peer, Process process) {
    final done = _collect(
      process,
      peer.name.toUpperCase(),
      simulators[peer]!,
      bundleId,
      resultJsonFile,
      output,
    );
    reports.add(done);
    return done;
  }

  try {
    final app = Directory.fromUri(
      directory.uri.resolve(
        'build/ios_integ/Build/Products/Debug-iphonesimulator/Runner.app/',
      ),
    );
    for (final peer in VirtualBlePeer.values) {
      final simulator = await launchIosSimulator(
        name: 'OpenCI Virtual BLE ${peer.name.toUpperCase()}',
      );
      simulators[peer] = simulator;
      await simulator.installApp(app);
      final container = await simulator.appDataDirectory(bundleId);
      final config = File.fromUri(
        container.uri.resolve('tmp/openci-virtual-ble.json'),
      );
      await config.writeAsString(
        jsonEncode({'endpoint': radio.endpoint(peer).toString()}),
      );
    }
    final b = report(VirtualBlePeer.b, await start(VirtualBlePeer.b));
    await Future.any([
      radio.waitForPeer(VirtualBlePeer.b, timeout: const Duration(minutes: 8)),
      b.then(
        (_) => throw StateError('B exited before the second peer started'),
      ),
    ]);
    final a = report(VirtualBlePeer.a, await start(VirtualBlePeer.a));
    await Future.wait([
      a,
      b,
      radio.waitForPeer(VirtualBlePeer.a, timeout: const Duration(minutes: 8)),
    ], eagerError: true).timeout(const Duration(minutes: 10));
    return output;
  } finally {
    // If either run fails, let Patrol stop its xcodebuild and shut down both devices.
    for (final process in active) {
      process.kill(ProcessSignal.sigint);
    }
    try {
      await Future.wait([
        radio.dispose(),
        ...simulators.values.map((s) => s.dispose()),
      ]);
    } finally {
      final drained = Future.wait(
        reports.map((r) => r.catchError((Object _) {})),
      );
      try {
        await drained.timeout(const Duration(seconds: 10));
      } on TimeoutException {
        for (final process in active) {
          process.kill(ProcessSignal.sigkill);
        }
        await drained.timeout(const Duration(seconds: 10));
      }
    }
  }
}

Future<void> _collect(
  Process process,
  String role,
  IosSimulator simulator,
  String bundleId,
  String? resultJsonFile,
  Directory output,
) async {
  stdout.writeln('Patrol results for $role: ${output.path}/$role.log');
  final log = File.fromUri(output.uri.resolve('$role.log')).openWrite();
  final reportLine = RegExp(r'📊 Report: (.+\.xcresult)\s*$');
  String? bundle;
  Future<void> forward(Stream<List<int>> stream, IOSink console) async {
    await for (final line
        in stream
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())) {
      log.writeln(line);
      console.writeln('[$role] $line');
      final match = reportLine.firstMatch(line);
      if (match != null) bundle = match[1];
    }
  }

  try {
    final code = process.exitCode;
    await Future.wait([
      forward(process.stdout, stdout),
      forward(process.stderr, stderr),
    ]);
    final exitCode = await code;
    if (exitCode != 0) {
      throw ProcessException(
        'dart',
        ['run', 'patrol_cli:main', 'test-without-building'],
        'Patrol failed on $role. See ${output.path}/$role.log',
        exitCode,
      );
    }
    if (resultJsonFile != null) {
      // Resolve again after XCTest installs and launches the app.
      final data = await simulator.appDataDirectory(bundleId);
      final evidence = File(p.join(data.path, 'tmp', resultJsonFile));
      await evidence.copy(p.join(output.path, '$role.json'));
    }
  } finally {
    await log.close();
    final path = bundle;
    if (path != null && await Directory(path).exists()) {
      await Link(
        p.join(output.path, '$role.xcresult'),
      ).create(p.relative(path, from: output.path));
    }
  }
}
