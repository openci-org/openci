import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

Future<void> main(List<String> arguments) async {
  final ci = await OpenCI.init(workflowName: 'Context probe', ciTriggers: []);
  if (arguments.contains('init-only')) {
    stdout.writeln('initialized');
    return;
  }
  try {
    final context = ci.context;
    if (!identical(context, ci.context)) throw StateError('Context changed');
    stdout.writeln(
      jsonEncode({
        if (context is CIContext) ...{
          'repository': {
            'owner': context.repository.owner,
            'name': context.repository.name,
            'githubBaseUrl': context.repository.githubBaseUrl.toString(),
          },
          'jobId': context.jobId,
          'runId': context.runId,
          'runNumber': context.runNumber,
          'checkoutSha': context.checkoutSha,
        },
        ...switch (context) {
          LocalContext() => {'event': 'local'},
          PushContext() => {
            'event': 'push',
            'branch': context.branch,
            'commitSha': context.commitSha,
          },
          PullRequestContext() => {
            'event': 'pull_request',
            'number': context.number,
            'headBranch': context.headBranch,
            'baseBranch': context.baseBranch,
            'headSha': context.headSha,
            'baseSha': context.baseSha,
          },
        },
      }),
    );
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}
