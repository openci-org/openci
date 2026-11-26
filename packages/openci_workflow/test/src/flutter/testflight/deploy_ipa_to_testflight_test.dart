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
const _appDeclarations = '/v1/appEncryptionDeclarations';
const _appDescription = 'A sports coaching app.';
late AppStoreConnectKeys _keys;
late ECPublicKey _publicKey;

bool _listsDeclarations(http.Request request) =>
    request.method == 'GET' && request.url.path == _appDeclarations;

bool _createsDeclaration(http.Request request) =>
    request.method == 'POST' && request.url.path == _appDeclarations;

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

Map<String, Object> _build({
  bool? usesNonExemptEncryption,
  String? declarationId,
}) => {
  'type': 'builds',
  'id': 'build-42',
  'attributes': {'usesNonExemptEncryption': usesNonExemptEncryption},
  'relationships': {
    'app': {
      'data': {'type': 'apps', 'id': '1234567890'},
    },
    'appEncryptionDeclaration': {
      'data': declarationId == null
          ? null
          : {'type': 'appEncryptionDeclarations', 'id': declarationId},
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

    group('standard encryption', () {
      Map<String, Object> declaration({
        String id = 'declaration-1',
        required bool france,
        bool exempt = false,
        String state = 'APPROVED',
        bool proprietary = false,
      }) => {
        'type': 'appEncryptionDeclarations',
        'id': id,
        'attributes': {
          'appDescription': _appDescription,
          'containsProprietaryCryptography': proprietary,
          'containsThirdPartyCryptography': true,
          'availableOnFrenchStore': france,
          'exempt': exempt,
          'appEncryptionDeclarationState': state,
        },
      };

      TestFlightExportCompliance compliance(bool france) =>
          TestFlightExportCompliance.standardEncryption(
            appDescription: _appDescription,
            availableOnFrenchStore: france,
          );

      Future<void> deploy(bool france) =>
          environment.deploy(exportCompliance: compliance(france));
      Future<void> apply(bool france, {String buildId = 'build-42'}) =>
          environment.withClient(
            () => environment.flutter.applyTestFlightExportCompliance(
              buildId: buildId,
              ascKeys: _keys,
              exportCompliance: compliance(france),
            ),
          );

      test('reports Apple errors and stops after a failed lookup', () async {
        environment.intercept = (req) async {
          if (!_listsDeclarations(req)) return null;
          return _json({
            'errors': [
              {
                'status': '404',
                'code': 'PATH_ERROR',
                'title': 'The URL path is not valid',
                'detail':
                    "The relationship 'appEncryptionDeclarations' does not exist",
                'meta': {'debug': 'private-metadata'},
              },
              {
                'code': 'PARAMETER_ERROR.INVALID',
                'detail': 'Check the specified field.',
              },
            ],
          }, 404);
        };
        await expectLater(
          apply(false),
          throwsA(
            isA<AppStoreConnectHttpException>()
                .having((e) => e.statusCode, 'HTTP status', 404)
                .having(
                  (e) => e.message,
                  'message',
                  'App Store Connect find app encryption declaration failed (HTTP 404). '
                      '[PATH_ERROR] The URL path is not valid '
                      "The relationship 'appEncryptionDeclarations' does not exist"
                      ' | [PARAMETER_ERROR.INVALID] Check the specified field.',
                ),
          ),
        );
        expect(environment.requests.map((r) => r.method), ['GET', 'GET']);
      });

      for (final (france, exempt) in [
        (true, false),
        (true, true),
        (false, true),
        (false, false),
      ]) {
        test(
          'submits France=$france and uses Apple’s exemption=$exempt',
          () async {
            await environment.createIpa();
            environment.intercept = (req) async {
              if (_listsDeclarations(req)) return _json({'data': []});
              if (_createsDeclaration(req)) {
                expect(jsonDecode(req.body)['data'], {
                  'type': 'appEncryptionDeclarations',
                  'attributes': {
                    'appDescription': _appDescription,
                    'containsProprietaryCryptography': false,
                    'containsThirdPartyCryptography': true,
                    'availableOnFrenchStore': france,
                  },
                  'relationships': {
                    'app': {
                      'data': {'type': 'apps', 'id': '1234567890'},
                    },
                  },
                });
                return _json({
                  'data': declaration(
                    france: france,
                    exempt: exempt,
                    state: exempt ? 'CREATED' : 'APPROVED',
                  ),
                }, 201);
              }
              if (req.method == 'PATCH' &&
                  req.url.path == '/v1/builds/build-42') {
                final data = jsonDecode(req.body)['data'];
                expect(data, {
                  'type': 'builds',
                  'id': 'build-42',
                  'attributes': {'usesNonExemptEncryption': !exempt},
                  if (!exempt)
                    'relationships': {
                      'appEncryptionDeclaration': {
                        'data': {
                          'type': 'appEncryptionDeclarations',
                          'id': 'declaration-1',
                        },
                      },
                    },
                });
                return _json({'data': data});
              }
              return null;
            };
            await deploy(france);
            expect(environment.requests.last.url.path, '/v1/builds/build-42');
            expect(
              environment.requests.where(_createsDeclaration),
              hasLength(1),
            );
          },
        );
      }

      test('reuses only a matching approved declaration across pages', () async {
        await environment.createIpa();
        environment.intercept = (req) async {
          if (_listsDeclarations(req)) {
            expect(req.url.queryParameters['filter[app]'], '1234567890');
            if (req.url.queryParameters['cursor'] == 'next') {
              return _json({
                'data': [declaration(france: true, id: 'reusable')],
              });
            }
            return _json({
              'data': [
                declaration(france: false),
                declaration(france: true, proprietary: true),
                declaration(france: true, state: 'IN_REVIEW'),
              ],
              'links': {
                'next':
                    'https://api.appstoreconnect.apple.com$_appDeclarations?cursor=next&filter%5Bapp%5D=other-app',
              },
            });
          }
          if (req.method == 'PATCH' && req.url.path == '/v1/builds/build-42') {
            final data = jsonDecode(req.body)['data'];
            expect(
              data['relationships']['appEncryptionDeclaration']['data']['id'],
              'reusable',
            );
            return _json({'data': data});
          }
          return null;
        };
        await deploy(true);
        expect(environment.requests.where(_createsDeclaration), isEmpty);
      });

      for (final state in ['CREATED', 'IN_REVIEW', 'REJECTED', 'INVALID']) {
        test(
          'a $state declaration keeps the uploaded build available for a retry',
          () async {
            await environment.createIpa();
            var created = false;
            final item = declaration(france: true, state: state);
            environment.intercept = (req) async {
              if (_listsDeclarations(req)) {
                return _json({
                  'data': [if (created) item],
                });
              }
              if (_createsDeclaration(req)) {
                created = true;
                return _json({'data': item}, 201);
              }
              return null;
            };
            for (final attempt in [deploy, apply]) {
              await expectLater(
                attempt(true),
                throwsA(
                  isA<StateError>().having(
                    (e) => e.message,
                    'message',
                    allOf(
                      contains('declaration-1'),
                      contains(state),
                      contains('build-42'),
                    ),
                  ),
                ),
              );
            }
            expect(
              environment.requests.where(_createsDeclaration),
              hasLength(1),
            );
            expect(
              environment.requests.where(
                (r) => r.url.path == '/v1/buildUploads',
              ),
              hasLength(1),
            );
            expect(
              environment.requests.where(
                (r) =>
                    r.method == 'PATCH' && r.url.path == '/v1/builds/build-42',
              ),
              isEmpty,
            );
          },
        );
      }

      test(
        'recovers a concurrently created declaration after a conflict',
        () async {
          await environment.createIpa();
          var conflict = false;
          environment.intercept = (req) async {
            if (_listsDeclarations(req)) {
              return _json({
                'data': [
                  if (conflict) declaration(france: false, exempt: true),
                ],
              });
            }
            if (_createsDeclaration(req)) {
              conflict = true;
              return _json({}, 409);
            }
            if (req.method == 'PATCH' &&
                req.url.path == '/v1/builds/build-42') {
              return _json(jsonDecode(req.body));
            }
            return null;
          };
          await deploy(false);
          expect(environment.requests.last.url.path, '/v1/builds/build-42');
        },
      );

      test('requires a description before contacting Apple', () async {
        await expectLater(
          environment.deploy(
            exportCompliance:
                const TestFlightExportCompliance.standardEncryption(
                  appDescription: ' ',
                  availableOnFrenchStore: false,
                ),
          ),
          throwsArgumentError,
        );
        expect(environment.requests, isEmpty);
      });

      test(
        'retries after approval and skips a second update of the same build',
        () async {
          var approved = false;
          var linked = false;
          environment.intercept = (req) async {
            if (_listsDeclarations(req)) {
              return _json({
                'data': [
                  declaration(
                    france: true,
                    state: approved ? 'APPROVED' : 'IN_REVIEW',
                  ),
                ],
              });
            }
            if (req.url.path == '/v1/builds/build-42') {
              if (req.method == 'PATCH') {
                linked = true;
                return _json(jsonDecode(req.body));
              }
              if (linked) {
                return _json({
                  'data': _build(
                    usesNonExemptEncryption: true,
                    declarationId: 'declaration-1',
                  ),
                });
              }
            }
            return null;
          };
          await expectLater(apply(true), throwsStateError);
          approved = true;
          await apply(true);
          await apply(true);
          expect(
            environment.requests
                .where((r) => r.method != 'GET')
                .map((r) => r.method),
            ['PATCH'],
          );
          expect(environment.commands, isEmpty);
        },
      );

      for (final matches in [true, false]) {
        test(
          'confirms a links-only build response against its declaration (matches: $matches)',
          () async {
            const relationship =
                '/v1/builds/build-42/relationships/appEncryptionDeclaration';
            environment.intercept = (req) async {
              if (_listsDeclarations(req)) {
                return _json({
                  'data': [declaration(france: false)],
                });
              }
              if (req.method == 'PATCH' &&
                  req.url.path == '/v1/builds/build-42') {
                return _json({
                  'data': {
                    'type': 'builds',
                    'id': 'build-42',
                    'attributes': {'usesNonExemptEncryption': true},
                    'relationships': {
                      'appEncryptionDeclaration': {
                        'links': {'self': relationship},
                      },
                    },
                  },
                });
              }
              if (req.url.path == relationship) {
                return _json({
                  'data': {
                    'type': 'appEncryptionDeclarations',
                    'id': matches ? 'declaration-1' : 'different',
                  },
                });
              }
              return null;
            };
            if (matches) {
              await apply(false);
            } else {
              await expectLater(apply(false), throwsStateError);
            }
            expect(environment.requests.last.url.path, relationship);
          },
        );
      }

      test(
        'requires a valid build ID before sending a compliance-only request',
        () async {
          await expectLater(
            apply(false, buildId: '../builds/42'),
            throwsArgumentError,
          );
          expect(environment.requests, isEmpty);
        },
      );

      test(
        'links the selected France answer when the build has a different declaration',
        () async {
          environment.intercept = (req) async {
            if (_listsDeclarations(req)) {
              return _json({
                'data': [
                  declaration(france: false, id: 'france-no'),
                  declaration(france: true, id: 'france-yes'),
                ],
              });
            }
            if (req.url.path == '/v1/builds/build-42') {
              if (req.method == 'PATCH') {
                final data = jsonDecode(req.body)['data'];
                expect(data.containsKey('attributes'), isFalse);
                expect(
                  data['relationships']['appEncryptionDeclaration']['data']['id'],
                  'france-yes',
                );
                return _json({
                  'data': _build(
                    usesNonExemptEncryption: true,
                    declarationId: 'france-yes',
                  ),
                });
              }
              return _json({
                'data': _build(
                  usesNonExemptEncryption: true,
                  declarationId: 'france-no',
                ),
              });
            }
            return null;
          };
          await apply(true);
          expect(environment.requests.last.method, 'PATCH');
        },
      );
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

    test('waits for the processed build linked to this upload', () async {
      environment.intercept = (request) async {
        expect(request.url.path, '/v1/buildUploads/$_uploadId');
        expect(request.url.queryParameters['include'], 'build');
        if (environment.requests.length == 1) {
          return _json({
            ..._upload('COMPLETE'),
            'included': [
              {'type': 'builds', 'id': 'unrelated'},
            ],
          });
        }
        return null;
      };
      expect(await environment.poll(includeBuild: true), 'build-42');
      expect(environment.requests, hasLength(2));
    });

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

    test('redacts credentials echoed in structured Apple errors', () async {
      environment.intercept = (request) async {
        final jwt = request.headers['authorization']!.substring(
          'Bearer '.length,
        );
        return _json({
          'errors': [
            {
              'code': 'FORBIDDEN_ERROR',
              'title': 'Token: $jwt\r\nCheck the key.',
              'detail':
                  'Bearer private-access-token ${_keys.keyId} '
                  '${_keys.issuerId} ${_keys.privateKeyBase64} '
                  'https://uploads.example.com/part?signature=private-signature',
            },
          ],
        }, 403);
      };
      await expectLater(
        environment.poll(),
        throwsA(
          isA<AppStoreConnectHttpException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('[FORBIDDEN_ERROR] Token: [REDACTED] Check the key.'),
              isNot(contains('private-access-token')),
              isNot(contains('private-signature')),
              isNot(contains(_keys.privateKeyBase64)),
              isNot(contains(_keys.issuerId)),
              isNot(contains(_keys.keyId)),
            ),
          ),
        ),
      );
    });

    for (final response in [
      http.Response('<html>private-response</html>', 502),
      http.Response.bytes([0xff], 502),
    ]) {
      test(
        'keeps the HTTP status for an unreadable ${response.bodyBytes.length}-byte response',
        () async {
          environment.intercept = (_) async => response;
          await expectLater(
            environment.poll(),
            throwsA(
              isA<AppStoreConnectHttpException>()
                  .having((e) => e.statusCode, 'HTTP status', 502)
                  .having((e) => e.message, 'message', endsWith('(HTTP 502).')),
            ),
          );
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
                    {
                      if (method == 'PUT') 'code': 'STORAGE_ERROR',
                      'detail': 'private-response',
                    },
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
                  isNot(contains('STORAGE_ERROR')),
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

  FlutterCI get flutter => OpenCI(
    workflowName: 'test',
    ciTriggers: const [CITrigger.push(branch: 'test')],
    workspacePath: workspace.path,
    currentWorkingDirectory: 'apps/mobile',
    commandRunner: (command, {required workingDirectory}) async {
      commands.add(command);
      workingDirectories.add(workingDirectory);
      await _run('/bin/sh', ['-c', command], cwd: workingDirectory);
    },
  ).flutter;

  Future<void> deploy({
    String ipaPath = 'app.ipa',
    AppStoreConnectKeys? keys,
    TestFlightExportCompliance? exportCompliance,
    String? dir,
    Duration timeout = const Duration(minutes: 30),
  }) => withClient(
    () => flutter.deployIpaToTestFlight(
      ipaPath: ipaPath,
      ascKeys: keys ?? _keys,
      exportCompliance: exportCompliance,
      dir: dir,
      processingTimeout: timeout,
    ),
  );

  Future<String?> poll({
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = Duration.zero,
    bool includeBuild = false,
  }) => withClient(() async {
    final client = AppStoreConnectClient(_keys);
    try {
      return await waitForTestFlightProcessing(
        client,
        _uploadId,
        timeout: timeout,
        pollInterval: pollInterval,
        includeBuild: includeBuild,
      );
    } finally {
      client.close();
    }
  });

  Future<T> withClient<T>(Future<T> Function() action) => http.runWithClient(
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
    if (request.method == 'GET' && request.url.path == '/v1/builds/build-42') {
      expect(
        request.url.queryParameters['include'],
        'app,appEncryptionDeclaration',
      );
      return _json({'data': _build()});
    }
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
      if (request.url.queryParameters['include'] == 'build') {
        final upload = _upload('COMPLETE');
        (upload['data'] as Map)['relationships'] = {
          'build': {
            'data': {'type': 'builds', 'id': 'build-42'},
          },
        };
        return _json(upload);
      }
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
