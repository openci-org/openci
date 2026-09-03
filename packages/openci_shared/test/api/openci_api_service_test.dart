import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('OpenCiApiService webhook task results', () {
    late List<http.Request> requests;
    late ChopperClient client;
    late OpenCiApiService api;

    setUp(() {
      requests = [];
      client = ChopperClient(
        baseUrl: Uri.parse('http://localhost:8080'),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{"success":true}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        converter: const JsonToTypeConverter(),
        services: [OpenCiApiService.create()],
      );
      api = client.getService<OpenCiApiService>();
    });

    tearDown(() => client.dispose());

    test('completeWebhookTask posts serialized BuildJob plans', () async {
      final plan = _buildJobPlan();

      final response = await api.completeWebhookTask('task-1', [plan]);

      expect(response.isSuccessful, isTrue);
      expect(requests, hasLength(1));
      expect(requests.single.method, equals('POST'));
      expect(
        requests.single.url.path,
        equals('/webhooks/tasks/task-1/complete'),
      );
      expect(
        jsonDecode(requests.single.body),
        equals({
          'jobs': [plan.toJson()],
        }),
      );
    });

    test('failWebhookTask posts the error message', () async {
      final response = await api.failWebhookTask(
        'task-1',
        'GitHub temporarily unavailable',
      );

      expect(response.isSuccessful, isTrue);
      expect(requests, hasLength(1));
      expect(requests.single.method, equals('POST'));
      expect(requests.single.url.path, equals('/webhooks/tasks/task-1/fail'));
      expect(
        jsonDecode(requests.single.body),
        equals({'errorMessage': 'GitHub temporarily unavailable'}),
      );
    });
  });
}

BuildJobPlan _buildJobPlan() {
  return const BuildJobPlan(
    owner: 'openci-owner',
    repo: 'openci-repo',
    workflowName: 'Dashboard CI',
    workflowFileName: 'dashboard_ci.dart',
    teamId: 'team-1',
    commitSha: 'commit-sha-1',
    branch: 'main',
    runsOn: 'macos-latest',
    githubBaseUrl: 'https://github.com',
    installationId: '98765',
  );
}
