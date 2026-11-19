import 'dart:io';

import '../quote_shell_argument.dart';
import 'pub_dev_publisher.dart';
import 'pub_publish_result.dart';

class DartCI {
  const DartCI(this._run, {String Function(String? dir)? resolveDirectory})
    : _resolveDirectory = resolveDirectory;

  final Future<void> Function(String command, {String? workingDirectory}) _run;
  final String Function(String? dir)? _resolveDirectory;

  /// Runs a single code generation build with the target package's build_runner.
  Future<void> runBuildRunner({String? dir}) =>
      _run('dart run build_runner build', workingDirectory: dir);

  Future<void> analyze({
    String? dir,
    bool fatalInfos = false,
    bool fatalWarnings = true,
  }) => _run(
    [
      'dart analyze',
      if (fatalInfos) '--fatal-infos',
      if (!fatalWarnings) '--no-fatal-warnings',
    ].join(' '),
    workingDirectory: dir,
  );

  /// Runs the default test suite, or the specified files and directories.
  Future<void> test({String? dir, List<String> paths = const []}) => _run(
    [
      'dart test',
      if (paths.isNotEmpty) '--',
      ...paths.map(quoteShellArgument),
    ].join(' '),
    workingDirectory: dir,
  );

  /// Publishes the package in the workflow directory (or [dir]) to pub.dev.
  ///
  /// Register the Google service account in the package's pub.dev Admin tab.
  /// [serviceAccountJsonBase64] is its Base64-encoded JSON key. Pub validates
  /// the package as part of `dart pub publish --force`: errors stop publishing,
  /// warnings are accepted, and no additional dry run is performed.
  ///
  /// Existing versions fail unless [skipIfPublished] is true, in which case
  /// [PubPublishStatus.alreadyPublished] is returned before authentication.
  /// This does not compare package contents or hide failures during publishing.
  /// Requests time out after one minute and each pub command after ten minutes.
  /// A failed or timed-out upload may have been accepted; check pub.dev before
  /// retrying. Success means pub accepted the upload, not that indexing finished.
  ///
  /// Publishing runs Dart directly and uses temporary, isolated credentials.
  /// When constructing [DartCI] directly, [dir] defaults to the current process
  /// directory unless a directory resolver was supplied to the constructor.
  Future<PubPublishResult> publishToPubDev({
    required String serviceAccountJsonBase64,
    bool skipIfPublished = false,
    String? dir,
  }) => PubDevPublisher().publish(
    workingDirectory:
        _resolveDirectory?.call(dir) ?? Directory(dir ?? '.').absolute.path,
    serviceAccountJsonBase64: serviceAccountJsonBase64,
    skipIfPublished: skipIfPublished,
  );

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
