import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

enum DashboardPatchMode {
  dryRun('--dry-run'),
  publish('--track=stable');

  const DashboardPatchMode(this.shorebirdArgument);

  final String shorebirdArgument;

  static DashboardPatchMode? forContext(WorkflowContext context) =>
      switch (context) {
        PullRequestContext() => dryRun,
        PushContext(branch: 'develop') => publish,
        PushContext() || LocalContext() => null,
      };
}

Future<String?> findDashboardPatchRelease({
  required String directory,
  required String platform,
}) async {
  final pubspec = loadYaml(
    await File('$directory/pubspec.yaml').readAsString(),
  );
  final version = Version.parse(pubspec['version'] as String);
  // The store workflows assign their own build numbers to this app version.
  final versionName = version.toString().split('+').first;
  final arguments = ['releases', 'list', '--platform', platform, '--json'];
  final result = await Process.run(
    'shorebird',
    arguments,
    workingDirectory: directory,
    environment: const {'CI': 'true'},
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'shorebird',
      arguments,
      '${result.stdout}\n${result.stderr}'.trim(),
      result.exitCode,
    );
  }
  final release = selectDashboardPatchRelease(
    result.stdout as String,
    platform: platform,
    versionName: versionName,
  );
  if (release == null) {
    stdout.writeln('Waiting for the Dashboard $versionName $platform release.');
  }
  return release;
}

String? selectDashboardPatchRelease(
  String output, {
  required String platform,
  required String versionName,
}) {
  final releases = switch (jsonDecode(output)) {
    {'status': 'success', 'data': {'releases': final List<dynamic> values}} =>
      values,
    _ => throw const FormatException('Invalid Shorebird release list.'),
  };
  Version? latest;
  for (final release in releases) {
    final name = release['version'] as String;
    final statuses = release['platform_statuses'] as Map<String, dynamic>;
    if (name.split('+').first != versionName) continue;
    final status = statuses[platform];
    if (status == null || status == 'draft') continue;
    if (status != 'active') {
      throw FormatException('Unknown Shorebird release status: $status');
    }
    final candidate = Version.parse(name);
    if (latest == null || candidate > latest) latest = candidate;
  }
  return latest?.toString();
}
