import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory output;
  late File probe;
  late String packages;
  late File credentials;
  const preview =
      'https://preview.example.com/build(42)?platform=ios&lang=ja#install';
  const documentation = 'http://docs.example.org/preview';

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('openci-pr-qr-test-');
    addTearDown(() => root.delete(recursive: true));
    packages = (await Isolate.packageConfig)!.toFilePath();
    output = await Directory.fromUri(root.uri.resolve('urls')).create();
    final key = File('${root.path}/test-key.pem');
    final generated = await Process.run('openssl', [
      'genpkey',
      '-algorithm',
      'RSA',
      '-pkeyopt',
      'rsa_keygen_bits:2048',
      '-out',
      key.path,
    ]);
    expect(generated.exitCode, 0, reason: generated.stderr.toString());
    credentials = File('${root.path}/test-credentials');
    await credentials.writeAsString(
      base64Encode(
        utf8.encode(
          jsonEncode({
            'type': 'service_account',
            'client_id': '123456789',
            'client_email': 'test@test-project.iam.gserviceaccount.com',
            'private_key': await key.readAsString(),
          }),
        ),
      ),
    );
    probe = File.fromUri(root.uri.resolve('probe.dart'));
    await probe.writeAsString('''
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflow/openci_workflow.dart';
Future<void> main(List<String> args) async {
  final ci = await OpenCI.init(workflowName: 'Test', ciTriggers: const []);
  final PullRequestCI pr = ci.pullRequest;
  if (args.first == 'upload') {
    final platform = args[1];
    final appId = '1:123456789:' + platform + ':abcdef';
    final releaseName = 'projects/123456789/apps/' + appId + '/releases/release-1';
    final temporary = await Directory.systemTemp.createTemp('openci-qr-upload-');
    try {
      final binary = File(temporary.path + (platform == 'ios' ? '/app.ipa' : '/app.apk'));
      await binary.writeAsBytes([1, 2, 3]);
      final serviceAccount = await File(args[3]).readAsString();
      final link = await http.runWithClient(
        () => platform == 'ios'
          ? ci.flutter.deployIpaToFirebaseAppDistribution(
              ipaPath: binary.path, appId: appId,
              serviceAccountJsonBase64: serviceAccount,
            )
          : ci.flutter.deployApkToFirebaseAppDistribution(
              apkPath: binary.path, appId: appId,
              serviceAccountJsonBase64: serviceAccount,
            ),
        () => MockClient((request) async => http.Response(jsonEncode(
          request.url.host == 'oauth2.googleapis.com'
            ? {'access_token': 'test-access-token', 'expires_in': 3600, 'token_type': 'Bearer'}
            : {'name': releaseName + '/operations/upload-1', 'done': true,
                'response': {'release': {
                  'name': releaseName, 'testingUri': args[2],
                  if (args.length < 5) 'displayVersion': '1.16.2',
                  if (args.length < 5) 'buildVersion': platform == 'ios' ? '3' : '4',
                  'binaryDownloadUri': 'https://example.org/private-signed-download',
                }}},
        ), 200, headers: {'content-type': 'application/json'})),
      );
      if (link != Uri.parse(args[2])) throw StateError('Incorrect tester URL');
    } finally {
      await temporary.delete(recursive: true);
    }
    return;
  }
  if (args.first == 'details') {
    await pr.postQrCode(url: Uri.parse(args[1]), version: args[2], buildNumber: args[3]);
    return;
  }
  if (args.first == 'parallel') {
    await Future.wait(args.skip(1).map((link) => pr.postQrCode(url: Uri.parse(link))));
    return;
  }
  await pr.postQrCode(url: Uri.parse(args[0]), lang: .ja, size: .small);
  await pr.postQrCode(url: Uri.parse(args[1]));
  if (args.length > 2) {
    await pr.postQrCode(url: Uri.parse(args[2]), size: .large);
  }
  if (args.length > 3) {
    await pr.postQrCode(
      url: Uri.parse(args[3]),
      size: .custom(width: 200, height: 150),
    );
  }
}
''');
  });

  Future<List<String>> readRecords(Directory output) async {
    final entries = await output
        .list()
        .where(
          (e) =>
              e is Directory &&
              e.path.split(Platform.pathSeparator).last.startsWith('qr-'),
        )
        .toList();
    entries.sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final entry in entries)
        ...(await File('${entry.path}/url').readAsLines()),
    ];
  }

  Future<ProcessResult> run(
    Map<String, String> env, {
    List<String> args = const [preview, documentation],
  }) => Process.run(
    Platform.resolvedExecutable,
    ['--packages=$packages', probe.path, ...args],
    environment: {'PATH': Platform.environment['PATH']!, ...env},
    includeParentEnvironment: false,
  );

  test(
    'appends web URLs with language and preset or custom sizes, including query and fragment',
    () async {
      const largeUrl = 'https://releases.example.com/app';
      const customUrl = 'https://releases.example.com/custom';
      final result = await run(
        {'OPENCI_PR_QR_OUTPUT': output.path},
        args: [preview, documentation, largeUrl, customUrl],
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(await readRecords(output), [
        'ja\t120x120\t$preview',
        'en\t180x180\t$documentation',
        'en\t240x240\t$largeUrl',
        'en\t200x150\t$customUrl',
      ]);
    },
  );

  test('parallel calls retain every URL', () async {
    final parallelOutput = await Directory.fromUri(
      root.uri.resolve('parallel'),
    ).create();
    final urls = List.generate(
      8,
      (i) => 'https://example.org/build/$i/${'x' * 2250}',
    );
    final result = await run(
      {'OPENCI_PR_QR_OUTPUT': parallelOutput.path},
      args: ['parallel', ...urls],
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
      await readRecords(parallelOutput),
      unorderedEquals(urls.map((u) => 'en\t180x180\t$u')),
    );
  });

  Future<List<Map<String, dynamic>>> readMetadata(Directory output) async {
    final result = <Map<String, dynamic>>[];
    await for (final entry in output.list()) {
      if (!entry.path.split(Platform.pathSeparator).last.startsWith('qr-')) {
        continue;
      }
      final file = File('${entry.path}/metadata.json');
      if (await file.exists()) {
        result.add(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
      }
    }
    return result;
  }

  for (final platform in ['ios', 'android']) {
    test(
      '$platform uploads retain actual app versions across processes for the matching URL only',
      () async {
        final releaseOutput = await Directory(
          '${root.path}/release-$platform',
        ).create();
        final link =
            'https://appdistribution.firebase.google.com/testerapps/'
            '1:123456789:$platform:abcdef/releases/release-1?source=qr';
        final env = {'OPENCI_PR_QR_OUTPUT': releaseOutput.path};
        final uploaded = await run(
          env,
          args: ['upload', platform, link, credentials.path],
        );
        expect(uploaded.exitCode, 0, reason: uploaded.stderr.toString());
        expect(await readRecords(releaseOutput), isEmpty);
        final posted = await run(
          env,
          args: [link, documentation, '$link&different=1'],
        );
        expect(posted.exitCode, 0, reason: posted.stderr.toString());
        expect(await readRecords(releaseOutput), [
          'ja\t120x120\t$link',
          'en\t180x180\t$documentation',
          'en\t240x240\t$link&different=1',
        ]);
        expect(await readMetadata(releaseOutput), [
          {'version': '1.16.2', 'buildNumber': platform == 'ios' ? '3' : '4'},
        ]);
        final overridden = await run(
          env,
          args: ['details', link, '2.0.0', '42'],
        );
        expect(overridden.exitCode, 0, reason: overridden.stderr.toString());
        expect(
          await readMetadata(releaseOutput),
          contains(equals({'version': '2.0.0', 'buildNumber': '42'})),
        );
        expect(
          await Directory(
            '${releaseOutput.path}/releases',
          ).list().where((e) => e is File).toList(),
          hasLength(1),
        );
        final cached = await Directory(
          '${releaseOutput.path}/releases',
        ).list().where((e) => e is File).single;
        expect(
          await File(cached.path).readAsString(),
          isNot(contains('private-signed-download')),
        );
      },
    );
  }

  test(
    'missing release metadata does not invent a version or build number',
    () async {
      final releaseOutput = await Directory(
        '${root.path}/missing-release',
      ).create();
      const link =
          'https://appdistribution.firebase.google.com/testerapps/'
          '1:123456789:ios:abcdef/releases/release-1';
      final env = {
        'OPENCI_PR_QR_OUTPUT': releaseOutput.path,
        'OPENCI_RUN_NUMBER': '71',
      };
      final uploaded = await run(
        env,
        args: ['upload', 'ios', link, credentials.path, 'missing'],
      );
      expect(uploaded.exitCode, 0, reason: uploaded.stderr.toString());
      final posted = await run(env, args: [link, documentation]);
      expect(posted.exitCode, 0, reason: posted.stderr.toString());
      expect(await readMetadata(releaseOutput), isEmpty);
    },
  );

  test('validates explicit release values before writing any output', () async {
    for (final value in [
      ' 1.16.2',
      '1.16.2 ',
      '1.16.2\n#71',
      'x' * 257,
      'あ' * 86,
    ]) {
      await expectLater(
        const PullRequestCI().postQrCode(
          url: Uri.parse(preview),
          version: value,
        ),
        throwsArgumentError,
      );
      await expectLater(
        const PullRequestCI().postQrCode(
          url: Uri.parse(preview),
          buildNumber: value,
        ),
        throwsArgumentError,
      );
    }
  });

  test(
    'push and local runs skip publication, old executors report the missing capability',
    () async {
      for (final env in [
        <String, String>{},
        {'OPENCI_RUN_ID': 'run', 'OPENCI_PR_QR_OUTPUT': ''},
      ]) {
        final result = await run(env);
        expect(result.exitCode, 0, reason: result.stderr.toString());
      }
      final result = await run({'OPENCI_RUN_ID': 'run'});
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('does not support pull request QR codes'));
    },
  );

  test(
    'rejects relative, non-web, credential-bearing and oversized URLs',
    () async {
      for (final link in [
        '/local',
        'mailto:test@example.org',
        'https://user:private@example.org',
        'https://example.org:99999',
        'https://example.org/${'x' * 2331}',
      ]) {
        await expectLater(
          const PullRequestCI().postQrCode(url: Uri.parse(link)),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              isNot(contains('private')),
            ),
          ),
        );
      }
    },
  );

  test(
    'compares sizes by value and rejects out-of-range custom dimensions',
    () async {
      expect(
        PostQrCodeSize.small,
        const PostQrCodeSize.custom(width: 120, height: 120),
      );
      expect(
        PostQrCodeSize.medium.hashCode,
        const PostQrCodeSize.custom(width: 180, height: 180).hashCode,
      );
      expect(PostQrCodeSize.small, isNot(PostQrCodeSize.large));
      expect(
        PostQrCodeSize.large.toString(),
        'PostQrCodeSize(width: 240, height: 240)',
      );
      for (final invalid in const <PostQrCodeSize>[
        .custom(width: 0, height: 180),
        .custom(width: 180, height: 0),
        .custom(width: -1, height: 180),
        .custom(width: 1001, height: 180),
        .custom(width: 180, height: 1001),
      ]) {
        await expectLater(
          const PullRequestCI().postQrCode(
            url: Uri.parse(documentation),
            size: invalid,
          ),
          throwsArgumentError,
        );
      }
    },
  );
}
