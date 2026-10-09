import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Logger implements Logger {
  final output = <String>[];
  final errors = <String>[];
  @override
  void stdout(String message) => output.add(message);
  @override
  void stderr(String message) => errors.add(message);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const token = 'private-file-test-token';
  late Directory root;
  late File file;
  late CredentialStore store;
  late _Logger logger;
  late List<http.Request> requests;
  late Future<String?> Function() selectFile;
  late int selections;
  late MockClientHandler handler;
  late File paths;
  late File secrets;
  late Set<String> savedNames;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('openci-register-file-');
    await Directory(p.join(root.path, 'openci')).create();
    await Directory(p.join(root.path, 'lib')).create();
    await File(
      p.join(root.path, 'pubspec.yaml'),
    ).writeAsString('name: example\n');
    paths = File(p.join(root.path, 'openci', 'generated', 'paths.g.dart'));
    secrets = File(p.join(root.path, 'openci', 'generated', 'secrets.g.dart'));
    file = File(p.join(root.path, 'google-services.json'));
    await file.writeAsString('  {"private":"日本語"}\n');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    await store.saveProfile(
      'test',
      const AuthProfile(
        serverUrl: 'https://ci.example.com/proxy/',
        token: token,
        teamId: 'selected/team',
      ),
    );
    logger = _Logger();
    requests = [];
    selections = 0;
    selectFile = () async => file.path;
    savedNames = {'EXISTING_SECRET'};
    handler = (request) async {
      if (request.method == 'POST') {
        savedNames.add((jsonDecode(request.body) as Map)['name'] as String);
      }
      return http.Response(
        jsonEncode({
          'success': true,
          if (request.method == 'GET')
            'secrets': [
              for (final name in savedNames) {'name': name},
            ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    };
  });

  tearDown(() async {
    final output = [...logger.output, ...logger.errors].join('\n');
    expect(output, isNot(contains(token)));
    expect(output, isNot(contains('{"private":')));
    for (final request in requests.where(
      (r) => r.url.host == 'ci.example.com' && r.method == 'POST',
    )) {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(output, isNot(contains(payload['value'] as String)));
      expect(
        await File(store.filePath).readAsString(),
        isNot(contains(payload['value'] as String)),
      );
      if (await secrets.exists()) {
        expect(
          await secrets.readAsString(),
          isNot(contains(payload['value'] as String)),
        );
      }
    }
    if (!requests.any((request) => request.method == 'GET')) {
      expect(await paths.exists(), isFalse);
      expect(await secrets.exists(), isFalse);
    }
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('genuineci register', 'test')
      ..addCommand(
        RegisterSecretFileCommand(
          logger: logger,
          credentialStore: store,
          workingDirectory: Directory(p.join(root.path, 'lib')),
          selectFile: () {
            selections++;
            return selectFile();
          },
        ),
      );
    return http.runWithClient(
      () => runner.run(['secretFile', ...arguments]),
      () => MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  test(
    'registers the exact file bytes as Base64 with the derived name',
    () async {
      final bytes = await file.readAsBytes();
      final credentials = await File(store.filePath).readAsString();
      expect(await run(), 0);
      expect(requests.map((request) => request.method), ['POST', 'GET']);
      final request = requests.first;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://ci.example.com/proxy/teams/selected%2Fteam/secrets',
      );
      expect(request.headers['authorization'], 'Bearer $token');
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['name'], 'GOOGLE_SERVICES_JSON_BASE64');
      expect(base64Decode(payload['value'] as String), bytes);
      expect(await file.readAsBytes(), bytes);
      expect(await File(store.filePath).readAsString(), credentials);
      expect(logger.output, [
        t.register.secret.saved(
          name: 'GOOGLE_SERVICES_JSON_BASE64',
          teamId: 'selected/team',
        ),
        t.sync.paths.saved(path: paths.path),
        t.sync.secrets.saved(path: secrets.path),
      ]);
      expect(await paths.readAsString(), contains('WorkspaceDirectory("lib")'));
      final definitions = await secrets.readAsString();
      expect(
        definitions,
        contains("Platform.environment['GOOGLE_SERVICES_JSON_BASE64']"),
      );
      expect(definitions, contains("Platform.environment['EXISTING_SECRET']"));
      expect(requests.last.url, request.url);
      expect(requests.last.headers['authorization'], 'Bearer $token');
    },
  );

  test('supports binary files that are not UTF-8', () async {
    file = File(p.join(root.path, 'signing key.p12'));
    await file.writeAsBytes([0, 255, 128, 13, 10, 0]);
    expect(await run(), 0);
    expect(jsonDecode(requests.first.body), {
      'name': 'SIGNING_KEY_P12_BASE64',
      'value': base64Encode([0, 255, 128, 13, 10, 0]),
    });
  });

  test('refreshes Firebase authentication before showing the picker', () async {
    final profile = (await store.getActiveProfile())!;
    await store.saveProfile(
      'test',
      profile.copyWith(
        authType: 'firebase',
        firebaseApiKey: 'firebase-api-key',
        refreshToken: 'private-refresh-token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
    );
    final saveHandler = handler;
    handler = (request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        expect(selections, 0);
        return http.Response(
          jsonEncode({
            'id_token': 'refreshed-id-token',
            'refresh_token': 'private-refresh-token',
            'expires_in': '3600',
          }),
          200,
        );
      }
      expect(request.headers['authorization'], 'Bearer refreshed-id-token');
      return saveHandler(request);
    };
    expect(await run(), 0);
    expect(requests, hasLength(3));
  });

  test('reports a sync failure after successfully saving the file', () async {
    final saveHandler = handler;
    handler = (request) async => request.method == 'GET'
        ? http.Response('private-file-contents', 500)
        : saveHandler(request);

    expect(await run(), 1);

    expect(savedNames, contains('GOOGLE_SERVICES_JSON_BASE64'));
    expect(requests.map((request) => request.method), ['POST', 'GET']);
    expect(await paths.exists(), isTrue);
    expect(await secrets.exists(), isFalse);
    expect(
      logger.output.first,
      t.register.secret.saved(
        name: 'GOOGLE_SERVICES_JSON_BASE64',
        teamId: 'selected/team',
      ),
    );
    expect(logger.errors, [t.sync.secrets.requestFailed(status: 500)]);
    expect(logger.errors.join('\n'), isNot(contains('private-file-contents')));
  });

  test('still syncs secrets when workspace path generation fails', () async {
    await File(
      p.join(root.path, 'pubspec.yaml'),
    ).writeAsString('workspace: [\n');

    expect(await run(), 1);

    expect(savedNames, contains('GOOGLE_SERVICES_JSON_BASE64'));
    expect(await paths.exists(), isFalse);
    expect(
      await secrets.readAsString(),
      contains("Platform.environment['GOOGLE_SERVICES_JSON_BASE64']"),
    );
    expect(logger.errors.single, contains('invalid YAML'));
  });

  test('keeps the saved file when run outside a workflow project', () async {
    await Directory(p.join(root.path, 'openci')).delete(recursive: true);

    expect(await run(), 1);

    expect(savedNames, contains('GOOGLE_SERVICES_JSON_BASE64'));
    expect(requests.single.method, 'POST');
    expect(logger.errors, [
      t.sync.paths.projectRootNotFound,
      t.sync.secrets.workflowDirectoryNotFound,
    ]);
  });

  test(
    'requires authentication before selecting or reading any file',
    () async {
      await store.saveProfile('test', const AuthProfile());
      expect(await run(), 1);
      expect(selections, 0);
      expect(requests, isEmpty);
      expect(logger.errors, [t.register.secret.loginRequired]);
    },
  );

  test('rejects positional arguments before opening the picker', () async {
    await expectLater(run([file.path]), throwsA(isA<UsageException>()));
    expect(selections, 0);
    expect(requests, isEmpty);
  });

  test('help does not select or upload a file', () async {
    expect(await run(['--help']), isNull);
    expect(selections, 0);
    expect(requests, isEmpty);
  });

  test('cancelling does not upload a file', () async {
    selectFile = () async => null;
    expect(await run(), 1);
    expect(requests, isEmpty);
    expect(logger.errors, [t.register.secretFile.cancelled]);
  });

  test('picker failures do not disclose exception contents', () async {
    selectFile = () async =>
        throw const FormatException('private-file-contents');
    expect(await run(), 1);
    expect(requests, isEmpty);
    expect(logger.errors, [t.register.secretFile.inputFailed]);
  });

  test('rejects an empty file without uploading', () async {
    await file.writeAsBytes([]);
    expect(await run(), 1);
    expect(requests, isEmpty);
    expect(logger.errors, [t.register.secretFile.emptyFile]);
  });

  for (final kind in ['missing', 'directory']) {
    test('rejects a $kind path without uploading', () async {
      selectFile = () async =>
          kind == 'directory' ? root.path : p.join(root.path, 'missing');
      expect(await run(), 1);
      expect(requests, isEmpty);
      expect(logger.errors, [t.register.secretFile.readFailed]);
    });
  }

  test('server errors do not print an echoed encoded file', () async {
    handler = (request) async => http.Response(request.body, 500);
    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.register.secret.requestFailed(status: 500)]);
  });
}
