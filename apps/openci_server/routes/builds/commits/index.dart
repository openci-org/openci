import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return _get(context);
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

    final limitParam = queryParams['limit'];
    final parsedLimit = limitParam == null ? 100 : int.tryParse(limitParam);
    final limit = (parsedLimit == null || parsedLimit < 1) ? 100 : parsedLimit;

    final driftJobs = await db.buildJobDao.getBuildJobsForTeam(
      teamId: teamId,
      limit: limit,
    );

    final jobs = driftJobs.map((j) => j.toShared()).toList();

    final commitGroups = groupBuildJobsToCommitGroups(jobs);

    return Response.json(
      body: commitGroups.map((g) => g.toJson()).toList(),
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to get commit groups',
    );
  }
}
