import 'dart:io';

import '../quote_shell_argument.dart';

Future<String> buildSignedIpa({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String exportOptionsPlistPath,
  required String ipaDirectory,
  required List<String> arguments,
  String? dir,
}) async {
  final temporary = await Directory.systemTemp.createTemp('openci-ipa-build-');
  final started = File.fromUri(temporary.uri.resolve('started'));
  final artifacts = File.fromUri(temporary.uri.resolve('artifacts'));
  try {
    await started.writeAsString('');

    await run(
      [
        'flutter build ipa',
        ...arguments.map(quoteShellArgument),
        '--release --codesign',
        '--export-options-plist ${quoteShellArgument(exportOptionsPlistPath)}',
      ].join(' '),
      workingDirectory: dir,
    );
    // Flutter can exit successfully after archiving even when IPA export fails.
    await run(
      '''
set -e
ipa_directory=${quoteShellArgument(ipaDirectory)}
case "\$ipa_directory" in
  /*) ;;
  *) ipa_directory="\$PWD/\$ipa_directory" ;;
esac
if [ -d "\$ipa_directory" ]; then
  find "\$ipa_directory" -type f -name '*.ipa' -size +0c -newer ${quoteShellArgument(started.path)} -print0 > ${quoteShellArgument(artifacts.path)}
else
  : > ${quoteShellArgument(artifacts.path)}
fi
''',
      workingDirectory: dir,
    );
    final paths = (await artifacts.readAsString())
        .split('\u0000')
        .where((path) => path.isNotEmpty)
        .toList();
    if (paths.isEmpty) {
      throw StateError('Flutter did not export a new IPA.');
    }
    if (paths.length != 1) {
      throw StateError('Flutter exported multiple IPAs; cannot select one.');
    }
    return paths.single;
  } finally {
    await temporary.delete(recursive: true);
  }
}
