import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

const _version = 'sites/demo-site/versions/version-1';
late String _credentials;

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late Directory keys;
  late _Environment env;
  setUpAll(() async {
    keys = await Directory.systemTemp.createTemp('openci-hosting-test-key-');
    final key = File('${keys.path}/key.pem');
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
    // Generated solely for mocked OAuth; this is not a real service account.
    _credentials = base64Encode(
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
  tearDownAll(() => keys.delete(recursive: true));
  setUp(() async => env = await _Environment.create());
  tearDown(() async {
    expect(env.clients.every((c) => c.closed), isTrue);
    expect(await env.temporary.list().toList(), isEmpty);
    await env.root.delete(recursive: true);
  });

  test(
    'public OpenCI API authenticates with SA JWT and the Hosting scope',
    () async {
      final url = await env.deploy();
      expect(url.toString(), 'https://demo-site.web.app');
      final oauth = env.requests.first;
      expect(oauth.url.host, 'oauth2.googleapis.com');
      expect(
        oauth.bodyFields['grant_type'],
        'urn:ietf:params:oauth:grant-type:jwt-bearer',
      );
      final assertion = oauth.bodyFields['assertion']!.split('.');
      final claims =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(
                    base64Url.normalize(assertion[1]),
                  ),
                ),
              )
              as Map;
      expect(claims['iss'], 'test@test-project.iam.gserviceaccount.com');
      expect(
        claims['scope'],
        'https://www.googleapis.com/auth/firebase.hosting',
      );
      expect(
        env.requests
            .skip(1)
            .every(
              (r) => r.headers['authorization'] == 'Bearer test-access-token',
            ),
        isTrue,
      );
      expect(env.requests.every((r) => !r.followRedirects), isTrue);
    },
  );

  test(
    'public preview API prefixes the stable channel ID and defaults to one hour',
    () async {
      final url = await env.deploy(preview: true);
      expect(url.host, 'demo-site--openci-pr-17-abc123.web.app');
      final create = env.requests.singleWhere(
        (r) => r.method == 'POST' && r.url.path.endsWith('/channels'),
      );
      expect(create.url.queryParameters, {'channelId': 'openci-pr-17'});
      expect(jsonDecode(create.body)['ttl'], '3600s');
      expect(
        env.requests.last.url.path,
        '/v1beta1/sites/demo-site/channels/openci-pr-17/releases',
      );
    },
  );

  test('resolves relative content against the workflow directory', () async {
    await env.deploy();
    expect(env.uploads.single.bodyBytes, isNotEmpty);
    expect(
      gzip.decode(env.uploads.single.bodyBytes),
      utf8.encode('workflow content'),
    );
  });

  test(
    'dir overrides the workflow directory and shell characters are literal',
    () async {
      const path = r"other app ' $(touch unexpected)";
      final content = await Directory(
        '${env.root.path}/$path/dist',
      ).create(recursive: true);
      await File('${content.path}/index.html').writeAsString('override');
      await env.deploy(dir: path);
      expect(
        gzip.decode(env.uploads.single.bodyBytes),
        utf8.encode('override'),
      );
      expect(await File('${env.root.path}/unexpected').exists(), isFalse);
    },
  );

  test(
    'accepts absolute content paths and dir empty means workspace root',
    () async {
      await env.deploy(publicDirectory: env.content.path);
      env.requests.clear();
      final content = await Directory('${env.root.path}/dist').create();
      await File(
        '${content.path}/index.html',
      ).writeAsString('workspace content');
      await env.deploy(dir: '');
      expect(
        gzip.decode(env.uploads.single.bodyBytes),
        utf8.encode('workspace content'),
      );
    },
  );

  test(
    'excludes hidden files, firebase.json and node_modules but keeps .well-known',
    () async {
      await File('${env.content.path}/.env').writeAsString('private-secret');
      await File(
        '${env.content.path}/firebase.json',
      ).writeAsString('private-config');
      await Directory('${env.content.path}/node_modules').create();
      await File(
        '${env.content.path}/node_modules/package.js',
      ).writeAsString('module');
      await Directory('${env.content.path}/.well-known').create();
      await File(
        '${env.content.path}/.well-known/assetlinks.json',
      ).writeAsString('[]');
      await env.deploy();
      final manifest =
          jsonDecode(
                env.requests
                    .singleWhere((r) => r.url.path.endsWith(':populateFiles'))
                    .body,
              )['files']
              as Map;
      expect(manifest.keys, ['/.well-known/assetlinks.json', '/index.html']);
      expect(
        env.uploads.map((r) => utf8.decode(gzip.decode(r.bodyBytes))),
        isNot(contains('private-secret')),
      );
    },
  );

  test('refuses symlinks before authentication or publishing', () async {
    final private = File('${env.root.path}/private.txt');
    await private.writeAsString('private-secret');
    await Link('${env.content.path}/linked.txt').create(private.path);
    await expectLater(env.deploy(), throwsArgumentError);
    expect(env.requests, isEmpty);
  });

  for (final path in ['', 'missing-directory', 'empty-directory']) {
    test(
      'rejects missing, empty or blank output before making requests: $path',
      () async {
        if (path == 'empty-directory') {
          await Directory('${env.root.path}/web app/$path').create();
        }
        await expectLater(
          env.deploy(publicDirectory: path),
          throwsArgumentError,
        );
        expect(env.requests, isEmpty);
      },
    );
  }

  for (final value in [
    'private-key-not-base64!!!',
    base64Encode(utf8.encode('{"private_key":"private-key"}')),
    base64Encode(
      utf8.encode('{"type":"authorized_user","refresh_token":"private-token"}'),
    ),
  ]) {
    test('rejects invalid SA keys without echoing supplied values', () async {
      await expectLater(
        env.deploy(credentials: value),
        throwsA(
          isA<FormatException>().having(
            (e) => e.toString(),
            'message',
            allOf(
              isNot(contains(value)),
              isNot(contains('private-key')),
              isNot(contains('private-token')),
            ),
          ),
        ),
      );
      expect(env.requests, isEmpty);
    });
  }

  test(
    'sanitizes OAuth failures and removes compressed build output',
    () async {
      env.authStatus = 400;
      await expectLater(
        env.deploy(),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('authenticate'),
              isNot(contains('private-response')),
            ),
          ),
        ),
      );
      expect(env.requests, hasLength(1));
    },
  );

  test('sanitizes invalid ServingConfig before making requests', () async {
    await expectLater(
      env.deploy(config: {'private-field': Object()}),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.toString(),
          'message',
          isNot(contains('private-field')),
        ),
      ),
    );
    expect(env.requests, isEmpty);
  });

  for (final id in ['live', '', '../private', 'UPPER', 'name with spaces']) {
    test('rejects unsafe preview channel IDs: $id', () async {
      await expectLater(
        env.deploy(preview: true, channelId: id),
        throwsArgumentError,
      );
      expect(env.requests, isEmpty);
    });
  }

  for (final duration in [Duration.zero, const Duration(days: 31)]) {
    test('bounds preview expiry: $duration', () async {
      await expectLater(
        env.deploy(preview: true, expiresIn: duration),
        throwsArgumentError,
      );
      expect(env.requests, isEmpty);
    });
  }

  for (final budget in [0, 101]) {
    test('bounds preview budget: $budget', () async {
      await expectLater(
        env.deploy(preview: true, budget: budget),
        throwsArgumentError,
      );
      expect(env.requests, isEmpty);
    });
  }

  test('rejects unsafe site IDs before authentication', () async {
    await expectLater(env.deploy(siteId: '../private'), throwsArgumentError);
    expect(env.requests, isEmpty);
  });
}

class _Environment {
  _Environment(this.root, this.content, this.temporary);

  final Directory root;
  final Directory content;
  final Directory temporary;
  final requests = <http.Request>[];
  final clients = <_TrackingClient>[];
  int authStatus = 200;

  static Future<_Environment> create() async {
    final root = await Directory.systemTemp.createTemp(
      'openci-hosting-public-',
    );
    final content = await Directory(
      '${root.path}/web app/dist',
    ).create(recursive: true);
    await File('${content.path}/index.html').writeAsString('workflow content');
    final temporary = await Directory('${root.path}/temporary').create();
    return _Environment(root, content, temporary);
  }

  List<http.Request> get uploads => requests
      .where((r) => r.url.host == 'upload-firebasehosting.googleapis.com')
      .toList();

  Future<Uri> deploy({
    bool preview = false,
    String siteId = 'demo-site',
    String channelId = 'pr-17',
    String publicDirectory = 'dist',
    String? credentials,
    String? dir,
    Duration expiresIn = const Duration(hours: 1),
    int budget = 20,
    Map<String, Object?> config = const {},
  }) async {
    final ci = OpenCI(
      workflowName: 'test',
      ciTriggers: const [],
      workspacePath: root.path,
      currentWorkingDirectory: 'web app',
      commandRunner: (_, {required workingDirectory}) async {
        fail('Hosting must not invoke a shell or Firebase CLI.');
      },
    );
    return http.runWithClient(
      () => IOOverrides.runZoned(
        () => preview
            ? ci.firebaseHosting.deployPreview(
                siteId: siteId,
                channelId: channelId,
                publicDirectory: publicDirectory,
                serviceAccountJsonBase64: credentials ?? _credentials,
                dir: dir,
                config: config,
                expiresIn: expiresIn,
                maxPreviewChannels: budget,
              )
            : ci.firebaseHosting.deploy(
                siteId: siteId,
                publicDirectory: publicDirectory,
                serviceAccountJsonBase64: credentials ?? _credentials,
                dir: dir,
                config: config,
              ),
        getSystemTempDirectory: () => temporary,
      ),
      () {
        final client = _TrackingClient((r) async {
          requests.add(r);
          // Only compressed public assets may exist in the helper's temp folder.
          await for (final entity in temporary.list(recursive: true)) {
            if (entity is File) {
              expect(entity.path, endsWith('.gz'));
              expect(
                utf8.decode(gzip.decode(await entity.readAsBytes())),
                isNot(contains('PRIVATE KEY')),
              );
            }
          }
          if (r.url.host == 'oauth2.googleapis.com') {
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
          final path = r.url.path;
          if (r.url.host.startsWith('upload-') || r.method == 'DELETE') {
            return http.Response('', 200);
          }
          if (r.method == 'GET' && path.endsWith('/channels')) return _json({});
          if (path.endsWith('/channels') ||
              path.contains('/channels/') && r.method == 'PATCH') {
            return _json({
              'name': 'sites/demo-site/channels/openci-pr-17',
              'url': 'https://demo-site--openci-pr-17-abc123.web.app',
              'labels': {'openci-workflow': 'preview'},
            });
          }
          if (path.endsWith(':populateFiles')) {
            return _json({
              'uploadRequiredHashes': (jsonDecode(r.body)['files'] as Map)
                  .values
                  .toList(),
              'uploadUrl':
                  'https://upload-firebasehosting.googleapis.com/upload/$_version/files',
            });
          }
          if (r.method == 'PATCH') {
            return _json({'name': _version, 'status': 'FINALIZED'});
          }
          if (path.endsWith('/releases')) {
            return _json({
              'version': {'name': _version},
              'type': 'DEPLOY',
            });
          }
          return _json({'name': _version});
        });
        clients.add(client);
        return client;
      },
    );
  }
}

class _TrackingClient extends MockClient {
  _TrackingClient(super.fn);
  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}
