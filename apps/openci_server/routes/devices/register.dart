import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
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

    late final Map<String, dynamic> body;
    try {
      final raw = await context.request.json();
      if (raw is! Map<String, dynamic>) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'success': false,
            'error': 'Request body must be a JSON object',
          },
        );
      }
      body = raw;
    } on FormatException {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Malformed JSON body',
        },
      );
    }

    final teamId = body['teamId'];
    final udid = body['udid'];
    final deviceProduct = body['deviceProduct'];
    final deviceOsVersion = body['deviceOsVersion'];

    if (teamId is! String ||
        udid is! String ||
        deviceProduct is! String ||
        deviceOsVersion is! String ||
        teamId.trim().isEmpty ||
        udid.trim().isEmpty ||
        deviceProduct.trim().isEmpty ||
        deviceOsVersion.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error':
              'Missing or empty required parameters: '
              'teamId, udid, deviceProduct, deviceOsVersion',
        },
      );
    }

    final existing = await db.deviceDao.findDevice(
      userId: uid,
      teamId: teamId,
      udid: udid,
    );

    final DriftUserDevice device;
    if (existing != null) {
      device = await db.deviceDao.updateDevice(
        existing: existing,
        deviceProduct: deviceProduct,
        deviceOsVersion: deviceOsVersion,
      );
    } else {
      device = await db.deviceDao.createDevice(
        userId: uid,
        teamId: teamId,
        udid: udid,
        deviceProduct: deviceProduct,
        deviceOsVersion: deviceOsVersion,
      );
    }

    return Response.json(
      body: device.toJson(),
    );
  } catch (e, s) {
    return handleRouteException(e, s, logMessage: 'Failed to register device');
  }
}
