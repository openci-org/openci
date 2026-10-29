import 'package:dashboard/generated/logs/logs.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('append variables preserve Int64 precision and nullable step', () {
    final variables = AppendBuildLogVariables(
      teamId: 'team',
      runId: 'run',
      stepId: Optional<String>.optional(nativeFromJson, nativeToJson)
        ..value = null,
      expectedLastSequence: BigInt.parse('9007199254740992'),
      sequence: BigInt.parse('9007199254740993'),
      logId: 'd69b6d04-88ce-41bf-9812-f9016e85e711',
      source: 'worker',
      stream: 'stdout',
      message: '',
      occurredAt: Timestamp.fromJson('2026-01-01T01:02:03.123456Z'),
    );

    final json = variables.toJson();
    expect(json['expectedLastSequence'], '9007199254740992');
    expect(json['sequence'], '9007199254740993');
    expect(json.containsKey('stepId'), isTrue);
    expect(json['stepId'], isNull);
    expect(json['message'], isEmpty);
    expect(
      DateTime.parse(json['occurredAt'] as String),
      DateTime.utc(2026, 1, 1, 1, 2, 3, 123, 456),
    );
  });

  test(
    'log results preserve Int64 precision, timestamps and nullable fields',
    () {
      final result = GetBuildLogsData.fromJson({
        'run': {
          'id': 'run',
          'lastLogSequence': '9007199254740993',
          'logsExpireAt': null,
          'logs': [
            {
              'logId': 'd69b6d0488ce41bf9812f9016e85e711',
              'sequence': '9007199254740993',
              'stepId': null,
              'source': 'worker',
              'stream': 'stdout',
              'message': '開始\ncheckout',
              'occurredAt': '2026-01-01T01:02:03.123456Z',
              'createdAt': '2026-01-01T01:02:04.654321Z',
            },
          ],
        },
      });

      final run = result.run!;
      final log = run.logs.single;
      expect(run.lastLogSequence, BigInt.parse('9007199254740993'));
      expect(run.logsExpireAt, isNull);
      expect(log.sequence, run.lastLogSequence);
      expect(log.stepId, isNull);
      expect(log.message, '開始\ncheckout');
      expect(
        log.occurredAt.toDateTime(),
        DateTime.utc(2026, 1, 1, 1, 2, 3, 123, 456),
      );
      expect(
        log.createdAt.toDateTime(),
        DateTime.utc(2026, 1, 1, 1, 2, 4, 654, 321),
      );
    },
  );
}
