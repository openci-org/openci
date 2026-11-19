import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late OpenCI ci;
  setUp(() async {
    ci = await OpenCI.init(workflowName: 'Test', ciTriggers: []);
  });
  const valid = '8ED90000-1242-4730-9012-AABBCCDDEEFF';
  test('rejects invalid UUIDs before launching Python', () async {
    for (final values in [('1234', valid), (valid, 'not-a-uuid')]) {
      await expectLater(
        ci.startVirtualBle(
          serviceUuid: values.$1,
          characteristicUuid: values.$2,
        ),
        throwsArgumentError,
      );
    }
  });
  test('reports an unavailable Python executable', () async {
    await expectLater(
      ci.startVirtualBle(
        serviceUuid: valid,
        characteristicUuid: valid,
        pythonExecutable: '/missing/openci/python',
      ),
      throwsA(isA<ProcessException>()),
    );
  });
}
