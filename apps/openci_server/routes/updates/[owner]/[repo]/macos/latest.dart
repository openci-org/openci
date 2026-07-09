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

    final jobs = await db.buildJobDao.getRecentSuccessfulMacosJobs(
      owner: owner,
      repo: repo,
      limit: 10,
    );

    if (jobs.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'No successful macOS build found for $owner/$repo',
        },
      );
    }

    const filename = 'OpenCI-dashboard-macos.zip';

    for (final job in jobs) {
      final objectName = 'artifacts/buildJobs/${job.id}/$filename';
      try {
        final stream = await storage.downloadObject(objectName);
        return Response.stream(
          body: stream,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/zip',
            'content-disposition': 'attachment; filename="$filename"',
          },
        );
      } catch (e) {
        if (e.toString().contains('NoSuchKey') ||
            e.toString().contains('404') ||
            e.toString().contains('does not exist') ||
            e.toString().contains('MinioError')) {
          // Fallback to the next successful job if this artifact is missing
          continue;
        }
        rethrow;
      }
    }

    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {
        'success': false,
        'error':
            'No macOS build artifact found for recent successful jobs in $owner/$repo',
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to serve latest macOS build for $owner/$repo',
    );
  }
}
