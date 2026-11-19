import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openci_virtual_ble_example/main.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'two simulators exchange a fresh GATT value',
    ($) async {
      final directory = Directory.systemTemp;
      final config = jsonDecode(
        await File('${directory.path}/openci-virtual-ble.json').readAsString(),
      );
      final endpoint = config['endpoint'] as String;
      final role = Uri.parse(endpoint).path.substring(1);
      await $.pumpWidget(BleExample(endpoint: endpoint));
      await $('Connect').tap();
      await $('Peer: ${role == 'A' ? 'B' : 'A'}').waitUntilVisible();
      final received = $(const ValueKey('received'));
      if (role == 'B') await received.waitUntilVisible();
      await $(role == 'A' ? 'Send fresh value' : 'Echo received value').tap();
      final acknowledged = $(const ValueKey('acknowledged'));
      await acknowledged.waitUntilVisible();
      await received.waitUntilVisible();
      final sent = $.tester.widget<Text>(acknowledged.finder).data!;
      final value = $.tester.widget<Text>(received.finder).data!;
      expect(value, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(sent, value);
      await File(
        '${directory.path}/openci-virtual-ble-result.json',
      ).writeAsString(
        jsonEncode({'role': role, 'received': value, 'acknowledged': sent}),
        flush: true,
      );
    },
    config: const PatrolTesterConfig(visibleTimeout: Duration(minutes: 4)),
  );
}
