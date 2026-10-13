import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

const _packageName = 'com.example.app';
const _editsPath = '/androidpublisher/v3/applications/$_packageName/edits';
const _editPath = '$_editsPath/123';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late Directory keyDirectory;
  late String credentials;

  setUpAll(() async {
    keyDirectory = await Directory.systemTemp.createTemp('openci-play-key-');
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
    // Generated only for mocked OAuth requests, not a real service account.
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

  group('deployAabToPlayConsole', () {
    late Directory workspace;
    late Directory temporary;
    late OpenCI ci;
    late List<String> commands;
    late List<String> workingDirectories;
    late List<http.Request> requests;
    late List<_TrackingClient> clients;
    late MockClientHandler handler;
    late int authStatus;
    const uploadPath = '/upload$_editPath/bundles';

    http.Response respond(http.Request request) {
      switch ((request.method, request.url.path)) {
        case ('POST', _editsPath):
          expect(jsonDecode(request.body), isEmpty);
          return _json({'id': '123'});
        case ('POST', final path) when path == uploadPath:
          return _json({'versionCode': 42});
        case ('PUT', final path) when path.startsWith('$_editPath/tracks/'):
          return _json(jsonDecode(request.body));
        case ('POST', '$_editPath:commit'):
          return _json({'id': '123'});
        case ('DELETE', _editPath):
          return http.Response('', 204);
        default:
          fail('Unexpected request: ${request.method} ${request.url}');
      }
    }

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp("openci play ' ");
      temporary = await Directory('${workspace.path}/temporary').create();
      commands = [];
      workingDirectories = [];
      requests = [];
      clients = [];
      authStatus = 200;
      handler = (request) async => respond(request);
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
      String? filename,
      String dir = 'apps/mobile',
    }) async {
      final file = File(
        '${workspace.path}/$dir/${filename ?? 'app.aab'}',
      );
      await file.parent.create(recursive: true);
      return file.writeAsBytes(List.generate(65536, (index) => index % 256));
    }

    Future<void> deploy({
      String? path,
      String packageName = _packageName,
      String? serviceAccountJsonBase64,
      String track = 'internal',
      bool draft = false,
      String? dir,
    }) => http.runWithClient(
      () => IOOverrides.runZoned(
        () => ci.flutter.deployAabToPlayConsole(
          aabPath: path ?? 'app.aab',
          packageName: packageName,
          serviceAccountJsonBase64: serviceAccountJsonBase64 ?? credentials,
          track: track,
          draft: draft,
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
            expect(
              claims['scope'],
              'https://www.googleapis.com/auth/androidpublisher',
            );
            return _json(
              authStatus == 200
                  ? {
                      'access_token': 'test-access-token',
                      'expires_in': 3600,
                      'token_type': 'Bearer',
                    }
                  : {'error': 'private-response'},
              authStatus,
            );
          }
          expect(request.url.host, 'androidpublisher.googleapis.com');
          expect(
            request.headers['authorization'],
            'Bearer test-access-token',
          );
          return handler(request);
        });
        clients.add(client);
        return client;
      },
    );

    test(
      'uploads bytes, releases to internal testing, then commits',
      () async {
        final file = await createAab(filename: '日本語 app.aab');
        await deploy(path: file.path, dir: 'nonexistent');

        expect(commands, isEmpty);
        expect(requests.map((r) => '${r.method} ${r.url.path}').skip(1), [
          'POST $_editsPath',
          'POST $uploadPath',
          'PUT $_editPath/tracks/internal',
          'POST $_editPath:commit',
        ]);
        final upload = requests[2];
        expect(upload.url.queryParameters, {'uploadType': 'media'});
        expect(
          upload.headers['Content-Type'],
          'application/octet-stream',
        );
        expect(upload.contentLength, await file.length());
        expect(upload.bodyBytes, await file.readAsBytes());
        expect(jsonDecode(requests[3].body), {
          'track': 'internal',
          'releases': [
            {
              'versionCodes': ['42'],
              'status': 'completed',
            },
          ],
        });
        expect(requests.last.url.queryParameters, {
          'changesInReviewBehavior': 'ERROR_IF_IN_REVIEW',
        });
        expect(requests.last.body, isEmpty);
      },
    );

    test('can commit a draft to a custom track', () async {
      final file = await createAab();
      await deploy(path: file.path, track: 'wear:closed-test', draft: true);
      expect(requests[3].url.path, '$_editPath/tracks/wear:closed-test');
      expect(jsonDecode(requests[3].body), {
        'track': 'wear:closed-test',
        'releases': [
          {
            'versionCodes': ['42'],
            'status': 'draft',
          },
        ],
      });
    });

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test('resolves relative paths with working directory $dir', () async {
        const filename = r"-app ' $(touch unexpected) 日本語.aab";
        final file = await createAab(
          filename: filename,
          dir: dir ?? 'apps/mobile',
        );
        await deploy(path: filename, dir: dir);
        expect(workingDirectories, [file.parent.path]);
        expect(requests[2].bodyBytes, await file.readAsBytes());
        expect(
          await File('${file.parent.path}/unexpected').exists(),
          isFalse,
        );
      });
    }

    test(
      'rejects invalid paths and identifiers before authenticating',
      () async {
        for (final path in ['', 'file.zip', 'app.apk']) {
          await expectLater(deploy(path: path), throwsArgumentError);
        }
        for (final packageName in [
          '',
          'app',
          'com.example/app',
          '1.example',
        ]) {
          await expectLater(
            deploy(packageName: packageName),
            throwsArgumentError,
          );
        }
        for (final track in [
          '',
          ' ',
          '..',
          '../production',
          'a\\b',
          'internal\n',
        ]) {
          await expectLater(deploy(track: track), throwsArgumentError);
        }
        expect(requests, isEmpty);
      },
    );

    test('rejects missing and empty files before authenticating', () async {
      await expectLater(
        deploy(path: '${workspace.path}/missing.aab'),
        throwsA(isA<FileSystemException>()),
      );
      final file = await createAab();
      await file.writeAsBytes([]);
      await expectLater(deploy(path: file.path), throwsArgumentError);
      expect(requests, isEmpty);
    });

    test('rejects malformed credentials without exposing them', () async {
      for (final secret in [
        'private-response',
        base64Encode(
          utf8.encode(
            jsonEncode({
              'type': 'service_account',
              'client_id': 'id',
              'client_email': 'private-response',
              'private_key': 'private-response',
            }),
          ),
        ),
      ]) {
        await expectLater(
          deploy(serviceAccountJsonBase64: secret),
          throwsA(
            isA<FormatException>().having(
              (e) => e.toString(),
              'message',
              allOf(
                isNot(contains(secret)),
                isNot(contains('private-response')),
              ),
            ),
          ),
        );
      }
      expect(requests, isEmpty);
    });

    test('does not create an edit if authentication fails', () async {
      final file = await createAab();
      authStatus = 400;
      await expectLater(
        deploy(path: file.path),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            isNot(contains('private-response')),
          ),
        ),
      );
      expect(requests, hasLength(1));
    });

    for (final (method, path) in [
      ('POST', _editsPath),
      ('POST', uploadPath),
      ('PUT', '$_editPath/tracks/internal'),
      ('POST', '$_editPath:commit'),
    ]) {
      test(
        'stops on failure at $method $path and discards its edit',
        () async {
          final file = await createAab();
          handler = (request) async =>
              request.method == method && request.url.path == path
              ? _json({'error': 'private-response'}, 403)
              : respond(request);
          await expectLater(
            deploy(path: file.path),
            throwsA(
              isA<HttpException>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains('HTTP 403'),
                  isNot(contains('private-response')),
                ),
              ),
            ),
          );
          final failed = requests.indexWhere(
            (r) => r.method == method && r.url.path == path,
          );
          expect(
            requests.skip(failed + 1).map((r) => '${r.method} ${r.url.path}'),
            path == _editsPath ? isEmpty : ['DELETE $_editPath'],
          );
        },
      );
    }

    test('keeps an existing app review intact', () async {
      final file = await createAab();
      handler = (r) async => r.url.path.endsWith(':commit')
          ? _json({
              'error': {
                'message': 'private-response',
                'details': [
                  {'reason': 'CHANGES_ALREADY_IN_REVIEW'},
                ],
              },
            }, 400)
          : respond(r);
      await expectLater(
        deploy(path: file.path),
        throwsA(
          isA<HttpException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('changes in review'),
              isNot(contains('private-response')),
            ),
          ),
        ),
      );
      final commits = requests.where((r) => r.url.path.endsWith(':commit'));
      expect(commits, hasLength(1));
      expect(
        commits.single.url.queryParameters['changesInReviewBehavior'],
        'ERROR_IF_IN_REVIEW',
      );
      expect(requests.last.method, 'DELETE');
    });

    test(
      'does not follow an upload redirect or commit on redirect',
      () async {
        final file = await createAab();
        handler = (request) async => request.url.path == uploadPath
            ? http.Response(
                '',
                302,
                headers: {'location': 'https://example.com/secret'},
              )
            : respond(request);
        await expectLater(
          deploy(path: file.path),
          throwsA(isA<HttpException>()),
        );
        expect(requests.last.method, 'DELETE');
        expect(requests, hasLength(4));
      },
    );

    for (final error in [
      http.ClientException('private-response'),
      TimeoutException('private-response'),
    ]) {
      test('sanitizes ${error.runtimeType} and discards the edit', () async {
        final file = await createAab();
        handler = (request) async {
          if (request.url.path == uploadPath) throw error;
          return respond(request);
        };
        await expectLater(
          deploy(path: file.path),
          throwsA(
            predicate<Object>(
              (e) => !e.toString().contains('private-response'),
            ),
          ),
        );
        expect(requests.last.method, 'DELETE');
        expect(requests, hasLength(4));
      });
    }

    test('preserves the original error when cleanup also fails', () async {
      final file = await createAab();
      handler = (request) async => switch (request.method) {
        'DELETE' => _json({'error': 'private-cleanup-response'}, 500),
        _ when request.url.path == uploadPath => _json({}, 400),
        _ => respond(request),
      };
      await expectLater(
        deploy(path: file.path),
        throwsA(
          isA<HttpException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 400'),
          ),
        ),
      );
    });

    test('rejects untrusted edit IDs without using them in a URL', () async {
      final file = await createAab();
      for (final id in [
        null,
        '',
        '../../other',
        'https://example.com/edit',
      ]) {
        requests.clear();
        handler = (_) async => _json({'id': id});
        await expectLater(deploy(path: file.path), throwsStateError);
        expect(requests, hasLength(2));
      }
    });

    test('does not release invalid uploaded version codes', () async {
      final file = await createAab();
      for (final code in [null, 0, -1, '42']) {
        requests.clear();
        handler = (r) async => r.url.path == uploadPath
            ? _json({'versionCode': code})
            : respond(r);
        await expectLater(deploy(path: file.path), throwsStateError);
        expect(requests, hasLength(4));
        expect(requests.last.method, 'DELETE');
      }
    });

    test(
      'requires Google to confirm the requested track, version and status',
      () async {
        final file = await createAab();
        for (final response in [
          <String, Object>{},
          {
            'track': 'production',
            'releases': [
              {
                'versionCodes': ['42'],
                'status': 'completed',
              },
            ],
          },
          {
            'track': 'internal',
            'releases': [
              {
                'versionCodes': ['41'],
                'status': 'completed',
              },
            ],
          },
          {
            'track': 'internal',
            'releases': [
              {
                'versionCodes': ['42'],
                'status': 'draft',
              },
            ],
          },
        ]) {
          requests.clear();
          handler = (r) async =>
              r.method == 'PUT' ? _json(response) : respond(r);
          await expectLater(deploy(path: file.path), throwsStateError);
          expect(requests, hasLength(5));
          expect(requests.last.method, 'DELETE');
        }
      },
    );

    test('fails on an unconfirmed commit', () async {
      final file = await createAab();
      handler = (r) async =>
          r.url.path.endsWith(':commit') ? _json({'id': 'other'}) : respond(r);
      await expectLater(
        deploy(path: file.path),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Check Play Console before retrying'),
          ),
        ),
      );
      expect(requests.last.method, 'DELETE');
    });

    test(
      'rejects malformed JSON without exposing server responses',
      () async {
        final file = await createAab();
        for (final body in ['private-response', '[]']) {
          handler = (r) async =>
              r.url.path == uploadPath ? http.Response(body, 200) : respond(r);
          await expectLater(
            deploy(path: file.path),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                isNot(contains(body)),
              ),
            ),
          );
        }
      },
    );
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
