import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('OpenCIApiService internal endpoints', () {
    test('seedLocalData sends seed options and decodes the result', () async {
      final body = {'teamId': 'test-team', 'installationId': '42'};
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse('https://api.openci.test/internal/seed'));
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), body);
        return http.Response(
          jsonEncode({'success': true, 'jobId': 'job-test'}),
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
          .getService<OpenCIApiService>()
          .seedLocalData(body);

      expect(response.isSuccessful, isTrue);
      expect(response.body, {'success': true, 'jobId': 'job-test'});
    });
  });

  group('OpenCIApiService worker endpoints', () {
    test(
      'claimNextJob sends the payload to the worker claim endpoint',
      () async {
        final body = {
          'vmName': 'worker-vm',
          'workerHost': 'worker-host',
          'maxConcurrentJobs': 2,
        };
        final httpClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url,
            Uri.parse('https://api.openci.test/worker/jobs/claim'),
          );
          expect(jsonDecode(request.body), body);
          return http.Response(
            jsonEncode({'job': null}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final client = _createClient(httpClient);
        addTearDown(client.dispose);

        final response = await client
            .getService<OpenCIApiService>()
            .claimNextJob(
              body,
            );

        expect(response.isSuccessful, isTrue);
        expect(response.body, {'job': null});
      },
    );
  });

  group('OpenCIApiService webhook task results', () {
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
          .getService<OpenCIApiService>()
          .completeWebhookTask('task-123', body);

      expect(response.isSuccessful, isTrue);
      expect(response.body?['jobs_created'], 1);
    });

    test('waits beyond ten seconds for queued Check registration', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        await request.drain<void>();
        await Future<void>.delayed(const Duration(seconds: 11));
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'success': true, 'jobs_created': 3}));
        await request.response.close();
      });
      final httpClient = http.Client();
      addTearDown(httpClient.close);
      final client = _createClient(
        httpClient,
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.dispose);

      final response = await client
          .getService<OpenCIApiService>()
          .completeWebhookTask('task-123', {'jobs': <Object?>[]});

      expect(response.isSuccessful, isTrue);
      expect(response.body?['jobs_created'], 3);
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
          .getService<OpenCIApiService>()
          .failWebhookTask('task-123', body);

      expect(response.isSuccessful, isTrue);
      expect(response.body?['already_failed'], isFalse);
    });

    test(
      'fetchOpenCIFiles sends the exact owner and installation ID',
      () async {
        final httpClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.path,
            '/teams/team-123/repositories/openci/openci-files',
          );
          expect(request.url.queryParameters, {
            'ref': 'commit-sha-123',
            'owner': 'openci-org',
            'installationId': '998877',
          });

          return http.Response(
            '[]',
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
            .getService<OpenCIApiService>()
            .fetchOpenCIFiles(
              'team-123',
              'openci',
              'commit-sha-123',
              owner: 'openci-org',
              installationId: 998877,
            );

        expect(response.isSuccessful, isTrue);
        expect(response.body, isEmpty);
      },
    );
  });
}

ChopperClient _createClient(http.Client httpClient, {Uri? baseUrl}) {
  return ChopperClient(
    baseUrl: baseUrl ?? Uri.parse('https://api.openci.test'),
    client: httpClient,
    converter: const JsonToTypeConverter(),
    services: [OpenCIApiService.create()],
  );
}
