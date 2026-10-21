import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('BuildJob.displayMatrixLabel', () {
    final cases =
        <
          ({
            String name,
            String? label,
            Map<String, Object?>? matrix,
            String? expected,
          })
        >[
          (
            name: 'prefers an explicit label over the matrix name',
            label: 'Release build',
            matrix: {'name': 'macOS', 'version': 3},
            expected: 'Release build',
          ),
          (
            name: 'uses the matrix name when the explicit label is empty',
            label: '',
            matrix: {'os': 'macOS', 'name': 'Stable build'},
            expected: 'Stable build',
          ),
          (
            name: 'returns null without a matrix',
            label: null,
            matrix: null,
            expected: null,
          ),
          (
            name: 'returns null for an empty matrix',
            label: null,
            matrix: {},
            expected: null,
          ),
          (
            name: 'joins matrix values in their declared order',
            label: null,
            matrix: {'os': 'macOS', 'version': 3, 'release': true},
            expected: 'macOS / 3 / true',
          ),
          (
            name: 'includes a non-string name in the joined values',
            label: null,
            matrix: {'name': 42, 'os': 'macOS'},
            expected: '42 / macOS',
          ),
        ];

    for (final value in cases) {
      test(value.name, () {
        final job = BuildJob(
          id: 'job-1',
          status: BuildJobStatus.QUEUED,
          owner: 'openci-org',
          repo: 'openci',
          workflowName: 'CI',
          workflowFileName: 'ci.dart',
          matrixLabel: value.label,
          matrix: value.matrix,
          createdAt: DateTime.utc(2026, 9, 7),
          updatedAt: DateTime.utc(2026, 9, 7),
        );

        expect(job.displayMatrixLabel, value.expected);
      });
    }
  });

  group('BuildJob JSON', () {
    test('reads execution fields and writes timestamps in UTC', () {
      final job = BuildJob.fromJson({
        ..._jobJson(),
        'teamId': 'team-1',
        'commitSha': 'abc123',
        'runCount': 2,
        'latestRunId': 'run-2',
        'runsOn': 'macos',
        'matrix': {'os': 'macOS', 'version': 3, 'release': true},
        'needs': ['lint', 'test'],
        'vmName': 'vm-1',
        'workerHost': 'worker-1',
        'billingAdmissionId': 'admission-1',
        'createdAt': '2026-09-07T09:00:00+09:00',
        'updatedAt': '2026-09-07T09:01:00+09:00',
        'completedAt': '2026-09-07T09:02:00+09:00',
      });

      expect(job.teamId, 'team-1');
      expect(job.commitSha, 'abc123');
      expect(job.runCount, 2);
      expect(job.latestRunId, 'run-2');
      expect(job.runsOn, 'macos');
      expect(job.matrix, {'os': 'macOS', 'version': 3, 'release': true});
      expect(job.needs, ['lint', 'test']);
      expect(job.vmName, 'vm-1');
      expect(job.workerHost, 'worker-1');
      expect(job.billingAdmissionId, 'admission-1');
      expect(job.createdAt, DateTime.utc(2026, 9, 7));
      expect(job.updatedAt, DateTime.utc(2026, 9, 7, 0, 1));
      expect(job.completedAt, DateTime.utc(2026, 9, 7, 0, 2));

      final encoded = jsonDecode(jsonEncode(job)) as Map<String, dynamic>;
      expect(encoded['createdAt'], '2026-09-07T00:00:00.000Z');
      expect(encoded['updatedAt'], '2026-09-07T00:01:00.000Z');
      expect(encoded['completedAt'], '2026-09-07T00:02:00.000Z');
      expect(encoded['matrix'], {'os': 'macOS', 'version': 3, 'release': true});
      expect(encoded['needs'], ['lint', 'test']);
      expect(BuildJob.fromJson(encoded), job);
    });

    test('accepts omitted optional fields in a minimal response', () {
      final job = BuildJob.fromJson(_jobJson());

      expect(job.id, 'job-1');
      expect(job.workflowFileName, 'ci.dart');
      expect(job.completedAt, isNull);
      expect(job.matrix, isNull);
      expect(job.needs, isNull);
      expect(job.vmName, isNull);
      expect(job.workerHost, isNull);
      expect(job.billingAdmissionId, isNull);
      expect(job.toJson()['completedAt'], isNull);
    });

    const statuses = {
      'WAITING': BuildJobStatus.WAITING,
      'QUEUED': BuildJobStatus.QUEUED,
      'IN_PROGRESS': BuildJobStatus.IN_PROGRESS,
      'SUCCESS': BuildJobStatus.SUCCESS,
      'FAILURE': BuildJobStatus.FAILURE,
      'CANCELLED': BuildJobStatus.CANCELLED,
      'SKIPPED': BuildJobStatus.SKIPPED,
      'TIMED_OUT': BuildJobStatus.TIMED_OUT,
    };
    for (final entry in statuses.entries) {
      test('preserves the wire status ${entry.key}', () {
        final job = BuildJob.fromJson({..._jobJson(), 'status': entry.key});

        expect(job.status, entry.value);
        expect(job.toJson()['status'], entry.key);
      });
    }

    test('rejects an unknown status', () {
      expect(
        () => BuildJob.fromJson({..._jobJson(), 'status': 'UNKNOWN'}),
        throwsArgumentError,
      );
    });

    test('rejects a missing required job ID', () {
      final json = _jobJson()..remove('id');

      expect(() => BuildJob.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('rejects a malformed timestamp', () {
      expect(
        () => BuildJob.fromJson({..._jobJson(), 'createdAt': 'invalid-date'}),
        throwsFormatException,
      );
    });
  });
}

Map<String, Object?> _jobJson() => {
  'id': 'job-1',
  'status': 'SUCCESS',
  'owner': 'openci-org',
  'repo': 'openci',
  'workflowName': 'CI',
  'workflowFileName': 'ci.dart',
  'createdAt': '2026-09-07T00:00:00.000Z',
  'updatedAt': '2026-09-07T00:01:00.000Z',
};
