import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:openci_build_job_processor/src/build_job_poller/claim_next_job.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class FakeOpenCiApiService implements OpenCiApiService {
  Response<Map<String, dynamic>>? responseToReturn;

  @override
  Future<Response<Map<String, dynamic>>> claimNextJob(
    Map<String, dynamic> body,
  ) async {
    return responseToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeOpenCiApiService apiService;

  setUp(() {
    apiService = FakeOpenCiApiService();
  });

  group('claimNextJob tests', () {
    test('returns BuildJob when job data is returned from API', () async {
      final now = DateTime.now().toIso8601String();
      final dummyJobMap = {
        'id': 'job-123',
        'buildRunId': 'run-456',
        'status': 'QUEUED',
        'owner': 'openci-org',
        'repo': 'openci',
        'workflowName': 'CI Workflow',
        'createdAt': now,
        'updatedAt': now,
        'steps': <dynamic>[],
      };

      apiService.responseToReturn = Response(
        http.Response('{}', 200),
        <String, dynamic>{'job': dummyJobMap},
      );

      final result = await claimNextJob(
        apiService: apiService,
        runsOnPattern: 'macos-*',
      );

      expect(result, isNotNull);
      expect(result?.id, equals('job-123'));
    });

    test('returns null when job in response body is null', () async {
      apiService.responseToReturn = Response(
        http.Response('{}', 200),
        <String, dynamic>{'job': null},
      );

      final result = await claimNextJob(
        apiService: apiService,
        runsOnPattern: 'macos-*',
      );

      expect(result, isNull);
    });

    test('throws Exception when API response is not successful', () async {
      apiService.responseToReturn = Response(
        http.Response('Internal Error', 500),
        null,
      );

      expect(
        () => claimNextJob(apiService: apiService, runsOnPattern: 'macos-*'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception when API response body is null', () async {
      apiService.responseToReturn = Response(http.Response('', 200), null);

      expect(
        () => claimNextJob(apiService: apiService, runsOnPattern: 'macos-*'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
