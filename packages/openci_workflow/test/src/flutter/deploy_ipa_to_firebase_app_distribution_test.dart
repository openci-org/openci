import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

const _appId = '1:123456789:ios:abcdef';
const _appName = 'projects/123456789/apps/$_appId';
const _release = '$_appName/releases/release-1';
late String _credentialsBase64;

void main() {
  group('deployIpaToFirebaseAppDistribution', () {
    late Directory keyDirectory;
    late _UploadEnvironment environment;

    setUpAll(() async {
      keyDirectory = await Directory.systemTemp.createTemp(
        'openci-fad-test-key-',
      );
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
      // Generated only for mocked OAuth requests; not a real service account key.
      _credentialsBase64 = base64Encode(
        utf8.encode(
          jsonEncode({
            'type': 'service_account',
            'project_id': 'test-project',
            'client_id': '123456789',
            'client_email': 'test@test-project.iam.gserviceaccount.com',
            'private_key': await key.readAsString(),
          }),
        ),
      );
    });
    tearDownAll(() => keyDirectory.delete(recursive: true));
    setUp(() async => environment = await _UploadEnvironment.create());
    tearDown(() async {
      expect(environment.clients.every((client) => client.closed), isTrue);
      expect(await environment.temporary.list().toList(), isEmpty);
      expect(
        environment.commands.join('\n'),
        isNot(contains(_credentialsBase64)),
      );
      await environment.workspace.delete(recursive: true);
    });

    for (final binary in [false, true]) {
      test(
        'authenticates and uploads using the IPA config (binary: $binary)',
        () async {
          final ipa = await environment.createIpa(
            binary: binary,
            configs: {
              "Payload/Runner's [prod].app/GoogleService-Info.plist": _plist(
                _appId,
              ),
              'Payload/Runner.app/Watch/Watch.app/GoogleService-Info.plist':
                  _plist('1:987654321:ios:123abc'),
            },
          );
          await environment.deploy();

          final request = environment.uploadRequest;
          expect(request.url.path, '/upload/v1/$_appName/releases:upload');
          expect(request.headers['authorization'], 'Bearer test-access-token');
          expect(request.bodyBytes, await ipa.readAsBytes());
          expect(environment.requests, hasLength(2));
          expect(environment.workingDirectories.toSet(), {
            environment.appDirectory(null).path,
          });
        },
      );
    }

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test('resolves the IPA in the workflow directory: $dir', () async {
        final ipa = await environment.createIpa(dir: dir);
        await environment.deploy(dir: dir);
        expect(environment.uploadRequest.bodyBytes, await ipa.readAsBytes());
        expect(environment.workingDirectories.toSet(), {
          environment.appDirectory(dir).path,
        });
      });
    }

    test('accepts an absolute IPA path from another directory', () async {
      final ipa = await environment.createIpa();
      await environment.deploy(ipaPath: ipa.path, dir: '');
      expect(environment.uploadRequest.bodyBytes, await ipa.readAsBytes());
    });

    test(
      'uses an explicit App ID without requiring a bundled config',
      () async {
        final ipa = await environment.createIpa(configs: {});
        await environment.deploy(ipaPath: ipa.path, appId: _appId);
        expect(environment.commands, isEmpty);
        expect(
          environment.uploadRequest.url.path,
          '/upload/v1/$_appName/releases:upload',
        );
      },
    );

    test('treats special characters in the IPA path literally', () async {
      const filename = r"-app ' $(touch unexpected) 日本語.ipa";
      final ipa = await environment.createIpa(filename: filename);
      await environment.deploy(ipaPath: filename);
      expect(environment.uploadRequest.bodyBytes, await ipa.readAsBytes());
      expect(
        environment.uploadRequest.headers['X-Goog-Upload-File-Name'],
        Uri.encodeComponent(filename),
      );
      expect(
        await File(
          '${environment.appDirectory(null).path}/unexpected',
        ).exists(),
        isFalse,
      );
    });

    test(
      'sanitizes authentication failures and closes the HTTP client',
      () async {
        await environment.createIpa();
        environment.authStatus = 400;
        await expectLater(
          environment.deploy(),
          throwsA(
            isA<StateError>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('authenticate'),
                isNot(contains('private-response')),
              ),
            ),
          ),
        );
        expect(environment.requests, hasLength(1));
      },
    );

    test('propagates upload failures and closes the HTTP client', () async {
      await environment.createIpa();
      environment.uploadStatus = 403;
      await expectLater(
        environment.deploy(),
        throwsA(
          isA<HttpException>().having(
            (error) => error.message,
            'message',
            contains('HTTP 403'),
          ),
        ),
      );
    });

    for (final configs in [
      <String, String>{},
      {
        'Payload/Runner.app/GoogleService-Info.plist': _plist(_appId),
        'Payload/Other.app/GoogleService-Info.plist': _plist(_appId),
      },
    ]) {
      test(
        'rejects missing or ambiguous app config: ${configs.length}',
        () async {
          await environment.createIpa(configs: configs);
          await expectLater(environment.deploy(), throwsStateError);
          expect(environment.requests, isEmpty);
        },
      );
    }

    for (final plist in [
      'not a plist',
      '<plist><dict><key>OTHER</key><string>value</string></dict></plist>',
      '<plist><dict><key>GOOGLE_APP_ID</key><integer>42</integer></dict></plist>',
    ]) {
      test('rejects invalid or missing GOOGLE_APP_ID: $plist', () async {
        await environment.createIpa(
          configs: {'Payload/Runner.app/GoogleService-Info.plist': plist},
        );
        await expectLater(
          environment.deploy(),
          throwsA(isA<ProcessException>()),
        );
        expect(environment.requests, isEmpty);
      });
    }

    test('does not upload an unreadable IPA', () async {
      await File(
        '${environment.appDirectory(null).path}/app.ipa',
      ).writeAsString('not a zip');
      await expectLater(environment.deploy(), throwsA(isA<ProcessException>()));
      expect(environment.requests, isEmpty);
    });

    test('rejects empty IPA files before authenticating', () async {
      await File('${environment.appDirectory(null).path}/app.ipa').create();
      await expectLater(environment.deploy(), throwsArgumentError);
      expect(environment.requests, isEmpty);
    });

    for (final appId in ['', 'org.example.app', '1:123:android:abcdef']) {
      test('rejects an invalid Firebase iOS App ID: $appId', () async {
        await expectLater(
          environment.deploy(appId: appId),
          throwsArgumentError,
        );
        expect(environment.commands, isEmpty);
        expect(environment.requests, isEmpty);
      });
    }

    for (final secret in [
      'invalid-base64-TEST_PRIVATE_KEY_DO_NOT_LOG!',
      base64Encode(utf8.encode('invalid-json-TEST_PRIVATE_KEY_DO_NOT_LOG')),
      base64Encode(utf8.encode('[]')),
      base64Encode(utf8.encode('{"type":"authorized_user"}')),
      base64Encode(utf8.encode('{"type":"service_account"}')),
      base64Encode(
        utf8.encode(
          jsonEncode({
            'type': 'service_account',
            'client_id': '123',
            'client_email': 'test@example.com',
            'private_key': 'TEST_PRIVATE_KEY_DO_NOT_LOG',
          }),
        ),
      ),
    ]) {
      test(
        'rejects malformed credentials without exposing their contents',
        () async {
          await expectLater(
            environment.deploy(serviceAccountJsonBase64: secret),
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
          expect(environment.commands, isEmpty);
          expect(environment.requests, isEmpty);
        },
      );
    }
  }, testOn: 'mac-os');
}

String _plist(String appId) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>GOOGLE_APP_ID</key><string>$appId</string></dict></plist>
''';

class _TrackingClient extends MockClient {
  _TrackingClient(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

class _UploadEnvironment {
  _UploadEnvironment(this.workspace, this.temporary);

  final Directory workspace;
  final Directory temporary;
  final commands = <String>[];
  final workingDirectories = <String>[];
  final requests = <http.Request>[];
  final clients = <_TrackingClient>[];
  int authStatus = 200;
  int uploadStatus = 200;

  http.Request get uploadRequest =>
      requests.singleWhere((request) => request.url.path.endsWith(':upload'));
  Directory appDirectory(String? dir) => dir == ''
      ? workspace
      : Directory('${workspace.path}/${dir ?? 'apps/dashboard'}');

  static Future<_UploadEnvironment> create() async {
    final workspace = await Directory.systemTemp.createTemp("openci fad ' ");
    final temporary = await Directory.fromUri(
      workspace.uri.resolve('temporary/'),
    ).create();
    final environment = _UploadEnvironment(workspace, temporary);
    await environment.appDirectory(null).create(recursive: true);
    return environment;
  }

  Future<File> createIpa({
    String filename = 'app.ipa',
    String? dir,
    bool binary = false,
    Map<String, String>? configs,
  }) async {
    final directory = appDirectory(dir);
    await directory.create(recursive: true);
    final payload = Directory.fromUri(directory.uri.resolve('Payload/'));
    await payload.create();
    await File.fromUri(payload.uri.resolve('README')).writeAsString('Test IPA');
    for (final config
        in (configs ??
                {
                  'Payload/Runner.app/GoogleService-Info.plist': _plist(_appId),
                })
            .entries) {
      final plist = File.fromUri(directory.uri.resolve(config.key));
      await plist.parent.create(recursive: true);
      await plist.writeAsString(config.value);
      if (binary) {
        final result = await Process.run('plutil', [
          '-convert',
          'binary1',
          plist.path,
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
      }
    }
    final ipa = File('${directory.path}/$filename');
    final result = await Process.run('zip', [
      '-q',
      '-r',
      ipa.path,
      'Payload',
    ], workingDirectory: directory.path);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return ipa;
  }

  Future<void> deploy({
    String ipaPath = 'app.ipa',
    String? serviceAccountJsonBase64,
    String? appId,
    String? dir,
  }) async {
    final ci = OpenCI.forTesting(
      workspacePath: workspace.path,
      currentWorkingDirectory: 'apps/dashboard',
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
    await http.runWithClient(
      () => IOOverrides.runZoned(
        () => ci.flutter.deployIpaToFirebaseAppDistribution(
          ipaPath: ipaPath,
          serviceAccountJsonBase64:
              serviceAccountJsonBase64 ?? _credentialsBase64,
          appId: appId,
          dir: dir,
        ),
        getSystemTempDirectory: () => temporary,
      ),
      () {
        final client = _TrackingClient((request) async {
          requests.add(request);
          // No credential file exists while authentication/upload is in flight.
          expect(await temporary.list().toList(), isEmpty);
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
            return http.Response(
              jsonEncode(
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
              ),
              authStatus,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.url.host, 'firebaseappdistribution.googleapis.com');
          return http.Response(
            jsonEncode({
              'name': '$_release/operations/upload-1',
              'done': true,
              'response': {
                'release': {'name': _release},
                'result': 'RELEASE_CREATED',
              },
            }),
            uploadStatus,
            headers: {'content-type': 'application/json'},
          );
        });
        clients.add(client);
        return client;
      },
    );
  }
}
