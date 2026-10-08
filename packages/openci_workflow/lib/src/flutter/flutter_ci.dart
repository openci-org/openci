import '../app_store_connect_keys.dart';
import '../time_zone.dart';
import 'ios_distribution_method.dart';

class FlutterCI {
  const FlutterCI(this._run);

  final Future<void> Function(String command, {String? workingDirectory}) _run;

  Future<void> staticAnalysis({
    String? dir,
    // See https://github.com/dart-lang/tools/issues/249
    bool suppressAnalytics = true,
    bool fatalInfo = false,
    bool noFatalInfos = false,
    bool noFatalWarnings = false,
  }) => _run(
    [
      'flutter analyze',
      if (suppressAnalytics) '--suppress-analytics',
      if (fatalInfo) '--fatal-infos',
      if (noFatalInfos) '--no-fatal-infos',
      if (noFatalWarnings) '--no-fatal-warnings',
    ].join(' '),
    workingDirectory: dir,
  );

  /// Runs Flutter tests with an optional time zone and tag exclusion.
  ///
  /// Sets `TZ` to [tz]'s identifier for this command and passes [excludeTags]
  /// as Flutter's `--exclude-tags` selector when provided. Omitting [tz]
  /// preserves the inherited time zone.
  Future<void> unitTests({String? dir, TimeZone? tz, String? excludeTags}) =>
      _run(
        [
          if (tz != null) 'TZ=${_quoteShellArgument(tz.value)}',
          'flutter test',
          if (excludeTags != null)
            '--exclude-tags ${_quoteShellArgument(excludeTags)}',
        ].join(' '),
        workingDirectory: dir,
      );

  Future<void> buildApk({String? dir, String? flavor}) => _run(
    [
      'flutter build apk',
      if (flavor != null) '--flavor ${_quoteShellArgument(flavor)}',
    ].join(' '),
    workingDirectory: dir,
  );

  Future<void> buildAab({String? dir, String? flavor}) => _run(
    [
      'flutter build appbundle',
      if (flavor != null) '--flavor ${_quoteShellArgument(flavor)}',
    ].join(' '),
    workingDirectory: dir,
  );

  Future<void> buildIpa({
    required IosDistributionMethod distributionMethod,
    required AppStoreConnectKeys ascKeys,
    required String certificatePrivateKey,
    String? dir,
    String? flavor,
    List<String> additionalArguments = const [],
  }) async {
    throw UnimplementedError('FlutterCI.buildIpa is not implemented yet.');
  }
}

String _quoteShellArgument(String value) =>
    "'${value.replaceAll("'", r"'\''")}'";
