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
  await pr.postQrCode(url: Uri.parse(args.first), lang: PostQrCodeLang.ja);
  await pr.postQrCode(url: Uri.parse(args.last));
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
    'appends web URLs from different sources, including query and fragment',
    () async {
      final result = await run({'OPENCI_PR_QR_OUTPUT': output.path});
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(await readRecords(output), [
        'ja\t$preview',
        'en\t$documentation',
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
      unorderedEquals(urls.map((u) => 'en\t$u')),
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
}
