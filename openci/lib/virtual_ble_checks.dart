import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

const _example = 'packages/openci_virtual_ble/example';

/// The SDK and its example are exercised from this checkout, including for CD.
Future<void> runVirtualBleChecks(OpenCI ci) async {
  await ci.run(
    'dart test integration_test/virtual_ble_test.dart',
    workingDirectory: 'packages/openci_workflow',
  );
  await ci.run(
    'flutter pub get --enforce-lockfile',
    workingDirectory: _example,
  );
  await ci.run('flutter analyze --no-pub', workingDirectory: _example);
  await ci.run(
    'dart run patrol_cli:main build ios --simulator --target patrol_test/round_trip_test.dart',
    workingDirectory: _example,
  );
  await runVirtualBleExample(ci);
}

Future<void> runVirtualBleExample(OpenCI ci) async {
  final directory = Directory('${ci.workspacePath}/$_example').absolute.path;
  final artifacts = await Directory(
    '$directory/build/virtual_ble',
  ).create(recursive: true);
  final output = await artifacts.createTemp('round-trip-');
  final radio = await ci.startVirtualBle(
    serviceUuid: 'BE110001-5D9F-4810-8692-47717E010001',
    characteristicUuid: 'BE110002-5D9F-4810-8692-47717E010001',
  );
  final simulators = <IosSimulator>[];
  final drivers = <Process>[];

  Future<Process> start(IosSimulator sim, VirtualBlePeer peer) async {
    final process = await Process.start(
      'python3.13',
      [
        'tool/run_peer.py',
        sim.id,
        radio.endpoint(peer).toString(),
        output.absolute.path,
      ],
      workingDirectory: directory,
      mode: ProcessStartMode.inheritStdio,
    );
    drivers.add(process);
    return process;
  }

  Future<void> finish(Process process, VirtualBlePeer peer) async {
    try {
      final code = await process.exitCode;
      if (code != 0) {
        throw StateError('Patrol on ${peer.name} exited with $code');
      }
    } finally {
      drivers.remove(process);
    }
  }

  try {
    for (final peer in VirtualBlePeer.values) {
      simulators.add(
        await ci.launchIosSimulator(
          name: 'OpenCI Virtual BLE ${peer.name.toUpperCase()}',
        ),
      );
    }
    final b = finish(
      await start(simulators[1], VirtualBlePeer.b),
      VirtualBlePeer.b,
    );
    await Future.any([
      radio.waitForPeer(VirtualBlePeer.b, timeout: const Duration(minutes: 8)),
      b.then(
        (_) => throw StateError('B exited before publishing its GATT value'),
      ),
    ]);
    final a = await start(simulators[0], VirtualBlePeer.a);
    await Future.wait([
      b,
      finish(a, VirtualBlePeer.a),
    ], eagerError: true);
    final aResult =
        jsonDecode(await File('${output.path}/A.json').readAsString()) as Map;
    final bResult =
        jsonDecode(await File('${output.path}/B.json').readAsString()) as Map;
    final value = aResult['acknowledged'];
    if (value is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(value) ||
        value != bResult['received'] ||
        value != bResult['acknowledged'] ||
        value != aResult['received']) {
      throw StateError('Round-trip mismatch: $aResult / $bResult');
    }
    stdout.writeln(
      'Virtual GATT round trip: A sent $value, B received and echoed it, A received it back.',
    );
    stdout.writeln('XCTest results: ${output.path}');
  } finally {
    final running = drivers.toList();
    for (final driver in running) {
      driver.kill();
    }
    try {
      await Future.wait(running.map((driver) => driver.exitCode));
    } finally {
      await Future.wait([
        radio.dispose(),
        ...simulators.map((simulator) => simulator.dispose()),
      ]);
    }
  }
}
