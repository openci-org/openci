import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

const _appId = '1:123456789:android:abcdef';
const _appName = 'projects/123456789/apps/$_appId';
const _aabInfo = '$_appName/aabInfo';
const _release = '$_appName/releases/release-1';
const _operation = '$_release/operations/upload-1';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object> _done() => {
  'name': _operation,
  'done': true,
  'response': {
    'release': {'name': _release},
    'result': 'RELEASE_CREATED',
  },
};

void main() {
  group('deployAabToFirebaseAppDistribution', () {
    late Directory keyDirectory;
    late String credentials;
    late Directory workspace;
    late Directory temporary;
    late OpenCI ci;
    late List<String> commands;
    late List<String> workingDirectories;
    late List<http.Request> requests;
    late List<_TrackingClient> clients;
    late MockClientHandler handler;
    late MockClientHandler integrationHandler;
    late int authStatus;

    setUpAll(() async {
      keyDirectory = await Directory.systemTemp.createTemp('openci-aab-key-');
      final key = File('${keyDirectory.path}/key.pem');
      final result = await Process.run('openssl', [
        'genpkey',
        '-algorithm',
        'RSA',
        '-pkeyopt',
        'rsa_keygen_bits:2048',
        '-out',
        key.path,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      // Generated for mocked OAuth requests only; not a real service account.
      credentials = base64Encode(
        utf8.encode(
          jsonEncode({
            'type': 'service_account',
            'client_id': '123456789',
            'client_email': 'test@test-project.iam.gserviceaccount.com',
            'private_key': await key.readAsString(),
          }),
        ),
      );
    });
    tearDownAll(() => keyDirectory.delete(recursive: true));

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp("openci aab ' ");
      temporary = await Directory('${workspace.path}/temporary').create();
      commands = [];
      workingDirectories = [];
      requests = [];
      clients = [];
      authStatus = 200;
      handler = (_) async => _json(_done());
      integrationHandler = (_) async => _json({
        'name': _aabInfo,
        'integrationState': 'INTEGRATED',
      });
      ci = OpenCI.forTesting(
        workspacePath: workspace.path,
        currentWorkingDirectory: 'apps/mobile',
        commandRunner: (command, {required workingDirectory}) async {
          commands.add(command);
          workingDirectories.add(workingDirectory);
          final result = await Process.run('/bin/sh', [
            '-c',
            command,
          ], workingDirectory: workingDirectory);
          if (result.exitCode != 0) {
            throw ProcessException(
              '/bin/sh',
              ['-c', command],
              '${result.stderr}',
              result.exitCode,
            );
          }
        },
      );
    });
    tearDown(() async {
      expect(clients.every((client) => client.closed), isTrue);
      expect(await temporary.list().toList(), isEmpty);
      expect(commands.join('\n'), isNot(contains(credentials)));
      await workspace.delete(recursive: true);
    });

    Future<File> createAab({
      String filename = 'app.aab',
      String dir = 'apps/mobile',
    }) async {
      final aab = File('${workspace.path}/$dir/$filename');
      await aab.parent.create(recursive: true);
      return aab.writeAsBytes(List.generate(65536, (index) => index % 256));
    }

    Future<void> deploy({
      String aabPath = 'app.aab',
      String appId = _appId,
      String? serviceAccountJsonBase64,
      String? dir,
    }) => http.runWithClient(
      () => IOOverrides.runZoned(
        () => ci.flutter.deployAabToFirebaseAppDistribution(
          aabPath: aabPath,
          appId: appId,
          serviceAccountJsonBase64: serviceAccountJsonBase64 ?? credentials,
          dir: dir,
        ),
        getSystemTempDirectory: () => temporary,
      ),
      () {
        final client = _TrackingClient((request) async {
          requests.add(request);
          expect(await temporary.list().toList(), isEmpty);
          expect(request.followRedirects, isFalse);
          if (request.url.host == 'oauth2.googleapis.com') {
            expect(
              request.bodyFields['grant_type'],
              'urn:ietf:params:oauth:grant-type:jwt-bearer',
            );
            final jwt = request.bodyFields['assertion']!.split('.');
            final claims =
                jsonDecode(
                      utf8.decode(
                        base64Url.decode(base64Url.normalize(jwt[1])),
                      ),
                    )
                    as Map;
            expect(claims['iss'], 'test@test-project.iam.gserviceaccount.com');
            expect(
              claims['scope'],
              'https://www.googleapis.com/auth/cloud-platform',
            );
            return _json(
              authStatus == 200
                  ? {
                      'access_token': 'test-access-token',
                      'expires_in': 3600,
                      'token_type': 'Bearer',
                    }
                  : {
                      'error': 'invalid_grant',
                      'error_description': 'private-response',
                    },
              authStatus,
            );
          }
          expect(request.url.host, 'firebaseappdistribution.googleapis.com');
          expect(request.headers['authorization'], 'Bearer test-access-token');
          if (request.url.path == '/v1/$_aabInfo') {
            expect(request.method, 'GET');
            return integrationHandler(request);
          }
          return handler(request);
        });
        clients.add(client);
        return client;
      },
    );

    test(
      'uploads the exact AAB bytes without subprocesses or distribution',
      () async {
        final aab = await createAab(filename: '日本語 app.aab');
        await deploy(aabPath: aab.path, dir: 'missing-directory');

        expect(commands, isEmpty);
        expect(requests, hasLength(3));
        expect(requests[1].url.path, '/v1/$_aabInfo');
        final request = requests.last;
        expect(request.method, 'POST');
        expect(request.url.path, '/upload/v1/$_appName/releases:upload');
        expect(request.headers['Content-Type'], 'application/octet-stream');
        expect(request.headers['X-Goog-Upload-Protocol'], 'raw');
        expect(
          request.headers['X-Goog-Upload-File-Name'],
          Uri.encodeComponent('日本語 app.aab'),
        );
        expect(request.contentLength, await aab.length());
        expect(request.bodyBytes, await aab.readAsBytes());
      },
    );

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test(
        'resolves relative AAB paths in the workflow directory: $dir',
        () async {
          const filename = r"-app ' $(touch unexpected) 日本語.aab";
          final aab = await createAab(
            filename: filename,
            dir: dir ?? 'apps/mobile',
          );
          await deploy(aabPath: filename, dir: dir);

          expect(requests.last.bodyBytes, await aab.readAsBytes());
          expect(workingDirectories.single, aab.parent.path);
          expect(await File('${aab.parent.path}/unexpected').exists(), isFalse);
        },
      );
    }

    test('waits for processing to finish', () async {
      final aab = await createAab();
      handler = (request) async => _json(
        request.method == 'POST' ? {'name': _operation} : _done(),
      );
      await deploy(aabPath: aab.path);
      expect(requests.map((request) => request.method), [
        'POST',
        'GET',
        'POST',
        'GET',
      ]);
      expect(requests.last.url.path, '/v1/$_operation');
    });

    test('attempts upload when Google Play status is unavailable', () async {
      final aab = await createAab();
      integrationHandler = (_) async => _json({
        'name': _aabInfo,
        'integrationState': 'AAB_STATE_UNAVAILABLE',
      });
      await deploy(aabPath: aab.path);
      expect(requests, hasLength(3));
      expect(requests.last.method, 'POST');
    });

    for (final (state, reason) in [
      ('PLAY_ACCOUNT_NOT_LINKED', 'Link this Firebase project to Google Play'),
      (
        'NO_APP_WITH_GIVEN_BUNDLE_ID_IN_PLAY_ACCOUNT',
        'same package name',
      ),
      ('APP_NOT_PUBLISHED', 'Complete Google Play app review'),
      ('PLAY_IAS_TERMS_NOT_ACCEPTED', 'internal app sharing terms'),
      ('ADHOC_SHARING_KEY_NOT_GENERATED', 'not generated'),
      ('ADHOC_SHARING_KEY_NOT_REGISTERED', 'Android Developer Verification'),
      (
        'PLAY_ANDROID_DEVELOPER_CONSOLE_ACCOUNT_NOT_FOUND',
        'developer account was not found',
      ),
      (
        'PLAY_ANDROID_DEVELOPER_CONSOLE_PACKAGE_NOT_FOUND',
        'app package was not found',
      ),
    ]) {
      test('reports $state before uploading the AAB', () async {
        final aab = await createAab();
        integrationHandler = (_) async => _json({
          'name': _aabInfo,
          'integrationState': state,
          'details': 'private-response',
        });
        await expectLater(
          deploy(aabPath: aab.path),
          throwsA(
            isA<StateError>().having(
              (error) => error.toString(),
              'message',
              allOf(contains(reason), isNot(contains('private-response'))),
            ),
          ),
        );
        expect(requests, hasLength(2));
        expect(requests.last.url.path, '/v1/$_aabInfo');
      });
    }

    for (final state in [
      null,
      123,
      <String, Object>{},
      'AAB_INTEGRATION_STATE_UNSPECIFIED',
      'private-unknown-state',
    ]) {
      test('rejects an unknown or missing integration state: $state', () async {
        final aab = await createAab();
        integrationHandler = (_) async => _json({
          'name': _aabInfo,
          'integrationState': ?state,
        });
        await expectLater(
          deploy(aabPath: aab.path),
          throwsA(
            isA<StateError>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('unknown AAB integration state'),
                isNot(contains('private-unknown-state')),
              ),
            ),
          ),
        );
        expect(requests, hasLength(2));
      });
    }

    for (final name in [null, 'projects/other/apps/other/aabInfo']) {
      test('rejects invalid AAB integration resource: $name', () async {
        final aab = await createAab();
        integrationHandler = (_) async => _json({
          'name': ?name,
          'integrationState': 'INTEGRATED',
        });
        await expectLater(deploy(aabPath: aab.path), throwsStateError);
        expect(requests, hasLength(2));
      });
    }

    for (final status in [302, 403, 404]) {
      test('stops when the integration check returns HTTP $status', () async {
        final aab = await createAab();
        integrationHandler = (_) async =>
            _json({'error': 'private-response'}, status);
        await expectLater(
          deploy(aabPath: aab.path),
          throwsA(
            isA<HttpException>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('check AAB integration'),
                contains('HTTP $status'),
                isNot(contains('private-response')),
              ),
            ),
          ),
        );
        expect(requests, hasLength(2));
      });
    }

    for (final path in ['', ' ', 'app.apk', 'app.ipa', 'app.aab.txt']) {
      test('rejects a non-AAB path: $path', () async {
        await expectLater(deploy(aabPath: path), throwsArgumentError);
        expect(commands, isEmpty);
        expect(requests, isEmpty);
      });
    }
    for (final appId in [
      '',
      'org.example.app',
      '1:123456789:ios:abcdef',
      '1:123456789:android:abc/def',
    ]) {
      test('rejects an invalid Android Firebase App ID: $appId', () async {
        await expectLater(deploy(appId: appId), throwsArgumentError);
        expect(commands, isEmpty);
        expect(requests, isEmpty);
      });
    }
    test('rejects a missing AAB before authentication', () async {
      await expectLater(
        deploy(aabPath: '${workspace.path}/missing.aab'),
        throwsA(isA<FileSystemException>()),
      );
      expect(requests, isEmpty);
    });
    test('rejects an empty AAB before authentication', () async {
      final aab = await File('${workspace.path}/empty.aab').create();
      await expectLater(deploy(aabPath: aab.path), throwsArgumentError);
      expect(requests, isEmpty);
    });

    for (final secret in [
      'TEST_PRIVATE_KEY_DO_NOT_LOG!',
      base64Encode(utf8.encode('TEST_PRIVATE_KEY_DO_NOT_LOG')),
      base64Encode(utf8.encode('{"type":"authorized_user"}')),
      base64Encode(utf8.encode('{"type":"service_account"}')),
    ]) {
      test('rejects malformed credentials without exposing them', () async {
        await expectLater(
          deploy(serviceAccountJsonBase64: secret),
          throwsA(
            isA<FormatException>()
                .having((error) => error.source, 'source', isNull)
                .having(
                  (error) => error.toString(),
                  'message',
                  isNot(contains('TEST_PRIVATE_KEY_DO_NOT_LOG')),
                ),
          ),
        );
        expect(commands, isEmpty);
        expect(requests, isEmpty);
      });
    }
    test(
      'stops on authentication failure and sanitizes the response',
      () async {
        final aab = await createAab();
        authStatus = 400;
        await expectLater(
          deploy(aabPath: aab.path),
          throwsA(
            isA<StateError>().having(
              (error) => error.toString(),
              'message',
              isNot(contains('private-response')),
            ),
          ),
        );
        expect(requests, hasLength(1));
      },
    );

    for (final status in [302, 403, 500]) {
      test(
        'fails on upload HTTP $status without exposing the response',
        () async {
          final aab = await createAab();
          handler = (_) async => _json({'error': 'private-response'}, status);
          await expectLater(
            deploy(aabPath: aab.path),
            throwsA(
              isA<HttpException>().having(
                (error) => error.message,
                'message',
                allOf(
                  contains('HTTP $status'),
                  isNot(contains('private-response')),
                ),
              ),
            ),
          );
          expect(requests, hasLength(3));
        },
      );
    }
    test('fails if polling fails', () async {
      final aab = await createAab();
      handler = (request) async => request.method == 'POST'
          ? _json({'name': _operation})
          : _json({'error': 'private-response'}, 403);
      await expectLater(
        deploy(aabPath: aab.path),
        throwsA(isA<HttpException>()),
      );
      expect(requests, hasLength(4));
    });
    for (final error in [
      http.ClientException('private-token'),
      TimeoutException('private-token'),
    ]) {
      test('sanitizes ${error.runtimeType}', () async {
        final aab = await createAab();
        handler = (_) async => throw error;
        await expectLater(
          deploy(aabPath: aab.path),
          throwsA(
            predicate<Object>(
              (error) => !error.toString().contains('private-token'),
            ),
          ),
        );
      });
    }
    test('fails on a processing error without exposing the response', () async {
      final aab = await createAab();
      handler = (_) async => _json({
        'name': _operation,
        'done': true,
        'error': {'code': 3, 'message': 'private-response'},
      });
      await expectLater(
        deploy(aabPath: aab.path),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('code 3'), isNot(contains('private-response'))),
          ),
        ),
      );
    });
    for (final body in [
      <String, Object>{},
      {'name': 'https://example.com/operation'},
      {'name': _operation.replaceFirst('123456789', '987654321')},
      {'name': _operation, 'done': true},
      {
        ..._done(),
        'response': {
          'release': {'name': 'projects/other/releases/id'},
        },
      },
    ]) {
      test('rejects an invalid operation or release: $body', () async {
        final aab = await createAab();
        handler = (_) async => _json(body);
        await expectLater(deploy(aabPath: aab.path), throwsStateError);
        expect(requests, hasLength(3));
      });
    }
    for (final body in ['private-invalid-json', '[]']) {
      test('sanitizes malformed JSON responses: $body', () async {
        final aab = await createAab();
        handler = (_) async => http.Response(body, 200);
        await expectLater(
          deploy(aabPath: aab.path),
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
  }, testOn: '!windows');
}

class _TrackingClient extends MockClient {
  _TrackingClient(super.handler);
  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}
