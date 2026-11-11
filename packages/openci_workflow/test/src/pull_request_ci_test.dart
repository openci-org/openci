import 'dart:io';
import 'dart:isolate';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory output;
  late File probe;
  late String packages;
  const preview =
      'https://preview.example.com/build(42)?platform=ios&lang=ja#install';
  const documentation = 'http://docs.example.org/preview';

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('openci-pr-qr-test-');
    addTearDown(() => root.delete(recursive: true));
    packages = (await Isolate.packageConfig)!.toFilePath();
    output = await Directory.fromUri(root.uri.resolve('urls')).create();
    probe = File.fromUri(root.uri.resolve('probe.dart'));
    await probe.writeAsString('''
import 'package:openci_workflow/openci_workflow.dart';
Future<void> main(List<String> args) async {
  final ci = await OpenCI.init(workflowName: 'Test', ciTriggers: const []);
  final PullRequestCI pr = ci.pullRequest;
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
    final entries = await output.list().where((e) => e is Directory).toList();
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
