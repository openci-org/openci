import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'orchard/execute_command.dart';
import 'orchard/orchard_api_client.dart';
import 'orchard/write_file.dart';

Future<void> checkoutRepository({
  required OrchardApiClient api,
  required http.Client lokiClient,
  required String lokiUrl,
  required String vmName,
  required BuildJob job,
  required String token,
  required String runId,
  required void Function(Object error, StackTrace stackTrace) onLogError,
  String workspacePath = '/tmp/workspace',
}) async {
  final baseUrl = Uri.parse(job.githubBaseUrl ?? 'https://github.com');
  if (!['http', 'https'].contains(baseUrl.scheme) ||
      baseUrl.host.isEmpty ||
      baseUrl.userInfo.isNotEmpty ||
      baseUrl.hasQuery ||
      baseUrl.hasFragment) {
    throw ArgumentError(
      'githubBaseUrl must be an HTTP(S) URL without credentials, query, or fragment.',
    );
  }
  if (token.isEmpty) {
    throw ArgumentError('token must not be empty.');
  }
  final workspace = workspacePath.replaceFirst(RegExp(r'/+$'), '');
  if (!workspace.startsWith('/') || workspace.contains('\u0000')) {
    throw ArgumentError('workspacePath must be an absolute path without NUL.');
  }
  final repoUrl = baseUrl
      .replace(
        pathSegments: [
          ...baseUrl.pathSegments.where((segment) => segment.isNotEmpty),
          job.owner,
          '${job.repo}.git',
        ],
      )
      .toString();
  final String fetchTarget;
  if (job.commitSha?.isNotEmpty ?? false) {
    fetchTarget = job.commitSha!;
  } else if (job.pullRequestNumber != null) {
    fetchTarget = 'refs/pull/${job.pullRequestNumber}/head';
  } else {
    fetchTarget = (job.branch?.isNotEmpty ?? false) ? job.branch! : 'develop';
  }
  if (fetchTarget.contains('\u0000')) {
    throw ArgumentError('The checkout ref must not contain NUL.');
  }

  final scriptPath = '$workspace.checkout.sh';
  final authorization = base64Encode(utf8.encode('x-access-token:$token'));
  final script =
      '''
set -e
trap ${_shellQuote('rm -f -- ${_shellQuote(scriptPath)}')} 0
export GIT_TERMINAL_PROMPT=0
mkdir -p ${_shellQuote(workspace)}
cd ${_shellQuote(workspace)}
git init
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin ${_shellQuote(repoUrl)}
else
  git remote add origin ${_shellQuote(repoUrl)}
fi
git -c ${_shellQuote('http.$repoUrl.extraHeader=Authorization: Basic $authorization')} fetch --depth=1 -- origin ${_shellQuote(fetchTarget)}
git checkout --detach FETCH_HEAD
''';
  await writeFile(
    api: api,
    vmName: vmName,
    filePath: scriptPath,
    content: script,
    mode: '600',
  );
  final exitCode = await executeCommand(
    api: api,
    lokiClient: lokiClient,
    lokiUrl: lokiUrl,
    vmName: vmName,
    command: '/bin/sh ${_shellQuote(scriptPath)}',
    runId: runId,
    jobId: job.id,
    stepId: 'checkout',
    onLogError: onLogError,
  );
  if (exitCode != 0) {
    throw StateError('Git checkout failed with exit code $exitCode.');
  }
}

String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
