import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    HttpMethod.post => _post(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final queryParams = context.request.uri.queryParameters;
    final teamId = queryParams['teamId'];
    if (teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Missing teamId parameter'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final hasIpaParam = queryParams['hasIpa'];
    bool? hasIpa;
    if (hasIpaParam != null) {
      if (hasIpaParam == 'true') {
        hasIpa = true;
      } else if (hasIpaParam == 'false') {
        hasIpa = false;
      } else {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Invalid hasIpa parameter'},
        );
      }
    }

    final limitParam = queryParams['limit'];
    const maxLimit = 200;
    final parsedLimit = limitParam == null ? 100 : int.tryParse(limitParam);
    if (parsedLimit == null || parsedLimit < 1 || parsedLimit > maxLimit) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid limit parameter'},
      );
    }
    final limit = parsedLimit;

    final driftJobs = await db.buildJobDao.getBuildJobsForTeam(
      teamId: teamId,
      hasIpa: hasIpa,
      limit: limit,
    );

    final jobs = driftJobs.map((j) => j.toShared().toJson()).toList();
    return Response.json(body: {'success': true, 'buildJobs': jobs});
  } catch (e, s) {
    stderr.writeln('Failed to get build jobs: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}

Future<Response> _post(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

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
        body: {'success': false, 'error': 'Invalid JSON format: $e'},
      );
    }

    final BuildJob job;
    try {
      job = BuildJob.fromJson(payload);
    } on TypeError catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid payload structure: $e'},
      );
    } on ArgumentError catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid payload values: $e'},
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid payload: $e'},
      );
    }

    final teamId = job.teamId;
    if (teamId == null) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final driftJob = job.toDrift();
    await db.buildJobDao.insertBuildJob(driftJob);

    return Response.json(
      body: {'success': true, 'id': job.id},
    );
  } catch (e, s) {
    stderr.writeln('Failed to insert build job: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
