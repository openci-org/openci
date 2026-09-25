import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/src/commands/dev/seed_local_data.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _signUpUri = Uri.parse(
  'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/'
  'accounts:signUp?key=demo-openci-api-key',
);
final _signInUri = _signUpUri.replace(
  path: '/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword',
);
final _verificationUri = Uri.parse(
  'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/'
  'projects/demo-openci/accounts:update',
);

MockClient _seedClient(Future<http.Response> Function(http.Request) onSeed) =>
    MockClient((request) async {
      if (request.url == _signUpUri) {
        return http.Response('{"localId":"development-user"}', 200);
      }
      if (request.url == _verificationUri) {
        return http.Response(
          '{"localId":"development-user","emailVerified":true}',
          200,
        );
      }
      return onSeed(request);
    });

class _RecordingLogger implements Logger {
  final stdoutMessages = <String>[];
  final stderrMessages = <String>[];

  @override
  void stdout(String message) => stdoutMessages.add(message);

  @override
  void stderr(String message) => stderrMessages.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('seedLocalData', () {
    late _RecordingLogger logger;
    late Directory projectRoot;

    setUp(() async {
      logger = _RecordingLogger();
      projectRoot = await Directory.systemTemp.createTemp(
        'seed_local_data_test_',
      );
      await File(
        p.join(projectRoot.path, '.env'),
      ).writeAsString('INTERNAL_API_KEY=test-internal-key\n');
    });

    tearDown(() async {
      await projectRoot.delete(recursive: true);
    });

    test('sends the created Auth user UID with the seed request', () async {
      const serverUrl = 'http://localhost:9090';
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url == _signUpUri) {
          return http.Response(
            '{"localId":"created-user-uid","idToken":"private-token"}',
            200,
          );
        }
        if (request.url == _verificationUri) {
          return http.Response(
            '{"localId":"created-user-uid","emailVerified":true}',
            200,
          );
        }
        return http.Response('{"success":true,"jobId":"job-test"}', 200);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'OPENCI_SERVER_URL': serverUrl},
        ),
        () => client,
      );

      expect(result, isTrue);
      expect(requests, hasLength(3));
      final authRequest = requests.first;
      expect(authRequest.method, 'POST');
      expect(authRequest.url, _signUpUri);
      expect(authRequest.followRedirects, isFalse);
      expect(authRequest.headers['content-type'], 'application/json');
      expect(authRequest.headers, isNot(contains('authorization')));
      expect(jsonDecode(authRequest.body), {
        'email': 'test@openci.org',
        'password': '123456',
        'returnSecureToken': true,
      });
      final request = requests.last;
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('$serverUrl/internal/seed'));
      expect(request.headers['content-type'], 'application/json');
      expect(request.headers['authorization'], 'Bearer test-internal-key');
      expect(jsonDecode(request.body), {'userId': 'created-user-uid'});
      expect(logger.stderrMessages, isEmpty);
      expect(logger.stdoutMessages, [
        '\n${t.dev.start.stepSeed}',
        t.dev.start.stepSeedCompleted,
      ]);
    });

    test('sends the same Auth user UID on repeated seeding', () async {
      final requests = <http.Request>[];
      var created = false;
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url == _signUpUri) {
          if (created) {
            return http.Response('{"error":{"message":"EMAIL_EXISTS"}}', 400);
          }
          created = true;
          return http.Response('{"localId":"development-user"}', 200);
        }
        if (request.url == _signInUri) {
          expect(request.followRedirects, isFalse);
          expect(request.body, requests.first.body);
          return http.Response('{"localId":"development-user"}', 200);
        }
        if (request.url == _verificationUri) {
          return http.Response(
            '{"localId":"development-user","emailVerified":true}',
            200,
          );
        }
        expect(jsonDecode(request.body), {'userId': 'development-user'});
        return http.Response('{"success":true}', 200);
      });

      await http.runWithClient(() async {
        for (var i = 0; i < 2; i++) {
          expect(
            await seedLocalData(
              logger,
              projectRoot: projectRoot,
              environment: {},
            ),
            isTrue,
          );
        }
      }, () => client);

      final seedUri = Uri.parse('http://localhost:8080/internal/seed');
      expect(requests.map((request) => request.url), [
        _signUpUri,
        _verificationUri,
        seedUri,
        _signUpUri,
        _signInUri,
        _verificationUri,
        seedUri,
      ]);
      expect(logger.stderrMessages, isEmpty);
    });

    test(
      'fails without changing an existing user that cannot sign in',
      () async {
        final requests = <Uri>[];
        final result = await http.runWithClient(
          () =>
              seedLocalData(logger, projectRoot: projectRoot, environment: {}),
          () => MockClient((request) async {
            requests.add(request.url);
            return request.url == _signUpUri
                ? http.Response('{"error":{"message":"EMAIL_EXISTS"}}', 400)
                : http.Response(
                    '{"error":{"message":"INVALID_PASSWORD"},'
                    '"debug":"private-auth-response"}',
                    400,
                  );
          }),
        );

        expect(result, isFalse);
        expect(requests, [_signUpUri, _signInUri]);
        expect(logger.stderrMessages.single, contains('test@openci.org'));
        expect(
          logger.stderrMessages.single,
          isNot(contains('private-auth-response')),
        );
        expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
      },
    );

    test(
      'marks only the development user email as verified before seeding',
      () async {
        final requests = <http.Request>[];
        final result = await http.runWithClient(
          () =>
              seedLocalData(logger, projectRoot: projectRoot, environment: {}),
          () => MockClient((request) async {
            requests.add(request);
            if (request.url == _signUpUri) {
              return http.Response('{"localId":"development-user"}', 200);
            }
            if (request.url == _verificationUri) {
              return http.Response(
                '{"localId":"development-user","emailVerified":true}',
                200,
              );
            }
            return http.Response('{"success":true}', 200);
          }),
        );

        expect(result, isTrue);
        final verification = requests[1];
        expect(verification.url, _verificationUri);
        expect(verification.followRedirects, isFalse);
        expect(verification.headers['authorization'], 'Bearer owner');
        expect(jsonDecode(verification.body), {
          'localId': 'development-user',
          'emailVerified': true,
        });
        expect(requests.last.url.path, '/internal/seed');
      },
    );

    test('does not seed team data when email verification fails', () async {
      final requests = <Uri>[];
      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => MockClient((request) async {
          requests.add(request.url);
          if (request.url == _signUpUri) {
            return http.Response('{"localId":"development-user"}', 200);
          }
          expect(request.url, _verificationUri);
          return http.Response('private-verification-response', 500);
        }),
      );

      expect(result, isFalse);
      expect(requests, [_signUpUri, _verificationUri]);
      expect(
        logger.stderrMessages.single,
        isNot(contains('private-verification-response')),
      );
    });

    test('rejects a verification response for another user', () async {
      final requests = <Uri>[];
      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => MockClient((request) async {
          requests.add(request.url);
          if (request.url == _signUpUri) {
            return http.Response('{"localId":"development-user"}', 200);
          }
          expect(request.url, _verificationUri);
          return http.Response(
            '{"localId":"another-user","emailVerified":true}',
            200,
          );
        }),
      );

      expect(result, isFalse);
      expect(requests, [_signUpUri, _verificationUri]);
    });

    test('rejects an unverified response before seeding', () async {
      final requests = <Uri>[];
      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => MockClient((request) async {
          requests.add(request.url);
          if (request.url == _signUpUri) {
            return http.Response('{"localId":"development-user"}', 200);
          }
          expect(request.url, _verificationUri);
          return http.Response(
            '{"localId":"development-user","emailVerified":false}',
            200,
          );
        }),
      );

      expect(result, isFalse);
      expect(requests, [_signUpUri, _verificationUri]);
    });

    test('rejects redirects from the email verification endpoint', () async {
      final requests = <Uri>[];
      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => MockClient((request) async {
          requests.add(request.url);
          if (request.url == _signUpUri) {
            return http.Response('{"localId":"development-user"}', 200);
          }
          expect(request.url, _verificationUri);
          expect(request.followRedirects, isFalse);
          return http.Response(
            '{"localId":"development-user","emailVerified":true}',
            302,
            headers: {'location': 'https://identitytoolkit.googleapis.com'},
          );
        }),
      );

      expect(result, isFalse);
      expect(requests, [_signUpUri, _verificationUri]);
    });

    final authFailures = <String, Future<http.Response> Function()>{
      'rejects signup': () async =>
          http.Response('{"error":{"message":"OPERATION_NOT_ALLOWED"}}', 400),
      'returns a server error': () async =>
          http.Response('{"error":"private-auth-response"}', 500),
      'redirects': () async => http.Response(
        '{"localId":"development-user"}',
        302,
        headers: {'location': 'https://identitytoolkit.googleapis.com'},
      ),
      'returns invalid JSON': () async =>
          http.Response('private-auth-response', 200),
      'returns a non-object': () async => http.Response('[]', 200),
      'omits the UID': () async => http.Response('{}', 200),
      'returns an empty UID': () async => http.Response('{"localId":" "}', 200),
      'throws': () async => throw http.ClientException('private-auth-response'),
      'times out': () => Completer<http.Response>().future,
    };
    for (final failure in authFailures.entries) {
      test('does not seed team/job data when Auth ${failure.key}', () async {
        var requests = 0;
        final result = await http.runWithClient(
          () => seedLocalData(
            logger,
            projectRoot: projectRoot,
            environment: {},
            timeout: const Duration(milliseconds: 50),
          ),
          () => MockClient((request) async {
            requests++;
            expect(request.url, _signUpUri);
            expect(request.followRedirects, isFalse);
            return failure.value();
          }),
        );

        expect(result, isFalse);
        expect(requests, 1);
        expect(logger.stderrMessages.single, contains('127.0.0.1:9099'));
        expect(
          logger.stderrMessages.single,
          isNot(contains('private-auth-response')),
        );
        expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
      });
    }

    test('uses the default server URL and HTTP client', () async {
      var requestCount = 0;

      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => _seedClient((request) async {
          requestCount++;
          expect(request.url, Uri.parse('http://localhost:8080/internal/seed'));
          expect(request.headers['authorization'], 'Bearer test-internal-key');
          return http.Response('{"success":true,"jobId":"job-test"}', 200);
        }),
      );

      expect(result, isTrue);
      expect(requestCount, 1);
    });

    test('reads the internal key from the project .env file', () async {
      await File(p.join(projectRoot.path, '.env')).writeAsString(
        '# Local development\nINTERNAL_API_KEY = file-key # comment\n',
      );
      var requestCount = 0;

      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => _seedClient((request) async {
          requestCount++;
          expect(request.headers['authorization'], 'Bearer file-key');
          return http.Response('{"success":true,"jobId":"job-test"}', 200);
        }),
      );

      expect(result, isTrue);
      expect(requestCount, 1);
    });

    test('uses the project .env key even when a shell key is set', () async {
      await File(
        p.join(projectRoot.path, '.env'),
      ).writeAsString('INTERNAL_API_KEY=file-key\n');

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'INTERNAL_API_KEY': 'shell-key'},
        ),
        () => _seedClient((request) async {
          expect(request.headers['authorization'], 'Bearer file-key');
          return http.Response('{"success":true,"jobId":"job-test"}', 200);
        }),
      );

      expect(result, isTrue);
    });

    test('does not send the project key to a remote server', () async {
      await File(
        p.join(projectRoot.path, '.env'),
      ).writeAsString('INTERNAL_API_KEY=file-key\n');
      var requestCount = 0;

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {
            'OPENCI_SERVER_URL': 'https://ci.example.com',
            'INTERNAL_API_KEY': 'shell-key',
          },
        ),
        () => MockClient((_) async {
          requestCount++;
          return http.Response('', 200);
        }),
      );

      expect(result, isFalse);
      expect(requestCount, 0);
      expect(logger.stderrMessages.single, contains('OPENCI_SERVER_URL'));
      expect(logger.stderrMessages.single, isNot(contains('file-key')));
      expect(logger.stderrMessages.single, isNot(contains('shell-key')));
    });

    test('returns false when the seed request fails', () async {
      var requestCount = 0;
      final client = _seedClient((request) async {
        requestCount++;
        expect(request.url, Uri.parse('http://localhost:8080/internal/seed'));
        return http.Response('seed failed', 500);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: const {},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(requestCount, 1);
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepSeedFailed),
      );
      expect(logger.stderrMessages.single, contains('Status: 500'));
      expect(logger.stderrMessages.single, contains('Body: seed failed'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('reports rejected credentials without logging the key', () async {
      final client = _seedClient((_) async {
        return http.Response('{"error":"Authentication required"}', 401);
      });

      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => client,
      );

      expect(result, isFalse);
      expect(logger.stderrMessages.single, contains('Status: 401'));
      expect(
        logger.stderrMessages.single,
        isNot(contains('test-internal-key')),
      );
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('returns false when an HTTP request throws', () async {
      final client = _seedClient(
        (_) async => throw Exception('connection failed'),
      );

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: const {},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(logger.stderrMessages.single, contains('connection failed'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('returns false when the seed request times out', () async {
      final client = _seedClient((_) => Completer<http.Response>().future);

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: const {},
          timeout: const Duration(milliseconds: 50),
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(logger.stderrMessages.single, contains('TimeoutException'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('does not send a request when the project key is unset', () async {
      await File(p.join(projectRoot.path, '.env')).delete();
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('', 200);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'INTERNAL_API_KEY': 'shell-key'},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(requestCount, 0);
      expect(logger.stderrMessages.single, contains('INTERNAL_API_KEY'));
    });

    test('does not send a request when the project key is empty', () async {
      await File(
        p.join(projectRoot.path, '.env'),
      ).writeAsString('INTERNAL_API_KEY=\n');
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('', 200);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'INTERNAL_API_KEY': 'shell-key'},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(requestCount, 0);
      expect(logger.stderrMessages.single, contains('INTERNAL_API_KEY'));
    });
  });
}
