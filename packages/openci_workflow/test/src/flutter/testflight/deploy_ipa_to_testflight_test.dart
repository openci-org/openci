import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflow/src/flutter/testflight/app_store_connect_client.dart';
import 'package:openci_workflow/src/flutter/testflight/deploy_ipa_to_testflight.dart';
import 'package:test/test.dart';

const _bundleId = 'org.example.testflight';
const _uploadId = 'upload-1';
const _fileId = 'file-1';
late AppStoreConnectKeys _keys;
late ECPublicKey _publicKey;

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object> _upload(String state, {String id = _uploadId}) => {
  'data': {
    'type': 'buildUploads',
    'id': id,
    'attributes': {
      'state': {
        'state': state,
        'errors': [
          {'code': 'ERROR', 'description': 'private-response'},
        ],
      },
    },
  },
};

void main() {
  group('deployIpaToTestFlight', () {
    late Directory keyDirectory;
    late _Environment environment;

    setUpAll(() async {
      keyDirectory = await Directory.systemTemp.createTemp('openci-test-ec-');
      final key = File('${keyDirectory.path}/key.p8');
      await _run('openssl', [
        'genpkey',
        '-algorithm',
        'EC',
        '-pkeyopt',
        'ec_paramgen_curve:prime256v1',
        '-out',
        key.path,
      ]);
      final public = File('${keyDirectory.path}/public.pem');
      await _run('openssl', [
        'pkey',
        '-in',
        key.path,
        '-pubout',
        '-out',
        public.path,
      ]);
      // Generated only for mocked API requests, not an App Store Connect key.
      _keys = AppStoreConnectKeys(
        issuerId: 'test-issuer',
        keyId: 'TESTKEY123',
        privateKeyBase64: base64Encode(await key.readAsBytes()),
      );
      _publicKey = ECPublicKey(await public.readAsString());
    });
    tearDownAll(() => keyDirectory.delete(recursive: true));
    setUp(() async => environment = await _Environment.create());
    tearDown(() async {
      expect(environment.clients.every((client) => client.closed), isTrue);
      expect(await environment.temporary.list().toList(), isEmpty);
      expect(
        environment.commands.join('\n'),
        isNot(contains(_keys.privateKeyBase64)),
      );
      await environment.workspace.delete(recursive: true);
    });

    for (final binary in [false, true]) {
      test(
        'uploads an IPA and confirms build processing (binary: $binary)',
        () async {
          final ipa = await environment.createIpa(binary: binary);
          await environment.deploy();

          final requests = environment.requests;
          expect(requests.map((r) => r.method), [
            'GET',
            'POST',
            'POST',
            'PUT',
            'PUT',
            'PATCH',
            'GET',
          ]);
          expect(
            requests.first.url.queryParameters['filter[bundleId]'],
            _bundleId,
          );
          final create = jsonDecode(requests[1].body) as Map;
          expect(create['data']['attributes'], {
            'cfBundleShortVersionString': '2.0.0',
            'cfBundleVersion': '42',
            'platform': 'IOS',
          });
          expect(create['data']['relationships']['app']['data'], {
            'type': 'apps',
            'id': '1234567890',
          });
          final reserve = jsonDecode(requests[2].body) as Map;
          expect(reserve['data']['attributes'], {
            'assetType': 'ASSET',
            'fileName': 'app.ipa',
            'fileSize': await ipa.length(),
            'uti': 'com.apple.ipa',
          });
          final parts = requests.where((r) => r.method == 'PUT').toList();
          expect(
            parts.expand((r) => r.bodyBytes).toList(),
            await ipa.readAsBytes(),
          );
          for (final part in parts) {
            expect(part.headers['x-upload-header'], 'provided-by-apple');
            expect(part.contentLength, part.bodyBytes.length);
          }
          final commit = jsonDecode(requests[5].body) as Map;
          expect(commit['data']['attributes'], {'uploaded': true});
          expect(requests.last.url.path, '/v1/buildUploads/$_uploadId');
          expect(
            requests.any((r) => r.url.path.contains('betaGroups')),
            isFalse,
          );
        },
      );
    }

    for (final binary in [false, true]) {
      test(
        'ignores unrelated plist data and dates (binary: $binary)',
        () async {
          await environment.createIpa(
            binary: binary,
            configs: {
              'Payload/Runner.app/Info.plist': _plist(
                extra:
                    '<key>CustomData</key><data>AQI=</data>'
                    '<key>CustomDate</key><date>2026-01-01T00:00:00Z</date>',
              ),
            },
          );
          await environment.deploy();
          expect(
            environment.requests.last.url.path,
            '/v1/buildUploads/$_uploadId',
          );
        },
      );
    }

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test(
        'resolves the IPA in the requested working directory: $dir',
        () async {
          const filename = r"-app ' $(touch unexpected) 日本語.ipa";
          final ipa = await environment.createIpa(filename: filename, dir: dir);
          await environment.deploy(ipaPath: filename, dir: dir);
          expect(environment.workingDirectories.toSet(), {ipa.parent.path});
          expect(await File('${ipa.parent.path}/unexpected').exists(), isFalse);
        },
      );
    }

    test('accepts an absolute IPA path', () async {
      final ipa = await environment.createIpa();
      await environment.deploy(ipaPath: ipa.path, dir: '');
      expect(environment.workingDirectories.toSet(), {
        environment.workspace.path,
      });
    });

    test(
      'keeps polling the same upload through awaiting and processing states',
      () async {
        final states = ['AWAITING_UPLOAD', 'PROCESSING', 'COMPLETE'].iterator;
        environment.intercept = (request) async {
          expect(states.moveNext(), isTrue);
          return _json(_upload(states.current));
        };
        await environment.poll();
        expect(environment.requests.map((r) => r.url.path).toSet(), {
          '/v1/buildUploads/$_uploadId',
        });
        expect(environment.requests, hasLength(3));
      },
    );

    test(
      'does not confuse file delivery completion with build processing',
      () async {
        await environment.createIpa();
        environment.intercept = (request) async =>
            request.url.path == '/v1/buildUploads/$_uploadId'
            ? _json(_upload('FAILED'))
            : null;
        await expectLater(
          environment.deploy(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('processing failed'),
                isNot(contains('private-response')),
              ),
            ),
          ),
        );
        expect(environment.requests.last.method, 'GET');
      },
    );

    test('bounds polling and does not re-upload on timeout', () async {
      environment.intercept = (_) async => _json(_upload('PROCESSING'));
      await expectLater(
        environment.poll(
          timeout: const Duration(milliseconds: 100),
          pollInterval: const Duration(minutes: 1),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(environment.requests.every((r) => r.method == 'GET'), isTrue);
    });

    test('bounds a hanging poll request', () async {
      environment.intercept = (_) => Completer<http.Response>().future;
      await expectLater(
        environment.poll(timeout: const Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );
    });

    for (final state in [null, 'private-unknown-state', 123]) {
      test('rejects an unknown processing state: $state', () async {
        environment.intercept = (_) async => _json({
          'data': {
            'id': _uploadId,
            'type': 'buildUploads',
            'attributes': {
              'state': {'state': state},
            },
          },
        });
        await expectLater(
          environment.poll(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              isNot(contains('private-unknown-state')),
            ),
          ),
        );
      });
    }

    test('rejects a completed response for a different upload', () async {
      environment.intercept = (_) async =>
          _json(_upload('COMPLETE', id: 'other'));
      await expectLater(environment.poll(), throwsStateError);
    });

    for (final path in ['', ' ', 'app.apk', 'app.ipa.zip']) {
      test('rejects an invalid IPA path: $path', () async {
        await expectLater(
          environment.deploy(ipaPath: path),
          throwsArgumentError,
        );
        expect(environment.requests, isEmpty);
        expect(environment.commands, isEmpty);
      });
    }
    test('rejects a nonpositive processing timeout', () async {
      await expectLater(
        environment.deploy(timeout: Duration.zero),
        throwsArgumentError,
      );
      expect(environment.requests, isEmpty);
    });
    test('rejects missing and empty IPA files before API calls', () async {
      await expectLater(
        environment.deploy(
          ipaPath: '${environment.workspace.path}/missing.ipa',
        ),
        throwsA(isA<FileSystemException>()),
      );
      final file = await File(
        '${environment.workspace.path}/empty.ipa',
      ).create();
      await expectLater(
        environment.deploy(ipaPath: file.path),
        throwsArgumentError,
      );
      expect(environment.requests, isEmpty);
    });

    for (final configs in [
      <String, String>{},
      {
        'Payload/First.app/Info.plist': _plist(),
        'Payload/Second.app/Info.plist': _plist(),
      },
      {'Payload/App.app/Info.plist': _plist(bundleId: '')},
      {'Payload/App.app/Info.plist': _plist(version: '')},
      {'Payload/App.app/Info.plist': _plist(buildNumber: '')},
      {'Payload/App.app/Info.plist': _plist(platform: 'iPhoneSimulator')},
      {
        'Payload/App.app/Info.plist': _plist().replaceFirst(
          '<key>CFBundleVersion</key><string>42</string>',
          '',
        ),
      },
      {
        'Payload/App.app/Info.plist': _plist().replaceFirst(
          '<string>42</string>',
          '<integer>42</integer>',
        ),
      },
    ]) {
      test(
        'rejects missing, ambiguous, or unsupported IPA metadata: ${configs.keys}',
        () async {
          await environment.createIpa(configs: configs);
          await expectLater(environment.deploy(), throwsStateError);
          expect(environment.requests, isEmpty);
        },
      );
    }

    for (final secret in [
      'PRIVATE_SECRET!',
      base64Encode(utf8.encode('PRIVATE_SECRET')),
    ]) {
      test('sanitizes invalid private keys', () async {
        await expectLater(
          environment.deploy(
            keys: AppStoreConnectKeys(
              issuerId: 'test-issuer',
              keyId: 'TESTKEY123',
              privateKeyBase64: secret,
            ),
          ),
          throwsA(
            isA<FormatException>()
                .having((e) => e.source, 'source', isNull)
                .having(
                  (e) => e.toString(),
                  'message',
                  isNot(contains('PRIVATE_SECRET')),
                ),
          ),
        );
        expect(environment.commands, isEmpty);
        expect(environment.requests, isEmpty);
      });
    }
    for (final (issuer, keyId) in [('', 'TESTKEY123'), ('test-issuer', '')]) {
      test('requires both issuer ID and key ID: $issuer/$keyId', () async {
        await expectLater(
          environment.deploy(
            keys: AppStoreConnectKeys(
              issuerId: issuer,
              keyId: keyId,
              privateKeyBase64: _keys.privateKeyBase64,
            ),
          ),
          throwsArgumentError,
        );
        expect(environment.requests, isEmpty);
      });
    }

    for (final data in [
      <Object>[],
      [
        {
          'type': 'apps',
          'id': '123',
          'attributes': {'bundleId': 'other'},
        },
      ],
      [
        {
          'type': 'apps',
          'id': '../other',
          'attributes': {'bundleId': _bundleId},
        },
      ],
    ]) {
      test(
        'requires exactly the matching App Store Connect app: $data',
        () async {
          await environment.createIpa();
          environment.intercept = (_) async => _json({'data': data});
          await expectLater(environment.deploy(), throwsStateError);
          expect(environment.requests, hasLength(1));
        },
      );
    }

    for (final (method, path, status) in [
      ('GET', '/v1/apps', 401),
      ('POST', '/v1/buildUploads', 409),
      ('POST', '/v1/buildUploadFiles', 403),
      ('PUT', '/part/0', 500),
      ('PUT', '/part/0', 302),
      ('PATCH', '/v1/buildUploadFiles/$_fileId', 422),
      ('GET', '/v1/buildUploads/$_uploadId', 503),
    ]) {
      test(
        'stops on $method $path HTTP $status and sanitizes errors',
        () async {
          await environment.createIpa();
          environment.intercept = (request) async =>
              request.method == method && request.url.path == path
              ? _json({
                  'errors': [
                    {'detail': 'private-response'},
                  ],
                }, status)
              : null;
          await expectLater(
            environment.deploy(),
            throwsA(
              isA<HttpException>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains('HTTP $status'),
                  isNot(contains('private-response')),
                ),
              ),
            ),
          );
          expect(environment.requests.last.url.path, path);
        },
      );
    }
    for (final error in [
      http.ClientException('private-upload-url'),
      TimeoutException('private-token'),
    ]) {
      test('sanitizes transport ${error.runtimeType}', () async {
        await environment.createIpa();
        environment.intercept = (_) async => throw error;
        await expectLater(
          environment.deploy(),
          throwsA(
            predicate<Object>(
              (e) =>
                  !e.toString().contains('private-upload-url') &&
                  !e.toString().contains('private-token'),
            ),
          ),
        );
      });
    }

    for (final body in ['private-invalid-json', '[]']) {
      test('rejects malformed API responses: $body', () async {
        await environment.createIpa();
        environment.intercept = (_) async => http.Response(body, 200);
        await expectLater(
          environment.deploy(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              isNot(contains(body)),
            ),
          ),
        );
      });
    }

    for (final field in [
      'method',
      'url',
      'offset',
      'length',
      'requestHeaders',
    ]) {
      test(
        'validates every upload operation before sending bytes: $field',
        () async {
          await environment.createIpa();
          environment.modifyParts = (parts) {
            parts.last[field] = switch (field) {
              'method' => 'DELETE',
              'url' => 'http://private-upload-url',
              'offset' => 0,
              'length' => -1,
              _ => [
                {'name': 'x-header\r\n', 'value': 'private-token'},
              ],
            };
          };
          await expectLater(
            environment.deploy(),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                isNot(contains('private')),
              ),
            ),
          );
          expect(environment.requests.any((r) => r.method == 'PUT'), isFalse);
        },
      );
    }
    test(
      'rejects missing chunks instead of committing incomplete bytes',
      () async {
        await environment.createIpa();
        environment.modifyParts = (parts) => parts.removeLast();
        await expectLater(environment.deploy(), throwsStateError);
        expect(environment.requests.any((r) => r.method == 'PUT'), isFalse);
      },
    );
    test('sorts upload operations by offset', () async {
      final ipa = await environment.createIpa();
      environment.modifyParts = (parts) {
        final first = parts.removeAt(0);
        parts.add(first);
      };
      await environment.deploy();
      expect(
        environment.requests
            .where((r) => r.method == 'PUT')
            .expand((r) => r.bodyBytes)
            .toList(),
        await ipa.readAsBytes(),
      );
    });
  }, testOn: 'mac-os');
}

class _Environment {
  _Environment(this.workspace, this.temporary);

  final Directory workspace;
  final Directory temporary;
  final requests = <http.Request>[];
  final clients = <_TrackingClient>[];
  final commands = <String>[];
  final workingDirectories = <String>[];
  Future<http.Response?> Function(http.Request)? intercept;
  void Function(List<Map<String, Object>>)? modifyParts;

  static Future<_Environment> create() async {
    final workspace = await Directory.systemTemp.createTemp(
      "openci testflight ' ",
    );
    final temporary = await Directory('${workspace.path}/temporary').create();
    return _Environment(workspace, temporary);
  }

  Future<File> createIpa({
    String filename = 'app.ipa',
    String? dir,
    bool binary = false,
    Map<String, String>? configs,
  }) async {
    final directory = Directory('${workspace.path}/${dir ?? 'apps/mobile'}');
    await Directory('${directory.path}/Payload').create(recursive: true);
    await File('${directory.path}/Payload/README').writeAsString('Test IPA');
    for (final entry
        in (configs ??
                {
                  "Payload/Runner's [prod].app/Info.plist": _plist(),
                  'Payload/Runner.app/Watch/Watch.app/Info.plist': _plist(
                    bundleId: 'other',
                  ),
                })
            .entries) {
      final plist = File('${directory.path}/${entry.key}');
      await plist.parent.create(recursive: true);
      await plist.writeAsString(entry.value);
      if (binary) await _run('plutil', ['-convert', 'binary1', plist.path]);
    }
    final ipa = File('${directory.path}/$filename');
    await _run('zip', ['-q', '-r', ipa.path, 'Payload'], cwd: directory.path);
    return ipa;
  }

  Future<void> deploy({
    String ipaPath = 'app.ipa',
    AppStoreConnectKeys? keys,
    String? dir,
    Duration timeout = const Duration(minutes: 30),
  }) async {
    final ci = OpenCI(
      workflowName: 'test',
      ciTriggers: const [CITrigger.push(branch: 'test')],
      workspacePath: workspace.path,
      currentWorkingDirectory: 'apps/mobile',
      commandRunner: (command, {required workingDirectory}) async {
        commands.add(command);
        workingDirectories.add(workingDirectory);
        await _run('/bin/sh', ['-c', command], cwd: workingDirectory);
      },
    );
    await withClient(
      () => ci.flutter.deployIpaToTestFlight(
        ipaPath: ipaPath,
        ascKeys: keys ?? _keys,
        dir: dir,
        processingTimeout: timeout,
      ),
    );
  }

  Future<void> poll({
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = Duration.zero,
  }) => withClient(() async {
    final client = AppStoreConnectClient(_keys);
    try {
      await waitForTestFlightProcessing(
        client,
        _uploadId,
        timeout: timeout,
        pollInterval: pollInterval,
      );
    } finally {
      client.close();
    }
  });

  Future<void> withClient(Future<void> Function() action) => http.runWithClient(
    () => IOOverrides.runZoned(action, getSystemTempDirectory: () => temporary),
    () {
      final client = _TrackingClient((request) async {
        requests.add(request);
        expect(await temporary.list().toList(), isEmpty);
        expect(request.followRedirects, isFalse);
        if (request.url.host == 'api.appstoreconnect.apple.com') {
          final token = request.headers['authorization']!.substring(
            'Bearer '.length,
          );
          final jwt = JWT.verify(token, _publicKey);
          expect(jwt.header?['alg'], 'ES256');
          expect(jwt.header?['kid'], 'TESTKEY123');
          expect(jwt.payload['iss'], 'test-issuer');
          expect(jwt.payload['aud'], 'appstoreconnect-v1');
          expect(jwt.payload['exp'] - jwt.payload['iat'], 900);
        } else {
          expect(request.url.host, 'uploads.example.com');
          expect(request.headers.containsKey('authorization'), isFalse);
        }
        final override = await intercept?.call(request);
        return override ?? respond(request);
      });
      clients.add(client);
      return client;
    },
  );

  http.Response respond(http.Request request) {
    if (request.url.path == '/v1/apps') {
      return _json({
        'data': [
          {
            'type': 'apps',
            'id': '1234567890',
            'attributes': {'bundleId': _bundleId},
          },
        ],
      });
    }
    if (request.url.path == '/v1/buildUploads') {
      return _json(_upload('AWAITING_UPLOAD'), 201);
    }
    if (request.url.path == '/v1/buildUploads/$_uploadId') {
      return _json(_upload('COMPLETE'));
    }
    if (request.url.path == '/v1/buildUploadFiles') {
      final size =
          (jsonDecode(request.body) as Map)['data']['attributes']['fileSize']
              as int;
      final half = size ~/ 2;
      final parts = <Map<String, Object>>[
        for (final (part, offset, length) in [
          (0, 0, half),
          (1, half, size - half),
        ])
          {
            'method': 'PUT',
            'url':
                'https://uploads.example.com/part/$part?signature=private-url',
            'offset': offset,
            'length': length,
            'requestHeaders': [
              {'name': 'x-upload-header', 'value': 'provided-by-apple'},
            ],
          },
      ];
      modifyParts?.call(parts);
      return _json({
        'data': {
          'type': 'buildUploadFiles',
          'id': _fileId,
          'attributes': {'uploadOperations': parts},
        },
      }, 201);
    }
    if (request.method == 'PUT') return http.Response('', 200);
    if (request.url.path == '/v1/buildUploadFiles/$_fileId') {
      return _json({
        'data': {
          'type': 'buildUploadFiles',
          'id': _fileId,
          'attributes': {
            'assetDeliveryState': {'state': 'COMPLETE'},
          },
        },
      });
    }
    throw StateError('Unexpected API request in test.');
  }
}

String _plist({
  String bundleId = _bundleId,
  String version = '2.0.0',
  String buildNumber = '42',
  String platform = 'iPhoneOS',
  String extra = '',
}) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$bundleId</string>
<key>CFBundleShortVersionString</key><string>$version</string>
<key>CFBundleVersion</key><string>$buildNumber</string>
<key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
$extra
</dict></plist>
''';

Future<void> _run(String command, List<String> arguments, {String? cwd}) async {
  final result = await Process.run(command, arguments, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw ProcessException(
      command,
      arguments,
      '${result.stderr}',
      result.exitCode,
    );
  }
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
