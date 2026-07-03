import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/storage.dart';

Future<Response> onRequest(
  RequestContext context,
  String owner,
  String repo,
) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    final storage = context.read<StorageManager>();

    final job = await db.buildJobDao.getLatestSuccessfulMacosJob(
      owner: owner,
      repo: repo,
    );

    if (job == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'No successful macOS build found for $owner/$repo',
        },
      );
    }

    final objectName = 'artifacts/buildJobs/${job.id}/appcast.xml';

    try {
      final stream = await storage.downloadObject(objectName);
      return Response.stream(
        body: stream,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/rss+xml; charset=utf-8',
        },
      );
    } catch (e) {
      if (e.toString().contains('NoSuchKey') || e.toString().contains('404')) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {
            'success': false,
            'error': 'appcast.xml not found for build ${job.id}',
          },
        );
      }
      rethrow;
    }
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to serve appcast.xml for $owner/$repo',
    );
  }
}
