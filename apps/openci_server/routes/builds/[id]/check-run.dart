import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String id) async {
  try {
    final driftJob = context.read<DriftBuildJob>();

    final Map<String, dynamic> payload;
    try {
      final body = await context.request.body();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Body must be a JSON object');
      }
      payload = decoded;
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid JSON: $e'},
      );
    }

    final runStatus = payload['runStatus'] as String?;
    if (runStatus == null || runStatus.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'runStatus is required'},
      );
    }

    final conclusion = payload['conclusion'] as String?;

    final installationIdStr = driftJob.installationId;
    final checkRunIdStr = driftJob.checkRunId;

    if (installationIdStr == null ||
        installationIdStr.isEmpty ||
        checkRunIdStr == null ||
        checkRunIdStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'installationId or checkRunId is missing for this build job',
        },
      );
    }

    await GitHubService.updateGitHubCheckRun(
      owner: driftJob.owner,
      repo: driftJob.repo,
      checkRunIdStr: checkRunIdStr,
      installationIdStr: installationIdStr,
      githubApiBaseUrlStr: driftJob.githubApiBaseUrl,
      runStatus: runStatus,
      conclusion: conclusion,
    );

    return Response.json(body: {'success': true});
  } on StateError catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.message},
    );
  } on HttpException catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.message},
    );
  } catch (e, s) {
    stderr.writeln('Failed to update check run for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Internal server error'},
    );
  }
}
