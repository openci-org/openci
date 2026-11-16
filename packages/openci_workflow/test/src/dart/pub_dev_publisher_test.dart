import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflow/src/dart/pub_dev_publisher.dart';
import 'package:openci_workflow/src/dart/pub_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _email = 'publisher@example.iam.gserviceaccount.com';
const _token = 'test.identity.token';

void main() {
  late String privateKey;
  late String credentials;
  late Directory workspace;
  late Directory package;
  late List<http.Request> requests;
  late List<List<String>> commands;
  late Map<String, String>? childEnvironment;
  late Future<http.Response> Function(http.Request) respond;
  late PubProcessRunner runner;

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status);
  http.Response existing() => json({
    'version': '1.2.3',
    'pubspec': {'name': 'example_package', 'version': '1.2.3'},
  });
  Future<void> pubspec(String content) =>
      File(p.join(package.path, 'pubspec.yaml')).writeAsString(content);

  setUpAll(() async {
    // Ephemeral key used only with mock Google responses, never a real account.
    final generated = await Process.run('openssl', [
      'genpkey',
      '-algorithm',
      'RSA',
      '-pkeyopt',
      'rsa_keygen_bits:2048',
    ]);
    expect(generated.exitCode, 0);
    privateKey = generated.stdout as String;
    credentials = base64Encode(
      utf8.encode(
        jsonEncode({
          'type': 'service_account',
          'client_email': _email,
          'private_key': privateKey,
          'token_uri': 'https://oauth2.googleapis.com/token',
        }),
      ),
    );
  });

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('openci-publish-test-');
    package = await Directory(
      p.join(workspace.path, "a package's directory"),
    ).create();
    await pubspec('name: example_package\nversion: 1.2.3\n');
    requests = [];
    commands = [];
    childEnvironment = null;
    respond = (request) async => request.method == 'GET'
        ? http.Response('', 404)
        : json({'id_token': _token});
    runner =
        (
          executable,
          arguments, {
          required workingDirectory,
          required environment,
          required secrets,
          required timeout,
        }) async {
          expect(executable, 'dart');
          expect(workingDirectory, await package.resolveSymbolicLinks());
          expect(timeout, const Duration(minutes: 10));
          expect(secrets, containsAll([_token, credentials]));
          commands.add(arguments);
          childEnvironment = environment;
          expect(await Directory(environment['HOME']!).exists(), isTrue);
          return 0;
        };
  });

  tearDown(() async {
    if (childEnvironment != null) {
      expect(
        await Directory(childEnvironment!['HOME']!).exists(),
        isFalse,
        reason: 'Temporary auth files must be removed on every exit path.',
      );
    }
    await workspace.delete(recursive: true);
  });

  Future<PubPublishResult> publish({
    bool skip = false,
    String? key,
    Duration requestTimeout = const Duration(seconds: 60),
  }) =>
      PubDevPublisher(
        client: MockClient((request) async {
          requests.add(request);
          expect(request.followRedirects, isFalse);
          return respond(request);
        }),
        runProcess: runner,
        requestTimeout: requestTimeout,
      ).publish(
        workingDirectory: package.path,
        serviceAccountJsonBase64: key ?? credentials,
        skipIfPublished: skip,
      );

  test(
    'publishes once with Google ID token and no additional validation command',
    () async {
      final result = await publish();
      expect(result.name, 'example_package');
      expect(result.version, '1.2.3');
      expect(result.status, PubPublishStatus.published);
      expect(
        result.url.toString(),
        'https://pub.dev/packages/example_package/versions/1.2.3',
      );
      expect(commands, [
        [
          'pub',
          'token',
          'add',
          'https://pub.dev',
          '--env-var',
          'OPENCI_PUB_DEV_ID_TOKEN',
        ],
        ['pub', 'publish', '--force'],
      ]);
      expect(
        requests.first.url.toString(),
        'https://pub.dev/api/packages/example_package/versions/1.2.3',
      );
      expect(requests.first.headers, isNot(contains('authorization')));
      final auth = requests.last;
      expect(auth.url.toString(), 'https://oauth2.googleapis.com/token');
      expect(
        auth.bodyFields['grant_type'],
        'urn:ietf:params:oauth:grant-type:jwt-bearer',
      );
      final jwt = JWT.decode(auth.bodyFields['assertion']!);
      expect(jwt.header?['alg'], 'RS256');
      expect(jwt.payload['iss'], _email);
      expect(jwt.payload['aud'], 'https://oauth2.googleapis.com/token');
      expect(jwt.payload['target_audience'], 'https://pub.dev');
      expect(jwt.payload['exp'] - jwt.payload['iat'], 300);
      expect(jwt.payload, isNot(contains('scope')));
      final environment = childEnvironment!;
      expect(environment['OPENCI_PUB_DEV_ID_TOKEN'], _token);
      expect(environment['PUB_HOSTED_URL'], 'https://pub.dev');
      expect(environment['HOME'], isNot(Platform.environment['HOME']));
      expect(environment['PUB_CACHE'], isNot(startsWith(environment['HOME']!)));
      expect(environment['APPDATA'], environment['HOME']);
      expect(environment['XDG_CONFIG_HOME'], environment['HOME']);
      expect(jsonEncode(commands), isNot(contains(_token)));
      expect(jsonEncode(environment), isNot(contains(credentials)));
      expect(jsonEncode(environment), isNot(contains(privateKey)));
    },
  );

  test('skips an existing version before authenticating', () async {
    respond = (_) async => existing();
    final result = await publish(skip: true, key: 'not needed');
    expect(result.status, PubPublishStatus.alreadyPublished);
    expect(requests, hasLength(1));
    expect(commands, isEmpty);
  });

  test('rejects an existing version by default', () async {
    respond = (_) async => existing();
    await expectLater(
      publish(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already published'),
        ),
      ),
    );
    expect(commands, isEmpty);
  });

  for (final status in [301, 401, 429, 500]) {
    test(
      'lookup HTTP $status never means absent or already published',
      () async {
        respond = (_) async => http.Response('sensitive response', status);
        await expectLater(publish(skip: true), throwsA(isA<HttpException>()));
        expect(commands, isEmpty);
        expect(requests, hasLength(1));
      },
    );
  }

  for (final body in [
    'not json',
    '{}',
    '{"version":"1.2.3","pubspec":{"name":"other","version":"1.2.3"}}',
    '{"version":"1.2.4","pubspec":{"name":"example_package","version":"1.2.4"}}',
  ]) {
    test('rejects malformed or mismatched version metadata: $body', () async {
      respond = (_) async => http.Response(body, 200);
      await expectLater(publish(skip: true), throwsA(isA<StateError>()));
      expect(commands, isEmpty);
    });
  }

  test('bounds lookup time without starting a process', () async {
    respond = (_) => Completer<http.Response>().future;
    await expectLater(
      publish(requestTimeout: const Duration(milliseconds: 10)),
      throwsA(isA<TimeoutException>()),
    );
    expect(commands, isEmpty);
  });

  for (final content in [
    'name: example_package\nversion: 1.2.3\npublish_to: none\n',
    'name: example_package\nversion: 1.2.3\npublish_to: https://example.com\n',
    'name: example_package\nversion: 1.2.3\npublish_to: [https://pub.dev]\n',
    'name: ../escape\nversion: 1.2.3\n',
    'name: example_package\nversion: 1\n',
    'name: example_package\nversion: invalid\n',
    'name: example_package\n',
    '[not, a, pubspec]',
  ]) {
    test(
      'rejects invalid package metadata before any request: $content',
      () async {
        await pubspec(content);
        await expectLater(publish(), throwsA(isA<FormatException>()));
        expect(requests, isEmpty);
        expect(commands, isEmpty);
      },
    );
  }

  test('reads quoted YAML and accepts an explicit pub.dev destination', () async {
    await pubspec(
      'name: "example_package" # comment\nversion: "1.2.3"\npublish_to: https://pub.dev/\n',
    );
    expect((await publish()).status, PubPublishStatus.published);
  });

  test('missing and invalid YAML fail before network access', () async {
    await File(p.join(package.path, 'pubspec.yaml')).delete();
    await expectLater(publish(), throwsA(isA<StateError>()));
    await pubspec('name: [');
    await expectLater(publish(), throwsA(isA<StateError>()));
    expect(requests, isEmpty);
  });

  for (final key in ['not base64!', base64Encode(utf8.encode('{}'))]) {
    test('malformed credentials produce a safe error', () async {
      await expectLater(
        publish(key: key),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Expected a Base64-encoded Google service account JSON key.',
          ),
        ),
      );
      expect(commands, isEmpty);
      expect(requests, hasLength(1));
    });
  }

  test('does not send credentials to a supplied token endpoint', () async {
    final data =
        jsonDecode(utf8.decode(base64Decode(credentials)))
            as Map<String, dynamic>;
    data['token_uri'] = 'https://example.com/steal';
    await expectLater(
      publish(key: base64Encode(utf8.encode(jsonEncode(data)))),
      throwsA(isA<FormatException>()),
    );
    expect(requests, hasLength(1));
  });

  for (final status in [302, 400, 403, 500]) {
    test('Google HTTP $status stops before token registration', () async {
      respond = (r) async => r.method == 'GET'
          ? http.Response('', 404)
          : http.Response(credentials, status);
      await expectLater(
        publish(),
        throwsA(
          isA<HttpException>().having(
            (e) => e.message,
            'message',
            isNot(contains(credentials)),
          ),
        ),
      );
      expect(commands, isEmpty);
    });
  }

  for (final response in [
    {},
    {'access_token': _token},
    {'id_token': ''},
    {'id_token': 'bad\ntoken'},
  ]) {
    test(
      'requires a valid ID token, not an OAuth access token: $response',
      () async {
        respond = (r) async =>
            r.method == 'GET' ? http.Response('', 404) : json(response);
        await expectLater(publish(), throwsA(isA<StateError>()));
        expect(commands, isEmpty);
      },
    );
  }

  for (final failAt in ['token', 'publish']) {
    test(
      'cleans credentials on $failAt failure and never retries publishing',
      () async {
        final normal = runner;
        runner =
            (
              exe,
              args, {
              required workingDirectory,
              required environment,
              required secrets,
              required timeout,
            }) async {
              await normal(
                exe,
                args,
                workingDirectory: workingDirectory,
                environment: environment,
                secrets: secrets,
                timeout: timeout,
              );
              return args[1] == failAt ? 65 : 0;
            };
        await expectLater(publish(skip: true), throwsA(isA<StateError>()));
        expect(
          commands.where((args) => args[1] == 'publish'),
          hasLength(failAt == 'publish' ? 1 : 0),
        );
      },
    );
  }

  test('cleans credentials when publishing times out', () async {
    final normal = runner;
    runner =
        (
          exe,
          args, {
          required workingDirectory,
          required environment,
          required secrets,
          required timeout,
        }) async {
          await normal(
            exe,
            args,
            workingDirectory: workingDirectory,
            environment: environment,
            secrets: secrets,
            timeout: timeout,
          );
          if (args[1] == 'publish') {
            throw TimeoutException('Upload status unknown.');
          }
          return 0;
        };
    await expectLater(publish(), throwsA(isA<TimeoutException>()));
    expect(commands, hasLength(2));
  });

  test(
    'pub registers the token reference only in the temporary configuration',
    () async {
      final normal = runner;
      runner =
          (
            exe,
            args, {
            required workingDirectory,
            required environment,
            required secrets,
            required timeout,
          }) async {
            await normal(
              exe,
              args,
              workingDirectory: workingDirectory,
              environment: environment,
              secrets: secrets,
              timeout: timeout,
            );
            if (args[1] == 'publish') return 0; // Never perform a real upload.
            final code = await runPubProcess(
              Platform.resolvedExecutable,
              args,
              workingDirectory: workingDirectory,
              environment: environment,
              secrets: secrets,
              timeout: timeout,
            );
            final files = await Directory(environment['HOME']!)
                .list(recursive: true)
                .where(
                  (entry) =>
                      entry is File && entry.path.endsWith('pub-tokens.json'),
                )
                .cast<File>()
                .toList();
            expect(files, hasLength(1));
            final text = await files.single.readAsString();
            expect(text, contains('OPENCI_PUB_DEV_ID_TOKEN'));
            expect(text, isNot(contains(_token)));
            expect(text, isNot(contains(credentials)));
            return code;
          };
      await publish();
    },
  );

  test('OpenCI inherits and overrides its package working directory', () async {
    final ci = OpenCI(
      workflowName: 'publish',
      ciTriggers: const [],
      workspacePath: workspace.path,
      currentWorkingDirectory: p.basename(package.path),
    );
    await pubspec('name: example_package\nversion: 1.2.3\npublish_to: none\n');
    final another = await Directory(p.join(workspace.path, 'another')).create();
    await File(
      p.join(another.path, 'pubspec.yaml'),
    ).writeAsString('name: invalid-name\nversion: 1.2.3\n');
    await expectLater(
      ci.dart.publishToPubDev(serviceAccountJsonBase64: ''),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('only accepts'),
        ),
      ),
    );
    await expectLater(
      ci.dart.publishToPubDev(serviceAccountJsonBase64: '', dir: 'another'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('valid package name'),
        ),
      ),
    );
  });
}
