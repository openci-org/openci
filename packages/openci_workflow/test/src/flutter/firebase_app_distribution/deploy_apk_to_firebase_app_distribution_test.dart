import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

const _appId = '1:123456789:android:abcdef';
const _appName = 'projects/123456789/apps/$_appId';
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
  group('deployApkToFirebaseAppDistribution', () {
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
    late int authStatus;

    setUpAll(() async {
      keyDirectory = await Directory.systemTemp.createTemp('openci-apk-key-');
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
      workspace = await Directory.systemTemp.createTemp("openci apk ' ");
      temporary = await Directory('${workspace.path}/temporary').create();
      commands = [];
      workingDirectories = [];
      requests = [];
      clients = [];
      authStatus = 200;
      handler = (_) async => _json(_done());
      ci = OpenCI(
        workflowName: 'test',
        ciTriggers: const [CITrigger.push(branch: 'test')],
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

    Future<File> createApk({
      String filename = 'app.apk',
      String dir = 'apps/mobile',
    }) async {
      final apk = File('${workspace.path}/$dir/$filename');
      await apk.parent.create(recursive: true);
      return apk.writeAsBytes(List.generate(65536, (index) => index % 256));
    }

    Future<void> deploy({
      String apkPath = 'app.apk',
      String appId = _appId,
      String? serviceAccountJsonBase64,
      String? dir,
    }) => http.runWithClient(
      () => IOOverrides.runZoned(
        () => ci.flutter.deployApkToFirebaseAppDistribution(
          apkPath: apkPath,
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
          return handler(request);
        });
        clients.add(client);
        return client;
      },
    );

    test(
      'uploads the exact APK bytes without subprocesses or distribution',
      () async {
        final apk = await createApk(filename: '日本語 app.apk');
        await deploy(apkPath: apk.path, dir: 'missing-directory');

        expect(commands, isEmpty);
        expect(requests, hasLength(2));
        final request = requests.last;
        expect(request.method, 'POST');
        expect(request.url.path, '/upload/v1/$_appName/releases:upload');
        expect(request.headers['Content-Type'], 'application/octet-stream');
        expect(request.headers['X-Goog-Upload-Protocol'], 'raw');
        expect(
          request.headers['X-Goog-Upload-File-Name'],
          Uri.encodeComponent('日本語 app.apk'),
        );
        expect(request.contentLength, await apk.length());
        expect(request.bodyBytes, await apk.readAsBytes());
      },
    );

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test(
        'resolves relative APK paths in the workflow directory: $dir',
        () async {
          const filename = r"-app ' $(touch unexpected) 日本語.apk";
          final apk = await createApk(
            filename: filename,
            dir: dir ?? 'apps/mobile',
          );
          await deploy(apkPath: filename, dir: dir);

          expect(requests.last.bodyBytes, await apk.readAsBytes());
          expect(workingDirectories.single, apk.parent.path);
          expect(await File('${apk.parent.path}/unexpected').exists(), isFalse);
        },
      );
    }

    test('waits for processing to finish', () async {
      final apk = await createApk();
      handler = (request) async => _json(
        request.method == 'POST' ? {'name': _operation} : _done(),
      );
      await deploy(apkPath: apk.path);
      expect(requests.map((request) => request.method), [
        'POST',
        'POST',
        'GET',
      ]);
      expect(requests.last.url.path, '/v1/$_operation');
    });

    for (final path in ['', ' ', 'app.aab', 'app.ipa', 'app.apk.txt']) {
      test('rejects a non-APK path: $path', () async {
        await expectLater(deploy(apkPath: path), throwsArgumentError);
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
    test('rejects a missing APK before authentication', () async {
      await expectLater(
        deploy(apkPath: '${workspace.path}/missing.apk'),
        throwsA(isA<FileSystemException>()),
      );
      expect(requests, isEmpty);
    });
    test('rejects an empty APK before authentication', () async {
      final apk = await File('${workspace.path}/empty.apk').create();
      await expectLater(deploy(apkPath: apk.path), throwsArgumentError);
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
        final apk = await createApk();
        authStatus = 400;
        await expectLater(
          deploy(apkPath: apk.path),
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
          final apk = await createApk();
          handler = (_) async => _json({'error': 'private-response'}, status);
          await expectLater(
            deploy(apkPath: apk.path),
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
          expect(requests, hasLength(2));
        },
      );
    }
    test('fails if polling fails', () async {
      final apk = await createApk();
      handler = (request) async => request.method == 'POST'
          ? _json({'name': _operation})
          : _json({'error': 'private-response'}, 403);
      await expectLater(
        deploy(apkPath: apk.path),
        throwsA(isA<HttpException>()),
      );
      expect(requests, hasLength(3));
    });
    for (final error in [
      http.ClientException('private-token'),
      TimeoutException('private-token'),
    ]) {
      test('sanitizes ${error.runtimeType}', () async {
        final apk = await createApk();
        handler = (_) async => throw error;
        await expectLater(
          deploy(apkPath: apk.path),
          throwsA(
            predicate<Object>(
              (error) => !error.toString().contains('private-token'),
            ),
          ),
        );
      });
    }
    test('fails on a processing error without exposing the response', () async {
      final apk = await createApk();
      handler = (_) async => _json({
        'name': _operation,
        'done': true,
        'error': {'code': 3, 'message': 'private-response'},
      });
      await expectLater(
        deploy(apkPath: apk.path),
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
        final apk = await createApk();
        handler = (_) async => _json(body);
        await expectLater(deploy(apkPath: apk.path), throwsStateError);
        expect(requests, hasLength(2));
      });
    }
    for (final body in ['private-invalid-json', '[]']) {
      test('sanitizes malformed JSON responses: $body', () async {
        final apk = await createApk();
        handler = (_) async => http.Response(body, 200);
        await expectLater(
          deploy(apkPath: apk.path),
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
