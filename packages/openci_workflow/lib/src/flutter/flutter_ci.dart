import '../app_store_connect_keys.dart';
import '../ios_signing/apply_ios_provisioning_profiles.dart';
import '../ios_signing/fetch_ios_signing_files.dart';
import '../ios_signing/import_ios_signing_certificates.dart';
import '../ios_signing/initialize_ios_keychain.dart';
import '../ios_signing/write_ios_signing_secrets.dart';
import '../quote_shell_argument.dart';
import '../time_zone.dart';
import 'build_signed_ipa.dart';
import 'deploy_ipa_to_firebase_app_distribution.dart' as firebase;
import 'ios_distribution_method.dart';
import 'read_ios_build_settings.dart';

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
          if (tz != null) 'TZ=${quoteShellArgument(tz.value)}',
          'flutter test',
          if (excludeTags != null)
            '--exclude-tags ${quoteShellArgument(excludeTags)}',
        ].join(' '),
        workingDirectory: dir,
      );

  Future<void> buildApk({
    String? dir,
    String? flavor,
    Map<String, String> dartDefines = const {},
  }) => _run(
    [
      'flutter build apk',
      if (flavor != null) '--flavor ${quoteShellArgument(flavor)}',
      for (final entry in dartDefines.entries)
        '--dart-define ${quoteShellArgument('${entry.key}=${entry.value}')}',
    ].join(' '),
    workingDirectory: dir,
  );

  Future<void> buildAab({
    String? dir,
    String? flavor,
    Map<String, String> dartDefines = const {},
  }) => _run(
    [
      'flutter build appbundle',
      if (flavor != null) '--flavor ${quoteShellArgument(flavor)}',
      for (final entry in dartDefines.entries)
        '--dart-define ${quoteShellArgument('${entry.key}=${entry.value}')}',
    ].join(' '),
    workingDirectory: dir,
  );

  /// Builds a signed IPA and returns its absolute path.
  ///
  /// Throws a [StateError] if Flutter does not export exactly one new,
  /// nonempty IPA. Use [dir] to override the workflow's working directory.
  Future<String> buildIpa({
    required IosDistributionMethod distributionMethod,
    required AppStoreConnectKeys ascKeys,
    required String certificatePrivateKey,
    String? dir,
    String? flavor,
    List<String> additionalArguments = const [],
  }) async {
    for (final argument in additionalArguments) {
      final option = argument.split('=').first;
      if (const {
        '--export-options-plist',
        '--export-method',
        '--no-codesign',
      }.contains(option)) {
        throw ArgumentError.value(
          option,
          'additionalArguments',
          'IPA signing and export options are managed by buildIpa.',
        );
      }
    }
    final credentials = await writeIosSigningSecrets(
      ascKeys: ascKeys,
      certificatePrivateKey: certificatePrivateKey,
    );
    final arguments = [
      if (flavor != null) ...['--flavor', flavor],
      ...additionalArguments,
    ];
    await _run(
      [
        'flutter build ios',
        ...arguments.map(quoteShellArgument),
        '--release --config-only --no-codesign',
      ].join(' '),
      workingDirectory: dir,
    );
    final settings = await readIosBuildSettings(run: _run, dir: dir);
    await initializeIosKeychain(run: _run, dir: dir);
    await fetchIosSigningFiles(
      run: _run,
      credentials: credentials,
      bundleId: settings.bundleId,
      distributionMethod: distributionMethod,
      dir: dir,
    );
    await importIosSigningCertificates(run: _run, dir: dir);
    final exportOptionsPlistPath = await applyIosProvisioningProfiles(
      run: _run,
      distributionMethod: distributionMethod,
      dir: dir,
    );
    return buildSignedIpa(
      run: _run,
      exportOptionsPlistPath: exportOptionsPlistPath,
      ipaDirectory: settings.ipaDirectory,
      arguments: arguments,
      dir: dir,
    );
  }

  /// Uploads an IPA to Firebase App Distribution using the Firebase CLI.
  ///
  /// Reads the Firebase App ID from the IPA's `GoogleService-Info.plist`
  /// unless [appId] is provided. Requires `firebase` on `PATH`; automatic
  /// App ID detection also requires macOS `unzip` and `plutil`.
  ///
  /// Decodes [serviceAccountJsonBase64] into a private temporary file for
  /// authentication and removes it after the upload. The service account needs
  /// the Firebase App Distribution Admin role on the target Firebase project.
  /// Relative paths are resolved in the workflow directory or [dir]. When
  /// [groups] and [testers] are empty, only uploads the release.
  Future<void> deployIpaToFirebaseAppDistribution({
    required String ipaPath,
    required String serviceAccountJsonBase64,
    String? appId,
    List<String> groups = const [],
    List<String> testers = const [],
    String? releaseNotes,
    String? dir,
  }) => firebase.deployIpaToFirebaseAppDistribution(
    run: _run,
    ipaPath: ipaPath,
    serviceAccountJsonBase64: serviceAccountJsonBase64,
    appId: appId,
    groups: groups,
    testers: testers,
    releaseNotes: releaseNotes,
    dir: dir,
  );
}
