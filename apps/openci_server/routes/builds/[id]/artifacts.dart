import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/mime.dart';
import 'package:openci_server/storage.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final storage = context.read<StorageManager>();
    final queryParams = context.request.uri.queryParameters;
    final name = queryParams['name'];

    if (name == null || name.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'name parameter is required'},
      );
    }

    final objectName = 'artifacts/buildJobs/$id/$name';
    final presignStr = queryParams['presign'];
    final isPresign = presignStr == 'true';

    if (isPresign) {
      final url = await storage.getPresignedUrl(
        objectName,
        expires: const Duration(minutes: 15),
      );
      return Response.json(
        body: {
          'success': true,
          'url': url,
        },
      );
    } else {
      final stream = await storage.downloadObject(objectName);
      final contentType = getContentType(name);
      return Response.stream(
        body: stream,
        headers: {
          HttpHeaders.contentTypeHeader: contentType,
        },
      );
    }
  } catch (e, s) {
    if (e.toString().contains('NoSuchKey') || e.toString().contains('404')) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Artifact not found'},
      );
    }
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to download artifact for build $id',
    );
  }
}

Future<Response> _post(RequestContext context, String id) async {
  try {
    final storage = context.read<StorageManager>();
    final queryParams = context.request.uri.queryParameters;
    final name = queryParams['name'];

    if (name == null || name.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'name parameter is required'},
      );
    }

    final contentLengthStr = context.request.headers['content-length'];
    final size = contentLengthStr != null
        ? int.tryParse(contentLengthStr)
        : null;

    final stream = context.request.bytes().map(Uint8List.fromList);
    final objectName = 'artifacts/buildJobs/$id/$name';

    await storage.uploadObject(objectName, stream, size: size);

    final scheme = context.request.uri.scheme;
    final authority = context.request.uri.authority;
    final downloadUrl = '$scheme://$authority/builds/$id/artifacts?name=$name';

    return Response.json(
      body: {
        'success': true,
        'downloadUrl': downloadUrl,
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to upload artifact for build $id',
    );
  }
}
