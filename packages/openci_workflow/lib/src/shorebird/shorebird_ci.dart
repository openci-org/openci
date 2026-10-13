import 'dart:io';

import '../app_store_connect_keys.dart';
import '../flutter/ios_distribution_method.dart';
import '../ios_signing/apply_ios_provisioning_profiles.dart';
import '../ios_signing/fetch_ios_signing_files.dart';
import '../ios_signing/import_ios_signing_certificates.dart';
import '../ios_signing/initialize_ios_keychain.dart';
import '../ios_signing/write_ios_signing_secrets.dart';
import '../quote_shell_argument.dart';

/// Shorebird release commands for a workflow.
class ShorebirdCI {
  const ShorebirdCI(this._run);

  final Future<void> Function(String command, {String? workingDirectory}) _run;

  Future<String> releaseAab({
    required String flutterVersion,
    String? dir,
    String? flavor,
    Map<String, String> dartDefines = const {},
    List<String> additionalArguments = const [],
    bool dryRun = false,
  }) async {
    if (flutterVersion.trim().isEmpty) {
      throw ArgumentError.value(
        flutterVersion,
        'flutterVersion',
        'Must specify a Shorebird Flutter version or revision.',
      );
    }
    for (final argument in additionalArguments) {
      final option = argument.split('=').first;
      if (const {
        '--',
        '--artifact',
        '--debug',
        '--profile',
        '--release',
        '--no-release',
        '--flavor',
      }.contains(option)) {
        throw ArgumentError.value(
          option,
          'additionalArguments',
          'Artifact type, flavor, and build mode are managed by releaseAab.',
        );
      }
    }

    await _run(
      '''
set -e
if [ -z "\${SHOREBIRD_TOKEN:-}" ]; then
  printf '%s\\n' 'SHOREBIRD_TOKEN is required for releaseAab.' >&2
  exit 1
fi
if ! command -v shorebird >/dev/null 2>&1; then
  printf '%s\\n' 'Shorebird CLI must be installed and on PATH.' >&2
  exit 1
fi
if [ ! -f shorebird.yaml ]; then
  printf '%s\\n' 'Missing shorebird.yaml; initialize this app with shorebird init.' >&2
  exit 1
fi
''',
      workingDirectory: dir,
    );

    final temporary = await Directory.systemTemp.createTemp(
      'openci-shorebird-aab-',
    );
    final artifacts = File.fromUri(temporary.uri.resolve('artifacts'));
    try {
      await _run(
        [
          'CI=true shorebird release android --artifact aab',
          '--flutter-version ${quoteShellArgument(flutterVersion)}',
          if (flavor != null) '--flavor ${quoteShellArgument(flavor)}',
          if (dryRun) '--dry-run',
          if (dartDefines.isNotEmpty || additionalArguments.isNotEmpty) '--',
          for (final entry in dartDefines.entries)
            quoteShellArgument('--dart-define=${entry.key}=${entry.value}'),
          ...additionalArguments.map(quoteShellArgument),
        ].join(' '),
        workingDirectory: dir,
      );
      final variant = flavor == null ? 'release' : '${flavor}Release';
      await _run(
        '''
set -e
aab_directory="\$PWD/"${quoteShellArgument('build/app/outputs/bundle/$variant')}
if [ -d "\$aab_directory" ]; then
  find "\$aab_directory" -type f -name '*.aab' -size +0c -print0 > ${quoteShellArgument(artifacts.path)}
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
      if (paths.length != 1) {
        throw StateError(
          'Shorebird did not produce exactly one nonempty AAB '
          'for $variant (found ${paths.length}).',
        );
      }
      return paths.single;
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  Future<String> releaseIos({
    required String bundleId,
    required IosDistributionMethod distributionMethod,
    required AppStoreConnectKeys ascKeys,
    required String certificatePrivateKey,
    required String flutterVersion,
    String? dir,
    String? flavor,
    Map<String, String> dartDefines = const {},
    List<String> additionalArguments = const [],
    bool dryRun = false,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(bundleId)) {
      throw ArgumentError.value(
        bundleId,
        'bundleId',
        'Must specify the iOS app bundle ID for signing.',
      );
    }
    if (flutterVersion.trim().isEmpty) {
      throw ArgumentError.value(
        flutterVersion,
        'flutterVersion',
        'Must specify a Shorebird Flutter version or revision.',
      );
    }
    for (final argument in additionalArguments) {
      final option = argument.split('=').first;
      if (const {
        '--',
        '--export-options-plist',
        '--export-method',
        '--codesign',
        '--no-codesign',
        '--config-only',
        '--debug',
        '--profile',
        '--release',
        '--no-release',
        '--simulator',
        '--flavor',
      }.contains(option)) {
        throw ArgumentError.value(
          option,
          'additionalArguments',
          'Signing, flavor, and build mode are managed by releaseIos.',
        );
      }
    }

    await _run(
      '''
set -e
if [ -z "\${SHOREBIRD_TOKEN:-}" ]; then
  printf '%s\\n' 'SHOREBIRD_TOKEN is required for releaseIos.' >&2
  exit 1
fi
if ! command -v shorebird >/dev/null 2>&1; then
  printf '%s\\n' 'Shorebird CLI must be installed and on PATH.' >&2
  exit 1
fi
if [ ! -f shorebird.yaml ]; then
  printf '%s\\n' 'Missing shorebird.yaml; initialize this app with shorebird init.' >&2
  exit 1
fi
''',
      workingDirectory: dir,
    );
    final credentials = await writeIosSigningSecrets(
      ascKeys: ascKeys,
      certificatePrivateKey: certificatePrivateKey,
    );
    final flutterArguments = [
      for (final entry in dartDefines.entries)
        '--dart-define=${entry.key}=${entry.value}',
      ...additionalArguments,
    ];
    await initializeIosKeychain(run: _run, dir: dir);
    await fetchIosSigningFiles(
      run: _run,
      credentials: credentials,
      bundleId: bundleId,
      distributionMethod: distributionMethod,
      dir: dir,
    );
    await importIosSigningCertificates(run: _run, dir: dir);
    final exportOptionsPlistPath = await applyIosProvisioningProfiles(
      run: _run,
      distributionMethod: distributionMethod,
      dir: dir,
    );
    await _run(
      'plutil -replace manageAppVersionAndBuildNumber -bool NO '
      '${quoteShellArgument(exportOptionsPlistPath)}',
      workingDirectory: dir,
    );

    final temporary = await Directory.systemTemp.createTemp(
      'openci-shorebird-release-',
    );
    final started = File.fromUri(temporary.uri.resolve('started'));
    final artifacts = File.fromUri(temporary.uri.resolve('artifacts'));
    try {
      await started.writeAsString('');
      await _run(
        [
          'CI=true shorebird release ios',
          '--flutter-version ${quoteShellArgument(flutterVersion)}',
          if (flavor != null) '--flavor ${quoteShellArgument(flavor)}',
          '--export-options-plist ${quoteShellArgument(exportOptionsPlistPath)}',
          if (dryRun) '--dry-run',
          if (flutterArguments.isNotEmpty) '--',
          ...flutterArguments.map(quoteShellArgument),
        ].join(' '),
        workingDirectory: dir,
      );
      // A successful archive or Shorebird upload does not prove IPA export.
      await _run(
        '''
set -e
build_directory=\$(sed -n 's/^FLUTTER_BUILD_DIR=//p' ios/Flutter/Generated.xcconfig)
if [ -z "\$build_directory" ]; then
  printf '%s\\n' 'Shorebird did not generate an iOS build directory.' >&2
  exit 1
fi
ipa_directory="\$build_directory/ios/ipa"
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
      if (paths.length != 1) {
        throw StateError(
          'Shorebird did not export exactly one new, nonempty IPA '
          '(found ${paths.length}).',
        );
      }
      return paths.single;
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
