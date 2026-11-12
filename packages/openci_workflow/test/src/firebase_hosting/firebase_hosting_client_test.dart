import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/src/firebase_hosting/firebase_hosting_client.dart';
import 'package:openci_workflow/src/firebase_hosting/hosting_files.dart';
import 'package:test/test.dart';

const _site = 'demo-site';
const _version = 'sites/$_site/versions/version-1';
const _channel = 'openci-pr-123';
final _now = DateTime.utc(2026, 11, 12, 6);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _channelData(
  String id, {
  bool owned = true,
  DateTime? updated,
  DateTime? expires,
}) => {
  'name': 'sites/$_site/channels/$id',
  'url': 'https://$_site--$id-abc123.web.app',
  'createTime': _now.subtract(const Duration(days: 1)).toIso8601String(),
  'updateTime': (updated ?? _now).toIso8601String(),
  'expireTime': (expires ?? _now.add(const Duration(hours: 1)))
      .toIso8601String(),
  if (owned) 'labels': {'openci-workflow': 'preview'},
};

void main() {
  late _Environment env;
  setUp(() async => env = await _Environment.create());
  tearDown(() => env.close());

  test(
    'deploys exact gzip bytes with SHA-256 hashes and ServingConfig',
    () async {
      const config = {
        'rewrites': [
          {'glob': '**', 'path': '/index.html'},
        ],
      };
      expect(
        await env.deploy(config: config),
        Uri.parse('https://$_site.web.app'),
      );
      final manifest =
          jsonDecode(
                env.requests
                    .singleWhere(
                      (r) => r.url.path.endsWith(':populateFiles'),
                    )
                    .body,
              )['files']
              as Map;
      expect(manifest.keys, ['/assets/日本語.bin', '/copy.html', '/index.html']);
      expect(manifest['/copy.html'], manifest['/index.html']);
      final uploads = env.requests.where(
        (r) => r.url.host.startsWith('upload-'),
      );
      expect(uploads, hasLength(2));
      for (final upload in uploads) {
        final hash = upload.url.pathSegments.last;
        expect(sha256.convert(upload.bodyBytes).toString(), hash);
        final snapshot = env.files.files.firstWhere((f) => f.hash == hash);
        expect(upload.bodyBytes, await snapshot.compressed.readAsBytes());
        expect(
          gzip.decode(upload.bodyBytes),
          await File(
            '${env.content.path}${snapshot.path}',
          ).readAsBytes(),
        );
        expect(upload.contentLength, upload.bodyBytes.length);
        expect(upload.headers['content-type'], 'application/octet-stream');
      }
      expect(jsonDecode(env.requests.first.body), {'config': config});
      final finalize = env.requests.singleWhere((r) => r.method == 'PATCH');
      expect(finalize.url.queryParameters, {'updateMask': 'status'});
      expect(jsonDecode(finalize.body), {'status': 'FINALIZED'});
      expect(env.requests.last.url.path, '/v1beta1/sites/$_site/releases');
      expect(env.requests.last.url.queryParameters, {'versionName': _version});
      expect(env.requests.every((r) => !r.followRedirects), isTrue);
    },
  );

  test(
    'sends manifests in batches of at most 1000 and uploads each hash once',
    () async {
      final file = env.files.files.first;
      final files = List.generate(
        1001,
        (i) => HostingFile('/$i', file.hash, file.compressed),
      );
      await env.deploy(files: files);
      final batches = env.requests.where(
        (r) => r.url.path.endsWith(':populateFiles'),
      );
      expect(batches.map((r) => (jsonDecode(r.body)['files'] as Map).length), [
        1000,
        1,
      ]);
      expect(
        env.requests.where((r) => r.url.host.startsWith('upload-')),
        hasLength(1),
      );
    },
  );

  test('skips files already uploaded to Firebase', () async {
    env.intercept = (r) async =>
        r.url.path.endsWith(':populateFiles') ? _json({}) : null;
    await env.deploy();
    expect(
      env.requests.where((r) => r.url.host.startsWith('upload-')),
      isEmpty,
    );
  });

  test(
    'accepts fully qualified project resource names for live and preview deployments',
    () async {
      Object? canonical(Object? value) {
        if (value is List) return value.map(canonical).toList();
        if (value is Map) {
          return value.map(
            (key, child) => MapEntry(
              key,
              key == 'name' && child is String && child.startsWith('sites/')
                  ? 'projects/123456789/$child'
                  : canonical(child),
            ),
          );
        }
        return value;
      }

      env.intercept = (r) async {
        final response = env._respond(r);
        return response.body.isEmpty
            ? response
            : _json(canonical(jsonDecode(response.body))!);
      };
      expect((await env.deploy()).host, '$_site.web.app');
      expect(
        (await env.deploy(channelId: _channel)).host,
        '$_site--$_channel-abc123.web.app',
      );
    },
  );

  test(
    'counts unrelated channel IDs with uppercase letters or underscores',
    () async {
      env.addChannel('External_Review', owned: false);
      await env.deploy(channelId: _channel, budget: 2);
      expect(env.deleted, isEmpty);
      expect(env.channels, contains('External_Review'));
    },
  );

  for (final type in [null, 'TYPE_UNSPECIFIED']) {
    test(
      'accepts default release type when the deployed version matches: $type',
      () async {
        env.intercept = (r) async => r.url.path.endsWith('/releases')
            ? _json({
                'version': {'name': _version},
                'type': ?type,
              })
            : null;
        await env.deploy();
      },
    );
  }

  test('bounds metadata requests that never complete', () async {
    env.intercept = (_) => Completer<http.Response?>().future;
    await expectLater(
      FirebaseHostingClient(
        env.client,
        requestTimeout: const Duration(milliseconds: 5),
      ).deploy(siteId: _site, files: env.files.files),
      throwsA(isA<TimeoutException>()),
    );
  });

  test(
    'bounds file uploads and attempts unpublished version cleanup',
    () async {
      env.intercept = (r) => r.url.host.startsWith('upload-')
          ? Completer<http.Response?>().future
          : Future.value(null);
      await expectLater(
        FirebaseHostingClient(
          env.client,
          uploadTimeout: const Duration(milliseconds: 5),
        ).deploy(siteId: _site, files: env.files.files),
        throwsA(isA<TimeoutException>()),
      );
      expect(env.requests.last.method, 'DELETE');
    },
  );

  test(
    'creates a one-hour preview, then reuses its URL and refreshes expiry',
    () async {
      final url = await env.deploy(channelId: _channel);
      expect(await env.deploy(channelId: _channel), url);
      expect(url.toString(), 'https://$_site--$_channel-abc123.web.app');
      final creates = env.requests.where(
        (r) => r.method == 'POST' && r.url.path.endsWith('/channels'),
      );
      expect(creates, hasLength(1));
      expect(creates.single.url.queryParameters, {'channelId': _channel});
      final settings = env.requests.where(
        (r) =>
            r.url.path.contains('/channels') &&
            (r.method == 'PATCH' ||
                r.url.path.endsWith('/channels') && r.method == 'POST'),
      );
      expect(settings, hasLength(4));
      for (final request in settings) {
        expect(jsonDecode(request.body), containsPair('ttl', '3600s'));
        expect(
          jsonDecode(request.body),
          containsPair('retainedReleaseCount', 1),
        );
        expect(jsonDecode(request.body)['labels'], {
          'openci-workflow': 'preview',
        });
      }
      expect(
        env.requests
            .where((r) => r.url.path.endsWith('/releases'))
            .every(
              (r) =>
                  r.url.path ==
                  '/v1beta1/sites/$_site/channels/$_channel/releases',
            ),
        isTrue,
      );
      expect(env.requests.where((r) => r.method == 'DELETE'), isEmpty);
    },
  );

  test(
    'uses the refreshed preview URL if an expired channel is recreated',
    () async {
      env.intercept = (r) async {
        if (r.method == 'PATCH' && r.url.path.contains('/channels/')) {
          return _json({
            ..._channelData(_channel),
            'url': 'https://$_site--$_channel-new123.web.app',
          });
        }
        return null;
      };
      expect(
        (await env.deploy(channelId: _channel)).host,
        '$_site--$_channel-new123.web.app',
      );
    },
  );

  test(
    'deletes expired previews first, then oldest owned channels to fit the budget',
    () async {
      env.addChannel('live');
      env.addChannel('external', owned: false);
      env.addChannel(
        'openci-old',
        updated: _now.subtract(const Duration(minutes: 30)),
      );
      env.addChannel(
        'openci-recent',
        updated: _now.subtract(const Duration(minutes: 5)),
      );
      env.addChannel(
        'openci-expired',
        expires: _now.subtract(const Duration(minutes: 1)),
      );
      await env.deploy(channelId: _channel, budget: 3);
      expect(env.deleted, ['openci-expired', 'openci-old']);
      expect(
        env.channels.keys,
        containsAll(['live', 'external', 'openci-recent', _channel]),
      );
    },
  );

  test(
    'cleans expired managed previews even when the budget has space',
    () async {
      env.addChannel('openci-expired', expires: _now);
      env.addChannel(_channel, expires: _now);
      await env.deploy(channelId: _channel);
      expect(env.deleted, ['openci-expired']);
      expect(env.channels, contains(_channel));
    },
  );

  test(
    'counts all pages and protects live, unlabeled and differently named channels',
    () async {
      env.addChannel('live');
      env.addChannel('openci-unlabeled', owned: false);
      env.addChannel('foreign-labelled');
      env.addChannel('openci-old');
      env.intercept = (r) async {
        if (r.method == 'GET' && r.url.path.endsWith('/channels')) {
          if (!r.url.queryParameters.containsKey('pageToken')) {
            return _json({
              'channels': [env.channels['live'], env.channels['openci-old']],
              'nextPageToken': 'page-2',
            });
          }
          expect(r.url.queryParameters['pageToken'], 'page-2');
          return _json({
            'channels': [
              env.channels['openci-unlabeled'],
              env.channels['foreign-labelled'],
            ],
          });
        }
        return null;
      };
      await env.deploy(channelId: _channel, budget: 3);
      expect(env.deleted, ['openci-old']);
      expect(
        env.channels.keys,
        containsAll(['live', 'openci-unlabeled', 'foreign-labelled']),
      );
    },
  );

  test(
    'fails before deletions when unrelated channels occupy the entire budget',
    () async {
      env.addChannel('external-1', owned: false);
      env.addChannel('external-2', owned: false);
      env.addChannel('openci-expired', expires: _now);
      await expectLater(
        env.deploy(channelId: _channel, budget: 2),
        throwsStateError,
      );
      expect(env.requests.map((r) => r.method), ['GET']);
    },
  );

  test('refuses to take ownership of a colliding channel', () async {
    env.addChannel(_channel, owned: false);
    await expectLater(env.deploy(channelId: _channel), throwsStateError);
    expect(env.requests.map((r) => r.method), ['GET']);
  });

  for (final owned in [false, true]) {
    test(
      'handles create conflict without taking over unowned channels: $owned',
      () async {
        env.intercept = (r) async {
          if (r.method == 'POST' && r.url.path.endsWith('/channels')) {
            env.addChannel(_channel, owned: owned);
            return _json({'private': 'private-response'}, 409);
          }
          return null;
        };
        if (owned) {
          await env.deploy(channelId: _channel);
        } else {
          await expectLater(env.deploy(channelId: _channel), throwsStateError);
          expect(env.requests.where((r) => r.method == 'PATCH'), isEmpty);
        }
      },
    );
  }

  for (final status in [404, 403]) {
    test(
      'cleanup handles concurrent deletion and stops on permission errors: $status',
      () async {
        env.addChannel('openci-expired', expires: _now);
        env.intercept = (r) async => r.method == 'DELETE'
            ? _json({'secret': 'private-response'}, status)
            : null;
        if (status == 404) {
          await env.deploy(channelId: _channel);
        } else {
          await expectLater(
            env.deploy(channelId: _channel),
            throwsA(isA<HttpException>()),
          );
          expect(env.requests.where((r) => r.method == 'POST'), isEmpty);
        }
      },
    );
  }

  for (final phase in ['create', 'populate', 'upload', 'finalize', 'release']) {
    test(
      'redacts HTTP failures during $phase and cleans only unpublished versions',
      () async {
        env.intercept = (r) async {
          final fails = switch (phase) {
            'create' => r.url.path.endsWith('/versions') && r.method == 'POST',
            'populate' => r.url.path.endsWith(':populateFiles'),
            'upload' => r.url.host.startsWith('upload-'),
            'finalize' => r.method == 'PATCH',
            _ => r.url.path.endsWith('/releases'),
          };
          return fails ? _json({'error': 'private-response'}, 403) : null;
        };
        await expectLater(
          env.deploy(),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              allOf(contains('403'), isNot(contains('private-response'))),
            ),
          ),
        );
        expect(
          env.requests.where((r) => r.method == 'DELETE'),
          hasLength(phase == 'create' || phase == 'release' ? 0 : 1),
        );
        if (phase != 'release') {
          expect(
            env.requests.where((r) => r.url.path.endsWith('/releases')),
            isEmpty,
          );
        }
      },
    );
  }

  for (final url in [
    'https://attacker.example/upload',
    'https://upload-firebasehosting.googleapis.com.attacker.example/upload',
    'https://upload-firebasehosting.googleapis.com/upload/sites/other/versions/v/files',
    'https://user@upload-firebasehosting.googleapis.com/upload/$_version/files',
  ]) {
    test('rejects an untrusted upload destination: $url', () async {
      env.intercept = (r) async => r.url.path.endsWith(':populateFiles')
          ? _json({
              'uploadRequiredHashes': [env.files.files.first.hash],
              'uploadUrl': url,
            })
          : null;
      await expectLater(env.deploy(), throwsStateError);
      expect(
        env.requests.every(
          (r) => r.url.host == 'firebasehosting.googleapis.com',
        ),
        isTrue,
      );
    });
  }

  test('rejects unknown upload hashes before sending content', () async {
    env.intercept = (r) async => r.url.path.endsWith(':populateFiles')
        ? _json({
            'uploadRequiredHashes': ['unknown-secret'],
          })
        : null;
    await expectLater(env.deploy(), throwsStateError);
    expect(
      env.requests.where((r) => r.url.host.startsWith('upload-')),
      isEmpty,
    );
  });

  for (final response in [
    'private-response',
    '[]',
    '{"name":"sites/other/versions/v"}',
  ]) {
    test(
      'rejects malformed JSON and cross-site resources without leaking responses',
      () async {
        env.intercept = (_) async => http.Response(response, 200);
        await expectLater(
          env.deploy(),
          throwsA(
            isA<StateError>().having(
              (e) => e.toString(),
              'message',
              isNot(contains('private-response')),
            ),
          ),
        );
        expect(env.requests, hasLength(1));
      },
    );
  }

  test('requires a finalized version before releasing', () async {
    env.intercept = (r) async => r.method == 'PATCH'
        ? _json({'name': _version, 'status': 'CREATED'})
        : null;
    await expectLater(env.deploy(), throwsStateError);
    expect(env.requests.last.method, 'DELETE');
    expect(
      env.requests.where((r) => r.url.path.endsWith('/releases')),
      isEmpty,
    );
  });

  test(
    'rejects an invalid release without deleting a possibly published version',
    () async {
      env.intercept = (r) async =>
          r.url.path.endsWith('/releases') ? _json({}) : null;
      await expectLater(env.deploy(), throwsStateError);
      expect(env.requests.where((r) => r.method == 'DELETE'), isEmpty);
    },
  );

  test(
    'bounds pagination and does not delete before all pages are validated',
    () async {
      env.intercept = (_) async => _json({
        'channels': [_channelData('openci-old')],
        'nextPageToken': 'repeated',
      });
      await expectLater(env.deploy(channelId: _channel), throwsStateError);
      expect(env.requests.map((r) => r.method), ['GET', 'GET']);
    },
  );

  for (final error in [
    http.ClientException('private-token'),
    TimeoutException('private-token'),
  ]) {
    test('sanitizes transport errors: ${error.runtimeType}', () async {
      env.intercept = (_) async => throw error;
      await expectLater(
        env.deploy(),
        throwsA(
          predicate<Object>(
            (e) => !e.toString().contains('private-token'),
          ),
        ),
      );
    });
  }

  test(
    'does not delete the version after an ambiguous release timeout',
    () async {
      env.intercept = (r) async {
        if (r.url.path.endsWith('/releases')) {
          throw TimeoutException('private-token');
        }
        return null;
      };
      await expectLater(env.deploy(), throwsA(isA<TimeoutException>()));
      expect(env.requests.where((r) => r.method == 'DELETE'), isEmpty);
    },
  );
}

class _Environment {
  _Environment(this.root, this.content, this.files) {
    client = MockClient((r) async {
      requests.add(r);
      return await intercept?.call(r) ?? _respond(r);
    });
  }

  final Directory root;
  final Directory content;
  final HostingFiles files;
  final requests = <http.Request>[];
  final channels = <String, Map<String, Object?>>{};
  late MockClient client;
  Future<http.Response?> Function(http.Request)? intercept;

  static Future<_Environment> create() async {
    final root = await Directory.systemTemp.createTemp('openci-hosting-test-');
    final content = await Directory('${root.path}/public').create();
    await File('${content.path}/index.html').writeAsString('<html>日本語</html>');
    await File('${content.path}/copy.html').writeAsString('<html>日本語</html>');
    await Directory('${content.path}/assets').create();
    await File(
      '${content.path}/assets/日本語.bin',
    ).writeAsBytes(List.generate(256, (i) => i));
    return _Environment(root, content, await HostingFiles.prepare(content));
  }

  void addChannel(
    String id, {
    bool owned = true,
    DateTime? updated,
    DateTime? expires,
  }) {
    channels[id] = _channelData(
      id,
      owned: owned,
      updated: updated,
      expires: expires,
    );
  }

  List<String> get deleted => requests
      .where((r) => r.method == 'DELETE' && r.url.path.contains('/channels/'))
      .map((r) => r.url.pathSegments.last)
      .toList();

  Future<Uri> deploy({
    String? channelId,
    int budget = 20,
    List<HostingFile>? files,
    Map<String, Object?> config = const {},
  }) => FirebaseHostingClient(client, now: () => _now).deploy(
    siteId: _site,
    files: files ?? this.files.files,
    config: config,
    channelId: channelId,
    maxPreviewChannels: budget,
  );

  http.Response _respond(http.Request r) {
    if (r.url.host.startsWith('upload-')) return http.Response('', 200);
    final path = r.url.path;
    if (r.method == 'DELETE') {
      if (path.contains('/channels/')) channels.remove(r.url.pathSegments.last);
      return http.Response('', 200);
    }
    if (r.method == 'GET' && path.endsWith('/channels')) {
      return _json({'channels': channels.values.toList()});
    }
    if (r.method == 'GET' && path.contains('/channels/')) {
      return _json(channels[r.url.pathSegments.last]!);
    }
    if (r.method == 'POST' && path.endsWith('/channels')) {
      final id = r.url.queryParameters['channelId']!;
      channels[id] = {
        ..._channelData(id),
        ...jsonDecode(r.body) as Map<String, dynamic>,
      };
      return _json(channels[id]!);
    }
    if (r.method == 'PATCH' && path.contains('/channels/')) {
      final id = r.url.pathSegments.last;
      channels[id] = {
        ...channels[id]!,
        ...jsonDecode(r.body) as Map<String, dynamic>,
      };
      return _json(channels[id]!);
    }
    if (r.method == 'POST' && path.endsWith('/versions')) {
      return _json({'name': _version});
    }
    if (path.endsWith(':populateFiles')) {
      return _json({
        'uploadRequiredHashes': (jsonDecode(r.body)['files'] as Map).values
            .toSet()
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
    throw StateError('Unexpected test request: ${r.method} ${r.url}');
  }

  Future<void> close() async {
    client.close();
    await files.close();
    await root.delete(recursive: true);
  }
}
