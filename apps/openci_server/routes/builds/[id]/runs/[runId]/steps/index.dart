import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, runId),
    HttpMethod.post => _post(context, id, runId),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(
  RequestContext context,
  String id,
  String runId,
) async {
  try {
    final db = context.read<AppDatabase>();
    final driftSteps = await db.buildJobDao.getBuildSteps(runId);

    final steps = driftSteps.map((s) {
      return BuildStep(
        id: s.id,
        runId: s.runId,
        name: s.name,
        status: s.status,
        durationMs: s.durationMs,
        stepOrder: s.stepOrder,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      );
    }).toList();

    return Response.json(body: steps.map((s) => s.toJson()).toList());
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read steps for run $runId',
    );
  }
}

Future<Response> _post(
  RequestContext context,
  String id,
  String runId,
) async {
  try {
    final db = context.read<AppDatabase>();
    final payload = await context.jsonBody();

    final step = BuildStep.fromJson(payload);

    final driftStep = DriftBuildStep(
      id: step.id,
      runId: step.runId,
      name: step.name,
      status: step.status,
      durationMs: step.durationMs,
      stepOrder: step.stepOrder,
      createdAt: step.createdAt,
      updatedAt: step.updatedAt,
    );

    await db.buildJobDao.insertBuildStep(driftStep);
    return Response.json(body: {'success': true});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to create/update step for run $runId',
    );
  }
}
