import 'dart:convert';
import 'dart:io';

import '../quote_shell_argument.dart';

Future<({String bundleId, String ipaDirectory})> readIosBuildSettings({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  String? dir,
}) async {
  final directory = await Directory.systemTemp.createTemp('openci-ios-build-');
  final flutterSettings = File.fromUri(
    directory.uri.resolve('flutter-settings'),
  );
  final projectInfo = File.fromUri(directory.uri.resolve('project.json'));
  final bundleIdFile = File.fromUri(directory.uri.resolve('bundle-id'));

  // Flutter has already resolved CLI arguments and the pubspec's default flavor.
  await run(
    "sed -n '/^FLAVOR=/p; /^FLUTTER_BUILD_DIR=/p' "
    'ios/Flutter/Generated.xcconfig > ${quoteShellArgument(flutterSettings.path)}',
    workingDirectory: dir,
  );
  final settings = <String, String>{};
  for (final line in await flutterSettings.readAsLines()) {
    final separator = line.indexOf('=');
    if (separator != -1) {
      settings[line.substring(0, separator)] = line.substring(separator + 1);
    }
  }
  final buildDirectory = settings['FLUTTER_BUILD_DIR'];
  if (buildDirectory == null || buildDirectory.isEmpty) {
    throw StateError('Flutter did not generate an iOS build directory.');
  }

  await run(
    'xcodebuild -list -json -project ios/*.xcodeproj '
    '> ${quoteShellArgument(projectInfo.path)}',
    workingDirectory: dir,
  );
  final info = jsonDecode(await projectInfo.readAsString());
  final String projectName;
  final List<String> configurations;
  if (info case {
    'project': {'name': String name, 'configurations': List<Object?> values},
  } when values.every((value) => value is String)) {
    projectName = name;
    configurations = values.cast<String>();
  } else {
    throw const FormatException(
      'Could not read the iOS project configurations.',
    );
  }

  final configuration = _releaseConfiguration(
    configurations,
    settings['FLAVOR'],
  );
  await run(
    [
      'xcode-project detect-bundle-id',
      '--project ${quoteShellArgument('ios/$projectName.xcodeproj')}',
      '--config ${quoteShellArgument(configuration)}',
      '--log-stream stderr',
      '> ${quoteShellArgument(bundleIdFile.path)}',
    ].join(' '),
    workingDirectory: dir,
  );
  final bundleId = (await bundleIdFile.readAsString()).trim();
  if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(bundleId)) {
    throw StateError('Could not detect the iOS bundle ID.');
  }
  return (bundleId: bundleId, ipaDirectory: '$buildDirectory/ios/ipa');
}

String _releaseConfiguration(List<String> configurations, String? flavor) {
  final expected = flavor == null || flavor.isEmpty
      ? 'release'
      : 'release-${flavor.toLowerCase()}';
  for (final configuration in configurations) {
    if (configuration.toLowerCase() == expected) return configuration;
  }

  // Match Flutter's fallback for projects with custom configuration names.
  if (flavor != null && flavor.isNotEmpty) {
    final matches = configurations.where((configuration) {
      final name = configuration.toLowerCase();
      return name.contains('release') && name.contains(flavor.toLowerCase());
    }).toList();
    if (matches.length == 1) return matches.single;
    if (matches.isEmpty) {
      for (final configuration in configurations) {
        if (configuration.toLowerCase() == 'release') return configuration;
      }
    }
  }
  throw StateError('Could not select an iOS release configuration.');
}
