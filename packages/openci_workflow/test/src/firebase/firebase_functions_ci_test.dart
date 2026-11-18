import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/src/firebase/firebase_functions_ci.dart';
import 'package:test/test.dart';

void main() {
  const credentialJson = '''{
    "type": "service_account",
    "client_email": "deploy@credential-project.iam.gserviceaccount.com",
    "private_key": "fixture-private-key"
  }''';
  final credentialBase64 = base64Encode(utf8.encode(credentialJson));
  late Directory workspace;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('functions-test-');
  });
  tearDown(() => workspace.delete(recursive: true));

  test(
    'selects one codebase and uses temporary ADC for the child only',
    () async {
      final parentEnvironment = jsonEncode(Platform.environment);
      late File keyFile;
      final functions = FirebaseFunctionsCI(
        (dir) => '${workspace.path}/$dir',
        processRunner:
            (
              executable,
              args, {
              required workingDirectory,
              required environment,
            }) async {
              expect(executable, 'npx');
              expect(args, [
                '--yes',
                'firebase-tools@15.34.2',
                'deploy',
                '--project=target-project',
                r'--config=config space/$(echo literal).json',
                '--only=functions:api',
                '--non-interactive',
              ]);
              expect(workingDirectory, '${workspace.path}/backend');
              expect(environment.containsKey('FIREBASE_TOKEN'), isFalse);
              keyFile = File(environment['GOOGLE_APPLICATION_CREDENTIALS']!);
              expect(await keyFile.readAsString(), credentialJson);
              expect(environment['XDG_CONFIG_HOME'], keyFile.parent.path);
              expect(keyFile.path, isNot(startsWith(workspace.path)));
              if (!Platform.isWindows) {
                expect((await keyFile.stat()).mode & 0x1ff, 0x180); // 0600
              }
              // Firebase's saved login/cache is removed together with the key.
              await File(
                '${keyFile.parent.path}/firebase-login.json',
              ).writeAsString('{}');
              return 0;
            },
      );
      await functions.deploy(
        projectId: 'target-project',
        codebase: 'api',
        firebaseConfigPath: r'config space/$(echo literal).json',
        serviceAccountJsonBase64: credentialBase64,
        dir: 'backend',
      );
      expect(await keyFile.parent.exists(), isFalse);
      expect(jsonEncode(Platform.environment) == parentEnvironment, isTrue);
    },
  );

  test('omitting codebase deploys all Functions without force', () async {
    final functions = FirebaseFunctionsCI(
      (_) => workspace.path,
      processRunner:
          (_, args, {required workingDirectory, required environment}) async {
            expect(args, contains('--only=functions'));
            expect(args, contains('--config=firebase.json'));
            expect(args, isNot(contains('--force')));
            return 0;
          },
    );
    await functions.deploy(
      projectId: 'target-project',
      serviceAccountJsonBase64: credentialBase64,
    );
  });

  for (final startupFailure in [false, true]) {
    test(
      'cleans up after ${startupFailure ? 'startup' : 'deployment'} failure',
      () async {
        late Directory temporary;
        final functions = FirebaseFunctionsCI(
          (_) => workspace.path,
          processRunner:
              (_, _, {required workingDirectory, required environment}) async {
                temporary = File(
                  environment['GOOGLE_APPLICATION_CREDENTIALS']!,
                ).parent;
                if (startupFailure) {
                  throw const ProcessException('npx', [], 'unavailable', 17);
                }
                return 17;
              },
        );
        await expectLater(
          functions.deploy(
            projectId: 'target-project',
            serviceAccountJsonBase64: credentialBase64,
          ),
          throwsA(
            isA<ProcessException>().having((e) => e.errorCode, 'exit code', 17),
          ),
        );
        expect(await temporary.exists(), isFalse);
      },
    );
  }

  test('invalid credentials fail without exposing decoder input', () async {
    final functions = FirebaseFunctionsCI(
      (_) => workspace.path,
      processRunner:
          (_, _, {required workingDirectory, required environment}) async {
            fail('Invalid credentials must not start a deployment.');
          },
    );
    for (final value in [
      'private-input!!',
      base64Encode(utf8.encode('{"private_key":"private-input"')),
      base64Encode(
        utf8.encode(
          '{"type":"authorized_user","refresh_token":"private-input"}',
        ),
      ),
    ]) {
      await expectLater(
        functions.deploy(
          projectId: 'target-project',
          serviceAccountJsonBase64: value,
        ),
        throwsA(
          isA<FormatException>()
              .having((e) => e.source, 'source', isNull)
              .having(
                (e) => e.toString(),
                'message',
                isNot(contains('private-input')),
              ),
        ),
      );
    }
  });

  test(
    'invalid selectors cannot broaden the deployment to other resources',
    () async {
      final functions = FirebaseFunctionsCI((_) => workspace.path);
      for (final codebase in ['', 'api,hosting', 'api:someFunction', 'API']) {
        await expectLater(
          functions.deploy(
            projectId: 'target-project',
            codebase: codebase,
            serviceAccountJsonBase64: credentialBase64,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'real child receives only the supplied environment and literal arguments',
    () async {
      final probe = File('${workspace.path}/probe.dart');
      await probe.writeAsString('''
import 'dart:convert';
import 'dart:io';
void main(List<String> args) {
  File('result.json').writeAsStringSync(jsonEncode({
    'args': args,
    'value': Platform.environment['OPENCI_FUNCTIONS_TEST'],
    'inheritedPath': Platform.environment.containsKey('PATH'),
    'inheritedToken': Platform.environment.containsKey('FIREBASE_TOKEN'),
  }));
  exitCode = 23;
}
''');
      const arguments = [
        r'spaces $(echo expanded); `echo expanded`',
        '--option=value',
      ];
      final code = await runFirebaseFunctionsProcess(
        Platform.resolvedExecutable,
        [probe.path, ...arguments],
        workingDirectory: workspace.path,
        environment: const {'OPENCI_FUNCTIONS_TEST': 'isolated'},
      );
      expect(code, 23);
      final result =
          jsonDecode(await File('${workspace.path}/result.json').readAsString())
              as Map;
      expect(result['args'], arguments);
      expect(result['value'], 'isolated');
      expect(result['inheritedPath'], isFalse);
      expect(result['inheritedToken'], isFalse);
    },
  );
}
