import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/src/flutter/firebase_app_distribution_client.dart';
import 'package:test/test.dart';

const _app = 'projects/123456789/apps/1:123456789:ios:abcdef';
const _release = '$_app/releases/release-1';
const _operation = '$_release/operations/upload-1';

Map<String, Object> _done() => {
  'name': _operation,
  'done': true,
  'response': {
    'release': {'name': _release},
    'result': 'RELEASE_CREATED',
  },
};

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late Directory root;
  late File ipa;
  late List<http.Request> requests;
  late MockClientHandler handler;
  late MockClient client;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('openci-fad-api-');
    ipa = File('${root.path}/日本語 app.ipa');
    await ipa.writeAsBytes(List.generate(1024 * 1024, (index) => index % 256));
    requests = [];
    handler = (_) async => _json(_done());
    client = MockClient((request) async {
      requests.add(request);
      return handler(request);
    });
  });
  tearDown(() async {
    client.close();
    await root.delete(recursive: true);
  });

  Future<String> upload({
    List<String> groups = const [],
    List<String> testers = const [],
    String? notes,
    Duration timeout = const Duration(minutes: 5),
  }) =>
      FirebaseAppDistributionClient(
        client,
        pollInterval: Duration.zero,
        operationTimeout: timeout,
      ).upload(
        ipa: ipa,
        appName: _app,
        groups: groups,
        testers: testers,
        releaseNotes: notes,
      );

  test(
    'uploads exact binary bytes without distributing or adding notes',
    () async {
      expect(await upload(), _release);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://firebaseappdistribution.googleapis.com/upload/v1/$_app/releases:upload',
      );
      expect(request.followRedirects, isFalse);
      expect(request.contentLength, await ipa.length());
      expect(request.bodyBytes, await ipa.readAsBytes());
      expect(request.headers['X-Goog-Upload-Protocol'], 'raw');
      expect(
        request.headers['X-Goog-Upload-File-Name'],
        Uri.encodeComponent('日本語 app.ipa'),
      );
      expect(request.headers['Content-Type'], 'application/octet-stream');
    },
  );

  test(
    'waits until the operation finishes before notes and distribution',
    () async {
      var polls = 0;
      handler = (request) async {
        if (request.url.path.endsWith(':upload')) {
          return _json({'name': _operation});
        }
        if (request.method == 'GET') {
          return _json(
            ++polls == 1 ? {'name': _operation, 'done': false} : _done(),
          );
        }
        return _json({});
      };
      const notes = 'Release "日本語"\nSecond line';
      expect(
        await upload(
          groups: ['qa'],
          testers: ['tester@example.com'],
          notes: notes,
        ),
        _release,
      );

      expect(requests.map((request) => request.method), [
        'POST',
        'GET',
        'GET',
        'PATCH',
        'POST',
      ]);
      expect(requests[1].url.path, '/v1/$_operation');
      expect(requests[3].url.queryParameters, {
        'updateMask': 'releaseNotes.text',
      });
      expect(jsonDecode(requests[3].body), {
        'name': _release,
        'releaseNotes': {'text': notes},
      });
      expect(requests.last.url.path, '/v1/$_release:distribute');
      expect(jsonDecode(requests.last.body), {
        'testerEmails': ['tester@example.com'],
        'groupAliases': ['qa'],
      });
    },
  );

  test('handles an unchanged release as a completed upload', () async {
    handler = (_) async => _json({
      ..._done(),
      'response': {
        'release': {'name': _release},
        'result': 'RELEASE_UNMODIFIED',
      },
    });
    expect(await upload(), _release);
  });

  test(
    'stops after an asynchronous processing error without exposing its body',
    () async {
      handler = (request) async => _json(
        request.method == 'POST'
            ? {'name': _operation}
            : {
                'name': _operation,
                'done': true,
                'error': {'code': 3, 'message': 'private-response'},
              },
      );

      await expectLater(
        upload(groups: ['qa'], notes: 'notes'),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('code 3'), isNot(contains('private-response'))),
          ),
        ),
      );
      expect(requests.map((request) => request.method), ['POST', 'GET']);
    },
  );

  test('bounds operation polling', () async {
    handler = (_) async => _json({'name': _operation});
    await expectLater(
      upload(timeout: Duration.zero),
      throwsA(isA<TimeoutException>()),
    );
    expect(requests, hasLength(1));
  });

  for (final phase in ['upload', 'poll', 'notes', 'distribute']) {
    test(
      'propagates HTTP failure during $phase and stops later requests',
      () async {
        handler = (request) async {
          final fails = switch (phase) {
            'upload' => request.url.path.endsWith(':upload'),
            'poll' => request.method == 'GET',
            'notes' => request.method == 'PATCH',
            _ => request.url.path.endsWith(':distribute'),
          };
          if (fails) {
            return _json({
              'error': {'message': 'private-response'},
            }, 403);
          }
          if (request.url.path.endsWith(':upload') && phase == 'poll') {
            return _json({'name': _operation});
          }
          return _json(_done());
        };
        await expectLater(
          upload(groups: ['qa'], notes: 'notes'),
          throwsA(
            isA<HttpException>().having(
              (error) => error.message,
              'message',
              allOf(contains('HTTP 403'), isNot(contains('private-response'))),
            ),
          ),
        );
        expect(
          requests,
          hasLength(switch (phase) {
            'upload' => 1,
            'poll' || 'notes' => 2,
            _ => 3,
          }),
        );
      },
    );
  }

  for (final error in [
    http.ClientException('private-token'),
    TimeoutException('private-token'),
  ]) {
    test('sanitizes ${error.runtimeType} errors', () async {
      handler = (_) async => throw error;
      await expectLater(
        upload(),
        throwsA(
          predicate<Object>(
            (error) => !error.toString().contains('private-token'),
          ),
        ),
      );
    });
  }

  for (final body in [
    <String, Object>{},
    {'name': 'https://example.com/token'},
    {'name': _operation.replaceFirst('123456789', '987654321')},
    {'name': _operation, 'done': true},
    {
      'name': _operation,
      'done': true,
      'response': {
        'release': {'name': 'projects/other/releases/id'},
      },
    },
  ]) {
    test('rejects invalid operation or release resources: $body', () async {
      handler = (_) async => _json(body);
      await expectLater(upload(groups: ['qa']), throwsStateError);
      expect(requests, hasLength(1));
    });
  }

  for (final body in ['private-invalid-json', '[]']) {
    test('sanitizes malformed JSON responses: $body', () async {
      handler = (_) async => http.Response(body, 200);
      await expectLater(
        upload(),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            isNot(contains(body)),
          ),
        ),
      );
    });
  }
}
