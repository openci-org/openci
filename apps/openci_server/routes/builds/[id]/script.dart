import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final driftJob = context.read<DriftBuildJob>();
    final script = _buildBuildScript(driftJob);

    return Response.json(
      body: {
        'success': true,
        'script': script,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.toString()},
    );
  }
}

String _buildBuildScript(DriftBuildJob buildJob) {
  final workflowYaml = buildJob.workflowYaml;
  if (workflowYaml != null && workflowYaml.isNotEmpty) {
    final runs = <String>[];
    final runMatches = RegExp(
      r'run:\s*\|?\s*\n?([^\n]+(?:\n[ \t]+[^\n]+)*)',
    ).allMatches(workflowYaml);
    for (final match in runMatches) {
      final scriptStr = match.group(1)?.trim();
      if (scriptStr != null && scriptStr.isNotEmpty) {
        runs.add(scriptStr);
      }
    }
    if (runs.isNotEmpty) {
      return runs.join('\n\n');
    }
  }

  final customScript = buildJob.customScript;
  if (customScript != null && customScript.isNotEmpty) {
    return customScript;
  }

  final eventType = buildJob.pullRequestNumber != null
      ? 'pull_request'
      : 'push';
  final jobKey = buildJob.workflowJobKey ?? buildJob.jobKey;
  final jobFlag = jobKey != null ? '-j $jobKey ' : '';

  final matrixArgs = <String>[];
  final buildJobMatrix = buildJob.matrix;
  if (buildJobMatrix != null && buildJobMatrix.isNotEmpty) {
    for (final entry in buildJobMatrix.entries) {
      matrixArgs.add('--matrix "${entry.key}:${entry.value}"');
    }
  }
  final matrixFlag = matrixArgs.isNotEmpty ? '${matrixArgs.join(' ')} ' : '';

  final workflowFileName = buildJob.workflowFileName;
  if (workflowFileName == null || workflowFileName.isEmpty) {
    throw ArgumentError('workflowFileName is required.');
  }

  final actScript = [
    'set -e',
    'export HOME=/Users/admin',
    'export PATH="/Users/admin/flutter/bin:/opt/homebrew/bin:\$PATH"',
    'cd ${buildJob.repo}',
    'act $eventType -W .openci/$workflowFileName '
        '$jobFlag'
        '$matrixFlag'
        '-P macos-latest=-self-hosted '
        '-P macos-14=-self-hosted '
        '-P macos-15=-self-hosted '
        '-P ubuntu-latest=-self-hosted '
        '-e /tmp/openci-event.json '
        '--secret-file /tmp/openci-secrets',
  ].join('\n');

  return actScript;
}
