import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/asc/asc_api_key.dart';
import 'package:genuineci_cli/src/asc/asc_authentication_status.dart';
import 'package:genuineci_cli/src/asc/create_asc_api_key.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _InputSink implements IOSink {
  bool closed = false;

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CreateProcess implements Process {
  _CreateProcess({
    required String output,
    int? code = 0,
    Stream<List<int>>? stdout,
    Stream<List<int>>? stderr,
  }) : stdout = stdout ?? Stream.value(utf8.encode(output)),
       stderr = stderr ?? const Stream.empty() {
    if (code != null) exited.complete(code);
  }

  final exited = Completer<int>();
  final signals = <ProcessSignal>[];

  @override
  final _InputSink stdin = _InputSink();

  @override
  final Stream<List<int>> stdout;

  @override
  final Stream<List<int>> stderr;

  @override
  Future<int> get exitCode => exited.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    signals.add(signal);
    if (!exited.isCompleted) exited.complete(-signal.signalNumber);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final executable = File('cached tools/asc');
  const appleId = "o'hara+ios@example.com";
  const status = AscAuthenticationStatus(
    authenticated: true,
    providerId: 123,
    publicProviderId: 'PUBLIC1234',
  );
  late Directory directory;
  late File privateKey;
  late _CreateProcess process;
  late Map<String, Object?> response;
  late List<List<String>> invocations;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('asc key test ');
    privateKey = File(p.join(directory.path, 'AuthKey_KEY123.p8'));
    await privateKey.writeAsString('FAKE PRIVATE KEY FOR TEST');
    response = {
      'keyId': 'KEY123',
      'issuerId': 'test-issuer-id',
      'p8Path': privateKey.path,
      'roles': ['APP_MANAGER'],
      'active': true,
    };
    process = _CreateProcess(output: jsonEncode(response));
    invocations = [];
  });

  tearDown(() => directory.delete(recursive: true));

  Future<AscApiKey> create({AscAuthenticationStatus session = status}) =>
      createAscApiKey(
        executable,
        appleId,
        session,
        directory,
        processStarter: (path, arguments) async {
          expect(path, executable.absolute.path);
          invocations.add(arguments);
          return process;
        },
      );

  Matcher failsWith(AscApiKeyFailure failure) => throwsA(
    isA<AscApiKeyException>().having(
      (error) => error.failure,
      'failure',
      failure,
    ),
  );

  for (final (providerId, publicProviderId) in <(int?, String?)>[
    (123, 'PUBLIC1234'),
    (123, null),
    (null, 'PUBLIC1234'),
  ]) {
    test(
      'creates for exactly the confirmed provider ($providerId, $publicProviderId)',
      () async {
        final key = await create(
          session: AscAuthenticationStatus(
            authenticated: true,
            providerId: providerId,
            publicProviderId: publicProviderId,
          ),
        );

        expect(invocations, [
          [
            'web',
            'api-keys',
            'create',
            '--apple-id',
            appleId,
            if (providerId != null) ...['--provider-id', '$providerId'],
            if (publicProviderId != null) ...[
              '--public-provider-id',
              publicProviderId,
            ],
            '--name',
            'GenuineCI',
            '--role',
            'APP_MANAGER',
            '--output-dir',
            directory.absolute.path,
            '--output',
            'json',
          ],
        ]);
        expect(key.keyId, 'KEY123');
        expect(key.issuerId, 'test-issuer-id');
        expect(key.privateKeyFile.path, privateKey.path);
        final metadata = File(p.join(directory.path, 'key.json'));
        expect(jsonDecode(await metadata.readAsString()), {
          'keyId': 'KEY123',
          'issuerId': 'test-issuer-id',
          'providerId': ?providerId,
          'publicProviderId': ?publicProviderId,
          'role': 'APP_MANAGER',
          'p8Path': privateKey.path,
        });
        if (!Platform.isWindows) {
          expect((await metadata.stat()).mode & 0x1ff, 0x180);
        }
        expect(process.stdin.closed, isTrue);
        expect(process.signals, isEmpty);
      },
    );
  }

  for (final session in [
    const AscAuthenticationStatus(authenticated: false, providerId: 123),
    const AscAuthenticationStatus(authenticated: true),
    const AscAuthenticationStatus(authenticated: true, providerId: 0),
    const AscAuthenticationStatus(authenticated: true, publicProviderId: ' '),
  ]) {
    test('rejects an unusable session before starting asc: $session', () async {
      await expectLater(create(session: session), throwsArgumentError);
      expect(invocations, isEmpty);
    });
  }

  test('reports a startup failure without raw diagnostics', () async {
    await expectLater(
      createAscApiKey(
        executable,
        appleId,
        status,
        directory,
        processStarter: (_, _) async =>
            throw const ProcessException('asc', [], 'private diagnostic'),
      ),
      failsWith(AscApiKeyFailure.start),
    );
  });

  for (final code in [1, 7, -2]) {
    test(
      'retains a downloaded key after exit $code and never retries',
      () async {
        process = _CreateProcess(output: jsonEncode(response), code: code);

        await expectLater(create(), failsWith(AscApiKeyFailure.execution));
        expect(invocations, hasLength(1));
        expect(await privateKey.readAsString(), 'FAKE PRIVATE KEY FOR TEST');
        expect(
          await File(p.join(directory.path, 'key.json')).exists(),
          isFalse,
        );
      },
    );
  }

  for (final fields in <Map<String, Object?>>[
    {'keyId': null},
    {'keyId': ''},
    {'keyId': '../outside'},
    {'issuerId': null},
    {'issuerId': ' '},
    {'issuerId': 'issuer\u001b[2J'},
    {'p8Path': null},
    {'p8Path': '/outside/AuthKey_KEY123.p8'},
    {'roles': null},
    {
      'roles': ['ADMIN'],
    },
    {
      'roles': ['APP_MANAGER', 'ADMIN'],
    },
    {'active': false},
    {'active': 'true'},
  ]) {
    test(
      'does not accept a malformed or unexpected key: ${jsonEncode(fields)}',
      () async {
        process = _CreateProcess(output: jsonEncode({...response, ...fields}));
        await expectLater(create(), failsWith(AscApiKeyFailure.response));
        expect(await privateKey.exists(), isTrue);
        expect(
          await File(p.join(directory.path, 'key.json')).exists(),
          isFalse,
        );
        expect(invocations, hasLength(1));
      },
    );
  }

  for (final output in ['not json', 'null', '[]', 'x' * (16 * 1024 + 1)]) {
    test(
      'rejects invalid or oversized JSON (${output.length} bytes)',
      () async {
        process = _CreateProcess(output: output);
        await expectLater(create(), failsWith(AscApiKeyFailure.response));
        expect(await privateKey.exists(), isTrue);
      },
    );
  }

  for (final empty in [true, false]) {
    test('rejects a ${empty ? 'zero-length' : 'missing'} P8', () async {
      if (empty) {
        await privateKey.writeAsString('');
      } else {
        await privateKey.delete();
      }
      await expectLater(create(), failsWith(AscApiKeyFailure.response));
      expect(await File(p.join(directory.path, 'key.json')).exists(), isFalse);
    });
  }

  test('rejects a symlink in place of the downloaded P8', () async {
    final target = File(p.join(directory.path, 'other.p8'));
    await privateKey.rename(target.path);
    await Link(privateKey.path).create(target.path);
    await expectLater(create(), failsWith(AscApiKeyFailure.response));
    expect(await target.readAsString(), 'FAKE PRIVATE KEY FOR TEST');
  }, skip: Platform.isWindows);

  test('retains the private key when metadata cannot be saved', () async {
    await Directory(p.join(directory.path, 'key.json')).create();
    await expectLater(create(), failsWith(AscApiKeyFailure.storage));
    expect(await privateKey.readAsString(), 'FAKE PRIVATE KEY FOR TEST');
    expect(invocations, hasLength(1));
  });

  test('waits for the child and drains its diagnostics', () async {
    var drained = false;
    process = _CreateProcess(
      output: jsonEncode(response),
      code: null,
      stderr: (() async* {
        for (var i = 0; i < 100; i++) {
          yield utf8.encode('private diagnostic');
        }
        drained = true;
      })(),
    );
    var completed = false;
    final result = create().whenComplete(() => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    process.exited.complete(0);
    await result;
    expect(drained, isTrue);
  });

  test('terminates a child after a stream failure and retains files', () async {
    process = _CreateProcess(
      output: '',
      code: null,
      stdout: Stream.error(const FileSystemException('private diagnostic')),
    );
    await expectLater(create(), failsWith(AscApiKeyFailure.execution));
    expect(process.signals, [ProcessSignal.sigterm]);
    expect(await privateKey.exists(), isTrue);
    expect(invocations, hasLength(1));
  });
}
