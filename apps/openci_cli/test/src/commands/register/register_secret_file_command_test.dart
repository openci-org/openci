import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/openci_cli.dart';
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

  setUp(() async {
    root = await Directory.systemTemp.createTemp('openci-register-file-');
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
    handler = (_) async => http.Response('{"success":true}', 200);
  });

  tearDown(() async {
    final output = [...logger.output, ...logger.errors].join('\n');
    expect(output, isNot(contains(token)));
    expect(output, isNot(contains('{"private":')));
    for (final request in requests.where(
      (r) => r.url.host == 'ci.example.com',
    )) {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(output, isNot(contains(payload['value'] as String)));
      expect(
        await File(store.filePath).readAsString(),
        isNot(contains(payload['value'] as String)),
      );
    }
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('openci register', 'test')
      ..addCommand(
        RegisterSecretFileCommand(
          logger: logger,
          credentialStore: store,
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
      final request = requests.single;
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
      ]);
    },
  );

  test('supports binary files that are not UTF-8', () async {
    file = File(p.join(root.path, 'signing key.p12'));
    await file.writeAsBytes([0, 255, 128, 13, 10, 0]);
    expect(await run(), 0);
    expect(jsonDecode(requests.single.body), {
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
      return http.Response('{"success":true}', 200);
    };
    expect(await run(), 0);
    expect(requests, hasLength(2));
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
