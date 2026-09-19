import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:genuineci_server/auth/internal_api_key_validator.dart';
import 'package:genuineci_server/build_job/build_job_mapper.dart';
import 'package:genuineci_server/database.dart';
import 'package:genuineci_server/request/error_handler.dart';
import 'package:genuineci_server/request/request_extension.dart';
import 'package:meta/meta.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context) =>
    handleRequest(context, const InternalApiKeyValidator());

@visibleForTesting
FutureOr<Response> handleRequest(
  RequestContext context,
  InternalApiKeyValidator validator,
) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, validator),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(
  RequestContext context,
  InternalApiKeyValidator validator,
) async {
  try {
    if (validator.isValid(context) == false) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final Map<String, dynamic> payload;
    try {
      payload = await context.jsonBody();
    } on BadRequestException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

    final claimRequest = ClaimJobRequest.fromJson(payload);

    final db = context.read<AppDatabase>();
    final driftJob = await db.buildJobDao.claimNextJob(
      vmName: claimRequest.vmName,
      workerHost: claimRequest.workerHost,
      maxConcurrentJobs: claimRequest.maxConcurrentJobs,
    );
    if (driftJob == null) {
      return Response.json(body: {'job': null});
    }

    return Response.json(body: {'job': driftJob.toShared().toJson()});
  } catch (e, s) {
    return handleRouteException(e, s, logMessage: 'Failed to claim next job');
  }
}
