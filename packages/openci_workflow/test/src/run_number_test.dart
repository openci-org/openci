import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  late Directory directory;
  late File probe;
  late String packageConfigPath;

  setUpAll(() async {
    packageConfigPath = (await Isolate.packageConfig)!.toFilePath();
    directory = await Directory.systemTemp.createTemp('openci-run-number-');
    addTearDown(() => directory.delete(recursive: true));
    probe = File('${directory.path}/probe.dart');
    await probe.writeAsString('''
import 'dart:convert';
import 'dart:io';
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main(List<String> args) async {
  final openCI = await OpenCI.init(workflowName: 'Test', ciTriggers: const []);
  if (args.single == 'init') {
    print('initialized');
    return;
  }
  try {
    final int first = openCI.runNumber;
    final int second = openCI.runNumber;
    print(jsonEncode([first, second]));
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}
''');
  });

  Future<ProcessResult> runProbe(String? value, {String action = 'read'}) =>
      Process.run(
        Platform.resolvedExecutable,
        ['--packages=$packageConfigPath', probe.path, action],
        environment: {
          'PATH': Platform.environment['PATH']!,
          'OPENCI_RUN_NUMBER': ?value,
        },
        includeParentEnvironment: false,
      );

  group('OpenCI.runNumber', () {
    for (final number in [1, 42, 2147483647]) {
      test('returns $number unchanged on repeated reads', () async {
        final result = await runProbe(number.toString());

        expect(result.exitCode, 0, reason: result.stderr.toString());
        expect(jsonDecode(result.stdout as String), [number, number]);
        expect(result.stderr, isEmpty);
      });
    }

    for (final testCase in <String, String?>{
      'missing': null,
      'empty': '',
      'whitespace': ' ',
      'zero': '0',
      'negative': '-1',
      'fractional': '1.5',
      'scientific notation': '1e2',
      'hexadecimal': '0x2a',
      'text': 'not-a-number',
      'overflow': '9223372036854775808',
    }.entries) {
      test('rejects a ${testCase.key} value with a clear StateError', () async {
        final result = await runProbe(testCase.value);

        expect(result.exitCode, 2);
        expect(result.stdout, isEmpty);
        expect(
          result.stderr,
          'OPENCI_RUN_NUMBER must be set to a positive decimal integer.\n',
        );
      });
    }

    test('initialization does not require a run number', () async {
      final result = await runProbe(null, action: 'init');

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, 'initialized\n');
    });
  });
}
