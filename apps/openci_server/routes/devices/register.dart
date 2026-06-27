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

    final body = await context.request.json() as Map<String, dynamic>;
    final teamId = body['teamId'] as String?;
    final udid = body['udid'] as String?;
    final deviceProduct = body['deviceProduct'] as String?;
    final deviceOsVersion = body['deviceOsVersion'] as String?;

    if (teamId == null ||
        teamId.isEmpty ||
        udid == null ||
        udid.isEmpty ||
        deviceProduct == null ||
        deviceProduct.isEmpty ||
        deviceOsVersion == null ||
        deviceOsVersion.isEmpty) {
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
