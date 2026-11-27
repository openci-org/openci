import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../ios_simulator.dart';
import '../virtual_ble/virtual_ble.dart';

const _startupTimeout = Duration(minutes: 10);
const _publicationTimeout = Duration(minutes: 8);
const _completionTimeout = Duration(minutes: 10);

Future<Directory> runVirtualBlePatrol({
  required Directory directory,
  required String bundleId,
  required String serviceUuid,
  required String characteristicUuid,
  required String? resultJsonFile,
  required String pythonExecutable,
}) async {
  final products = Directory.fromUri(
    directory.uri.resolve('build/ios_integ/Build/Products/'),
  );
  final spec = await _simulatorTestSpec(products);
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
    // Patrol CLI uses a one-second destination timeout. Xcode can take longer
    // to discover a freshly booted simulator on a CI Mac.
    final process = await Process.start(
      'xcodebuild',
      [
        'test-without-building',
        '-xctestrun',
        spec.path,
        '-destination',
        'platform=iOS Simulator,id=${device.id}',
        '-destination-timeout',
        '90',
        '-only-testing:RunnerUITests',
        '-parallel-testing-enabled',
        'NO',
        '-resultBundlePath',
        p.join(output.path, '${peer.name.toUpperCase()}.xcresult'),
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

  Future<void> waitForPublication(VirtualBlePeer peer, Future<void> finished) {
    return Future.any([
      radio.waitForPeer(
        peer,
        connectionTimeout: _startupTimeout,
        timeout: _publicationTimeout,
      ),
      finished.then(
        (_) => throw StateError(
          'Patrol finished before peer ${peer.name.toUpperCase()} published',
        ),
      ),
    ]);
  }

  try {
    final app = Directory.fromUri(
      products.uri.resolve('Debug-iphonesimulator/Runner.app/'),
    );
    // B waits in its UI test through A's startup, publication and UI update.
    final peerWait =
        _startupTimeout + _publicationTimeout + const Duration(minutes: 1);
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
        jsonEncode({
          'endpoint': radio.endpoint(peer).toString(),
          if (peer == VirtualBlePeer.b)
            'peerWaitTimeoutSeconds': peerWait.inSeconds,
        }),
      );
    }
    final b = report(VirtualBlePeer.b, await start(VirtualBlePeer.b));
    await waitForPublication(VirtualBlePeer.b, b);
    final a = report(VirtualBlePeer.a, await start(VirtualBlePeer.a));
    final finished = Future.wait([a, b], eagerError: true);
    await waitForPublication(VirtualBlePeer.a, finished);
    await finished.timeout(
      _completionTimeout,
      onTimeout: () => throw TimeoutException(
        'Patrol did not finish after both peers published their GATT values',
        _completionTimeout,
      ),
    );
    return output;
  } finally {
    // Stop any remaining XCTest run and shut down both devices on failure.
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

Future<File> _simulatorTestSpec(Directory products) async {
  const arguments = ['--sdk', 'iphonesimulator', '--show-sdk-version'];
  final sdk = await runSimulatorProcess(
    'xcrun',
    arguments,
    timeout: const Duration(minutes: 1),
  );
  if (sdk.exitCode != 0) {
    throw ProcessException(
      'xcrun',
      arguments,
      sdk.stderr.toString(),
      sdk.exitCode,
    );
  }
  final pattern = Glob(
    'Runner_*iphonesimulator${sdk.stdout.toString().trim()}*.xctestrun',
  );
  final specs = await products
      .list()
      .where((file) => file is File && pattern.matches(p.basename(file.path)))
      .cast<File>()
      .toList();
  if (specs.isEmpty) {
    throw StateError(
      'Patrol build produced no ${pattern.pattern} in ${products.path}',
    );
  }
  specs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return specs.first;
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
  Future<void> forward(Stream<List<int>> stream, IOSink console) async {
    await for (final line
        in stream
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())) {
      log.writeln(line);
      console.writeln('[$role] $line');
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
        'xcodebuild',
        ['test-without-building'],
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
  }
}
