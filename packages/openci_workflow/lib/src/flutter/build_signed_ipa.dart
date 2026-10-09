import 'dart:io';

import '../quote_shell_argument.dart';

Future<void> buildSignedIpa({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String exportOptionsPlistPath,
  required String ipaDirectory,
  required List<String> arguments,
  String? dir,
}) async {
  final started = File.fromUri(
    Directory.systemTemp.uri.resolve('openci-ipa-build-started'),
  );
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
    'find ${quoteShellArgument(ipaDirectory)} -type f -name \'*.ipa\' '
    '-size +0c -newer ${quoteShellArgument(started.path)} -print -quit '
    '| grep -q . || { '
    "printf '%s\\n' 'Flutter did not export a new IPA.' >&2; exit 1; }",
    workingDirectory: dir,
  );
}
