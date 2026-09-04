import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('OpenCiApiService webhook task results', () {
    test('completeWebhookTask sends jobs to the complete endpoint', () async {
      final body = {
        'jobs': [
          {
            'owner': 'openci-org',
            'repo': 'openci',
            'workflowName': 'CI',
          },
        ],
      };
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url,
          Uri.parse(
            'https://api.openci.test/webhooks/tasks/task-123/complete',
          ),
        );
        expect(jsonDecode(request.body), body);

        return http.Response(
          jsonEncode({
            'success': true,
            'jobs_created': 1,
            'job_ids': ['job-123'],
            'already_completed': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = _createClient(httpClient);
      addTearDown(() {
        client.dispose();
        httpClient.close();
      });

      final response = await client
          .getService<OpenCiApiService>()
          .completeWebhookTask('task-123', body);

      expect(response.isSuccessful, isTrue);
      expect(response.body?['jobs_created'], 1);
    });

    test('failWebhookTask sends errorMessage to the fail endpoint', () async {
      final body = {'errorMessage': 'workflow parse failed'};
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url,
          Uri.parse('https://api.openci.test/webhooks/tasks/task-123/fail'),
        );
        expect(jsonDecode(request.body), body);

        return http.Response(
          jsonEncode({'success': true, 'already_failed': false}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = _createClient(httpClient);
      addTearDown(() {
        client.dispose();
        httpClient.close();
      });

      final response = await client
          .getService<OpenCiApiService>()
          .failWebhookTask('task-123', body);

      expect(response.isSuccessful, isTrue);
      expect(response.body?['already_failed'], isFalse);
    });
  });
}

ChopperClient _createClient(http.Client httpClient) {
  return ChopperClient(
    baseUrl: Uri.parse('https://api.openci.test'),
    client: httpClient,
    converter: const JsonToTypeConverter(),
    services: [OpenCiApiService.create()],
  );
}
