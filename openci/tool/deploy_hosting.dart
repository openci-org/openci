import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

const project = 'openci-b1b91';
const previewBudget = 20;
const channelPrefix = 'openci-ci-pr-';

enum Site {
  website('openci-b1b91', 'website', 'apps/website', 'build/hosting'),
  dashboard('dashboard-openci', 'dashboard-openci', 'firebase', 'build/web');

  const Site(this.id, this.target, this.configDir, this.buildDir);
  final String id;
  final String target;
  final String configDir;
  final String buildDir;
}

/// Runs the pinned Firebase CLI inside the same Node environment on every VM.
Future<void> publish(OpenCI ci, Site site, Secret credentials) async {
  if (!Platform.environment.containsKey('OPENCI_RUN_ID')) return;
  if (credentials.value.isEmpty) throw StateError('Missing ${credentials.key}');
  final push = ci.ciTriggers.singleWhere(
    (trigger) => trigger.branch == 'develop',
  );
  final process = await Process.start(
    'bash',
    [
      'openci/tool/with_node.sh',
      'npm',
      'exec',
      '--yes',
      '--package=firebase-tools@15.34.2',
      '--',
      'dart',
      'run',
      'openci/tool/deploy_hosting.dart',
      site.name,
      credentials.key,
      ...push.paths!,
    ],
    workingDirectory: ci.workspacePath,
    mode: ProcessStartMode.inheritStdio,
  );
  if (await process.exitCode != 0) {
    throw StateError('Hosting deploy failed for ${site.id}.');
  }
}

Future<ProcessResult> git(List<String> args) async {
  final result = await Process.run('git', args);
  if (result.exitCode != 0) throw StateError('git ${args.first} failed.');
  return result;
}

// OpenCI checks out GitHub's test merge commit with depth=1. Read the raw
// parents so a refreshed merge ref after a base-only update can still match.
String? previewChannel(String commit, String rawCommit, String remoteRefs) {
  final parents = rawCommit
      .split('\n\n')
      .first
      .split('\n')
      .where((line) => line.startsWith('parent '))
      .toList();
  if (parents.length != 2) throw StateError('Expected a PR test merge commit.');
  final head = parents.last.substring('parent '.length);
  final merges = <String, String>{};
  final heads = <String, String>{};
  final pattern = RegExp(
    r'^([0-9a-f]+)\s+refs/pull/([1-9][0-9]*)/(merge|head)$',
  );
  for (final line in const LineSplitter().convert(remoteRefs)) {
    final ref = pattern.firstMatch(line);
    if (ref != null) (ref[3] == 'merge' ? merges : heads)[ref[2]!] = ref[1]!;
  }
  final exact = merges.keys.where((id) => merges[id] == commit);
  final matches = exact.isNotEmpty
      ? exact
      : merges.keys.where((id) => heads[id] == head);
  if (matches.isEmpty) return null;
  if (matches.length != 1) throw StateError('Several PRs match the checkout.');
  return '$channelPrefix${matches.single}';
}

List<String> channelsToRemove(List<dynamic> channels, String desired) {
  final previews = {
    for (final channel in channels)
      (channel['name'] as String).split('/').last: channel,
  }..remove('live');
  final needed =
      previews.length + (previews.containsKey(desired) ? 0 : 1) - previewBudget;
  if (needed <= 0) return [];
  final managed = RegExp(r'^openci-ci-pr-[1-9][0-9]*$');
  final owned =
      previews.keys
          .where(
            (id) =>
                id != desired &&
                managed.hasMatch(id) &&
                previews[id]['expireTime'] != null,
          )
          .toList()
        ..sort((a, b) {
          final oldest = DateTime.parse(
            previews[a]['expireTime'] as String,
          ).compareTo(DateTime.parse(previews[b]['expireTime'] as String));
          return oldest != 0 ? oldest : a.compareTo(b);
        });
  if (owned.length < needed) {
    throw StateError(
      'The preview budget is occupied by other channels on this site.',
    );
  }
  return owned.take(needed).toList();
}

Future<void> main(List<String> args) async {
  final site = Site.values.byName(args[0]);
  final prOutput = Platform.environment['OPENCI_PR_QR_OUTPUT'];
  if (Platform.environment['OPENCI_RUN_ID'] == null || prOutput == null) {
    throw StateError('Hosting publishing requires an OpenCI event.');
  }
  String? channel;
  if (prOutput.isNotEmpty) {
    final commit = (await git(['rev-parse', 'HEAD'])).stdout.toString().trim();
    final rawCommit = (await git([
      'cat-file',
      'commit',
      'HEAD',
    ])).stdout.toString();
    final refs = (await git([
      'ls-remote',
      'origin',
      'refs/pull/*/head',
      'refs/pull/*/merge',
    ])).stdout.toString();
    channel = previewChannel(commit, rawCommit, refs);
    if (channel == null) {
      stdout.writeln(
        'The PR checkout is no longer current. Skipping publication.',
      );
      return;
    }
  } else {
    await git([
      'fetch',
      '--no-tags',
      '--depth=1',
      'origin',
      'refs/heads/develop',
    ]);
    final diff = await Process.run('git', [
      'diff',
      '--quiet',
      'HEAD',
      'FETCH_HEAD',
      '--',
      for (final path in args.skip(2)) ':(glob)$path',
    ]);
    if (diff.exitCode == 1) {
      stdout.writeln(
        'Newer site inputs are already on develop. Skipping publication.',
      );
      return;
    }
    if (diff.exitCode != 0) {
      throw StateError('Could not verify the develop checkout.');
    }
  }

  final temp = await Directory.systemTemp.createTemp('openci-hosting-');
  try {
    final config = jsonDecode(
      await File('${site.configDir}/firebase.json').readAsString(),
    )['hosting'];
    final hosting = Map<String, dynamic>.from(
      config is List
          ? config.singleWhere((item) => item['site'] == site.id)
          : config,
    );
    // The CI build already ran the website's predeploy hook.
    hosting.remove('predeploy');
    hosting['public'] = 'public';
    final output = Directory('apps/${site.name}/${site.buildDir}').absolute;
    if (!File('${output.path}/index.html').existsSync()) {
      throw StateError('Missing Hosting build for ${site.id}.');
    }
    await Link('${temp.path}/public').create(output.path);
    await File(
      '${temp.path}/firebase.json',
    ).writeAsString(jsonEncode({'hosting': hosting}));
    await File(
      '${site.configDir}/.firebaserc',
    ).copy('${temp.path}/.firebaserc');

    final key = File('${temp.path}/service-account.json');
    await key.create();
    if ((await Process.run('chmod', ['600', key.path])).exitCode != 0) {
      throw StateError('Could not protect the credential file.');
    }
    try {
      final bytes = base64Decode(Platform.environment[args[1]]!);
      if (jsonDecode(utf8.decode(bytes)) case {
        'type': 'service_account',
        'client_email': String _,
        'private_key': String _,
      }) {
        await key.writeAsBytes(bytes);
      } else {
        throw const FormatException();
      }
    } on FormatException {
      throw StateError('Invalid Base64 service account JSON in ${args[1]}.');
    }
    final environment = Map.of(Platform.environment)
      ..remove(args[1])
      ..remove('FIREBASE_TOKEN')
      ..remove('DEBUG')
      ..['GOOGLE_APPLICATION_CREDENTIALS'] = key.path
      ..['XDG_CONFIG_HOME'] = temp.path
      ..['CI'] = 'true';

    Future<dynamic> firebase(List<String> arguments) async {
      final result = await Process.run(
        'firebase',
        [...arguments, '--project', project, '--non-interactive', '--json'],
        workingDirectory: temp.path,
        environment: environment,
        includeParentEnvironment: false,
      );
      final Map response;
      try {
        response = jsonDecode(result.stdout as String) as Map;
      } on FormatException {
        throw StateError(
          'Firebase ${arguments.first} returned invalid output (exit ${result.exitCode}).',
        );
      }
      if (result.exitCode != 0 || response['status'] != 'success') {
        throw HostingCommandError(
          'Firebase ${arguments.first} on ${site.id}: ${response['error'] ?? 'failed'}',
        );
      }
      return response['result'];
    }

    final previewId = channel;
    if (previewId == null) {
      await firebase(['deploy', '--only', 'hosting:${site.target}']);
      stdout.writeln('Published ${site.id} to its live channel.');
      return;
    }
    Future<void> makeRoom() async {
      final data = await firebase(['hosting:channel:list', '--site', site.id]);
      for (final id in channelsToRemove(data['channels'] as List, previewId)) {
        try {
          await firebase([
            'hosting:channel:delete',
            id,
            '--site',
            site.id,
            '--force',
          ]);
        } on HostingCommandError catch (error) {
          // Another PR may have just removed the same oldest channel.
          if (!error.message.contains('404')) rethrow;
        }
      }
    }

    Future<dynamic> publishPreview() async {
      await makeRoom();
      return firebase([
        'hosting:channel:deploy',
        previewId,
        '--only',
        site.target,
        '--expires',
        '1h',
        '--no-authorized-domains',
      ]);
    }

    dynamic result;
    try {
      result = await publishPreview();
    } on HostingCommandError catch (error) {
      // A concurrent deployment may have created this channel or filled the site.
      if (!RegExp(
        r'409|429|quota|maximum number of channels|resource.exhausted',
        caseSensitive: false,
      ).hasMatch(error.message)) {
        rethrow;
      }
      result = await publishPreview();
    }
    final preview = result[site.target];
    final url = Uri.parse(preview['url'] as String);
    if (preview['site'] != site.id ||
        url.scheme != 'https' ||
        !url.host.endsWith('.web.app')) {
      throw StateError('Unexpected preview response for ${site.id}.');
    }
    await makeRoom(); // Account for channels admitted by concurrent PRs.
    stdout.writeln('Preview $url expires at ${preview['expireTime']}.');
    await const PullRequestCI().postQrCode(url: url, lang: PostQrCodeLang.ja);
  } finally {
    await temp.delete(recursive: true);
  }
}

class HostingCommandError implements Exception {
  HostingCommandError(this.message);
  final String message;

  @override
  String toString() => message;
}
