import 'dart:convert';
import 'dart:io';

import '../../quote_shell_argument.dart';

typedef TestFlightIpa = ({
  File file,
  String bundleId,
  String version,
  String buildNumber,
});

Future<TestFlightIpa> readTestFlightIpa({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String ipaPath,
  String? dir,
}) async {
  final temporary = await Directory.systemTemp.createTemp('openci-testflight-');
  try {
    var ipa = File(ipaPath);
    if (!ipa.isAbsolute) {
      final cwd = File.fromUri(temporary.uri.resolve('cwd'));
      await run(
        r'''printf '%s' "$PWD" > ''' + quoteShellArgument(cwd.path),
        workingDirectory: dir,
      );
      ipa = File('${await cwd.readAsString()}/$ipaPath');
    }
    if (await ipa.length() == 0) {
      throw ArgumentError.value(ipaPath, 'ipaPath', 'Must not be empty.');
    }
    final entries = File.fromUri(temporary.uri.resolve('entries'));
    final plist = File.fromUri(temporary.uri.resolve('Info.plist'));
    final metadata = File.fromUri(temporary.uri.resolve('metadata.json'));
    await run(
      'unzip -Z1 ${quoteShellArgument(ipa.path)} '
      '> ${quoteShellArgument(entries.path)}',
      workingDirectory: dir,
    );
    final configs = (await entries.readAsLines())
        .where(RegExp(r'^Payload/[^/]+\.app/Info\.plist$').hasMatch)
        .toList();
    if (configs.length != 1) {
      throw StateError('Expected one app-level Info.plist in the IPA.');
    }
    // unzip interprets entry names as patterns, even when shell-quoted.
    final entry = configs.single.replaceAllMapped(
      RegExp(r'[*?\[\\]'),
      (match) => '\\${match[0]}',
    );
    await run(
      'unzip -p ${quoteShellArgument(ipa.path)} ${quoteShellArgument(entry)} '
      '> ${quoteShellArgument(plist.path)}',
      workingDirectory: dir,
    );
    final data = <String, Object?>{};
    try {
      // Other plist fields may contain data or dates, which JSON cannot encode.
      for (final key in [
        'CFBundleIdentifier',
        'CFBundleShortVersionString',
        'CFBundleVersion',
      ]) {
        await run(
          'plutil -extract $key raw -expect string '
          '-o ${quoteShellArgument(metadata.path)} '
          '${quoteShellArgument(plist.path)}',
          workingDirectory: dir,
        );
        data[key] = await metadata.readAsString();
      }
      await run(
        'plutil -extract CFBundleSupportedPlatforms json '
        '-o ${quoteShellArgument(metadata.path)} '
        '${quoteShellArgument(plist.path)}',
        workingDirectory: dir,
      );
      data['CFBundleSupportedPlatforms'] = jsonDecode(
        await metadata.readAsString(),
      );
    } catch (_) {
      throw StateError('Could not read the IPA app metadata using plutil.');
    }
    if (data
        case {
          'CFBundleIdentifier': String bundleId,
          'CFBundleShortVersionString': String version,
          'CFBundleVersion': String buildNumber,
          'CFBundleSupportedPlatforms': ['iPhoneOS'],
        }
        when bundleId.trim().isNotEmpty &&
            version.trim().isNotEmpty &&
            buildNumber.trim().isNotEmpty) {
      return (
        file: ipa,
        bundleId: bundleId,
        version: version,
        buildNumber: buildNumber,
      );
    }
    throw StateError(
      'The IPA must contain an iOS device app with a Bundle ID, version, '
      'and build number.',
    );
  } finally {
    await temporary.delete(recursive: true);
  }
}
