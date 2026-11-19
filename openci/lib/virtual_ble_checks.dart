import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

/// Both callers use the SDK package as their workflow's working directory.
Future<void> runVirtualBleChecks(OpenCI ci) async {
  const example = 'packages/openci_virtual_ble/example';
  await ci.dart.test(paths: ['integration_test/virtual_ble_test.dart']);
  await ci.flutter.pubGet(dir: example, enforceLockfile: true);
  await ci.flutter.staticAnalysis(dir: example, noPub: true);
  final output = await ci.patrol.testWithVirtualBle(
    dir: example,
    target: 'patrol_test/round_trip_test.dart',
    bundleId: 'org.openci.virtualBleExample',
    serviceUuid: 'BE110001-5D9F-4810-8692-47717E010001',
    characteristicUuid: 'BE110002-5D9F-4810-8692-47717E010001',
    resultJsonFile: 'openci-virtual-ble-result.json',
  );

  Future<Map<String, dynamic>> evidence(String role) async {
    final file = File.fromUri(output.uri.resolve('$role.json'));
    final result =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (result['role'] != role) {
      throw StateError('Unexpected $role evidence: $result');
    }
    return result;
  }

  final a = await evidence('A');
  final b = await evidence('B');
  final value = a['acknowledged'];
  if (value is! String ||
      !RegExp(r'^[a-f0-9]{32}$').hasMatch(value) ||
      value != b['received'] ||
      value != b['acknowledged'] ||
      value != a['received']) {
    throw StateError('Round-trip mismatch: $a / $b');
  }
  stdout.writeln(
    'Virtual GATT round trip: A sent $value, B received and echoed it, A received it back.',
  );
}
