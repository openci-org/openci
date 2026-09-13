import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'orchard/execute_command.dart';
import 'orchard/orchard_api_client.dart';
import 'orchard/write_file.dart';

Future<int> runWorkflow({
  required OrchardApiClient api,
  required http.Client lokiClient,
  required String lokiUrl,
  required String vmLokiUrl,
  required String vmName,
  required BuildJob job,
  required String runId,
  required String secretsContent,
  required void Function(Object error, StackTrace stackTrace) onLogError,
  String workspacePath = '/tmp/workspace',
  String vmHomePath = '/Users/admin',
}) async {
  final workspace = workspacePath.replaceFirst(RegExp(r'/+$'), '');
  final vmHome = vmHomePath.replaceFirst(RegExp(r'/+$'), '');
  if ([
    workspace,
    vmHome,
  ].any((path) => !path.startsWith('/') || path.contains('\u0000'))) {
    throw ArgumentError(
      'workspacePath and vmHomePath must be absolute paths without NUL.',
    );
  }
  final fileName = job.workflowFileName;
  if (fileName.isEmpty ||
      fileName.startsWith('/') ||
      fileName.split('/').contains('..') ||
      fileName.contains('\u0000')) {
    throw ArgumentError(
      'workflowFileName must be a relative path within genuine_ci.',
    );
  }
  if ([
    runId,
    job.id,
    vmLokiUrl,
  ].any((value) => value.isEmpty || value.contains('\u0000'))) {
    throw ArgumentError(
      'Run ID, job ID, and VM Loki URL must not be empty or contain NUL.',
    );
  }
  final assignments = secretsContent
      .replaceAll('\r\n', '\n')
      .split('\n')
      .where((line) => line.isNotEmpty)
      .toList();
  if (secretsContent.contains('\u0000') ||
      assignments.any(
        (line) => !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*=').hasMatch(line),
      )) {
    throw ArgumentError(
      'secretsContent must contain NAME=value lines without NUL.',
    );
  }

  final envPath = '$workspace/.env';
  final scriptPath = '$workspace.workflow.sh';
  final script =
      '''
set -e
trap ${_shellQuote('/bin/rm -f -- ${_shellQuote(scriptPath)} ${_shellQuote(envPath)}')} 0
cd ${_shellQuote(workspace)}
${assignments.map((line) => 'export ${_shellQuote(line)}').join('\n')}
export HOME=${_shellQuote(vmHome)}
export FLUTTER_ROOT=${_shellQuote('$vmHome/fvm/default')}
export PATH="\$FLUTTER_ROOT/bin:\$HOME/.pub-cache/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"
export GENUINE_CI_RUN_ID=${_shellQuote(runId)}
export GENUINE_CI_BUILD_JOB_ID=${_shellQuote(job.id)}
export LOKI_URL=${_shellQuote(vmLokiUrl)}
flutter pub get
flutter pub run ${_shellQuote('genuine_ci/$fileName')}
''';
  await writeFile(
    api: api,
    vmName: vmName,
    filePath: envPath,
    content: assignments.join('\n'),
    mode: '600',
  );
  await writeFile(
    api: api,
    vmName: vmName,
    filePath: scriptPath,
    content: script,
    mode: '600',
  );
  return executeCommand(
    api: api,
    lokiClient: lokiClient,
    lokiUrl: lokiUrl,
    vmName: vmName,
    command: '/bin/sh ${_shellQuote(scriptPath)}',
    runId: runId,
    jobId: job.id,
    stepId: 'run_workflow',
    onLogError: onLogError,
  );
}

String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
