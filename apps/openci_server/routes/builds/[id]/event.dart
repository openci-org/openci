import 'dart:async';
import 'dart:convert';
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
    final payload = _buildEventPayload(driftJob);

    return Response.json(
      body: {
        'success': true,
        'eventPayload': payload,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.toString()},
    );
  }
}

String _buildEventPayload(DriftBuildJob buildJob) {
  final owner = buildJob.owner;
  final repo = buildJob.repo;
  final fullName = '$owner/$repo';
  final commitSha = buildJob.commitSha ?? '';
  final branch = buildJob.branch ?? '';
  final pullRequestNumber = buildJob.pullRequestNumber;

  final repository = <String, dynamic>{
    'name': repo,
    'full_name': fullName,
    'owner': {'login': owner, 'name': owner},
    'default_branch': branch,
  };

  if (pullRequestNumber != null) {
    return jsonEncode({
      'action': 'opened',
      'number': pullRequestNumber,
      'pull_request': {
        'number': pullRequestNumber,
        'head': {
          'ref': branch,
          'sha': commitSha,
          'repo': {'full_name': fullName, 'name': repo},
        },
        'base': {
          'ref': '',
          'sha': '',
          'repo': {'full_name': fullName, 'name': repo},
        },
      },
      'repository': repository,
      'sender': {'login': owner},
    });
  }

  return jsonEncode({
    'ref': branch.isEmpty ? '' : 'refs/heads/$branch',
    'before': '',
    'after': commitSha,
    'head_commit': {'id': commitSha},
    'repository': repository,
    'pusher': {'name': owner},
    'sender': {'login': owner},
  });
}
