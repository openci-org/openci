import '../quote_shell_argument.dart';

/// Dart checks using the toolchain already available on the build machine.
class DartCI {
  const DartCI(this._run);

  final Future<void> Function(String command, {String? workingDirectory}) _run;

  /// Checks tracked and non-ignored new Dart files without rewriting them.
  ///
  /// Uses the workflow's working directory unless [dir] overrides it. The
  /// directory must be inside a Git checkout. An empty file selection succeeds;
  /// formatting differences, Git errors, and formatter errors fail the command.
  Future<void> checkFormat({String? dir}) {
    const command =
        'git ls-files --cached --others --exclude-standard -z -- "*.dart" '
        '| xargs -0 -r dart format --output=none --set-exit-if-changed --';

    // Preserve Git failures even when xargs receives no files.
    return _run(
      'bash -o pipefail -c ${quoteShellArgument(command)}',
      workingDirectory: dir,
    );
  }
}
