import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/mobile_config_helper.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:uuid/uuid.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    HttpMethod.post => _post(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Set<String> allowedRedirectOrigins = () {
  final origins = Platform.environment['ALLOWED_ORIGINS'];
  if (origins == null || origins.trim().isEmpty) {
    throw StateError('ALLOWED_ORIGINS environment variable is not set');
  }
  final list = origins
      .split(',')
      .map((o) => o.trim().replaceAll(RegExp(r'/$'), ''))
      .where((o) => o.isNotEmpty)
      .toList();
  return {
    ...list,
  };
}();

Future<Response> _get(RequestContext context) async {
  try {
    final queryParams = context.request.uri.queryParameters;
    final userId = queryParams['userId'];
    final teamId = queryParams['teamId'];
    final redirectOrigin = queryParams['redirectOrigin'];
    final redirectUri = redirectOrigin == null
        ? null
        : Uri.tryParse(redirectOrigin);

    if (userId == null || userId.isEmpty || teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Missing required parameters: userId, teamId',
        },
      );
    }

    if (redirectOrigin == null ||
        redirectOrigin.isEmpty ||
        redirectUri == null ||
        redirectUri.scheme != 'https' ||
        redirectUri.host.isEmpty ||
        !allowedRedirectOrigins.contains(redirectUri.origin)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Invalid redirectOrigin',
        },
      );
    }

    final serverUri = context.request.uri;
    if (serverUri.port < 1 || serverUri.port > 65535) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Invalid server port',
        },
      );
    }

    final callbackUrl = Uri(
      scheme: serverUri.scheme,
      host: serverUri.host,
      port: serverUri.port != 80 && serverUri.port != 443
          ? serverUri.port
          : null,
      path: '/devices/mobile-config',
      queryParameters: {
        'userId': userId,
        'teamId': teamId,
        'redirectOrigin': redirectUri.origin,
      },
    ).toString();

    final profileUuid = const Uuid().v4();
    final escapedCallbackUrl = escapeXml(callbackUrl);

    final configXml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <dict>
    <key>URL</key>
    <string>$escapedCallbackUrl</string>
    <key>DeviceAttributes</key>
    <array>
      <string>UDID</string>
      <string>IMEI</string>
      <string>ICCID</string>
      <string>VERSION</string>
      <string>PRODUCT</string>
    </array>
  </dict>
  <key>PayloadDescription</key>
  <string>Profile to register your iOS device UDID for OpenCI App Distribution.</string>
  <key>PayloadDisplayName</key>
  <string>OpenCI Device UDID Enrollment</string>
  <key>PayloadIdentifier</key>
  <string>org.openci.profile-service</string>
  <key>PayloadOrganization</key>
  <string>OpenCI</string>
  <key>PayloadType</key>
  <string>Profile Service</string>
  <key>PayloadUUID</key>
  <string>$profileUuid</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
</dict>
</plist>''';

    return Response(
      body: configXml,
      headers: {
        'Content-Type': 'application/x-apple-aspen-config; charset=utf-8',
        'Content-Disposition':
            'attachment; filename="openci-udid.mobileconfig"',
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to generate mobileconfig',
    );
  }
}

Future<Response> _post(RequestContext context) async {
  try {
    final queryParams = context.request.uri.queryParameters;
    final userId = queryParams['userId'];
    final teamId = queryParams['teamId'];
    final redirectOrigin = queryParams['redirectOrigin'];
    final redirectUri = redirectOrigin == null
        ? null
        : Uri.tryParse(redirectOrigin);

    if (userId == null || userId.isEmpty || teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Missing required parameters: userId, teamId',
        },
      );
    }

    if (redirectOrigin == null ||
        redirectOrigin.isEmpty ||
        redirectUri == null ||
        redirectUri.scheme != 'https' ||
        redirectUri.host.isEmpty ||
        !allowedRedirectOrigins.contains(redirectUri.origin)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Invalid redirectOrigin',
        },
      );
    }

    final bodyStr = await context.request.body();
    final udid = extractUdid(bodyStr);

    if (udid == null || udid.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Could not extract UDID from profile installation payload',
        },
      );
    }

    final deviceProduct = extractProduct(bodyStr);
    final deviceOsVersion = extractOsVersion(bodyStr);

    final db = context.read<AppDatabase>();
    await db.deviceDao.upsertDevice(
      userId: userId,
      teamId: teamId,
      udid: udid,
      deviceProduct: deviceProduct,
      deviceOsVersion: deviceOsVersion,
    );

    final redirectUrl = redirectUri
        .replace(
          path: redirectUri.path.isEmpty ? '/' : redirectUri.path,
          queryParameters: {
            ...redirectUri.queryParameters,
            'enrolled': 'true',
            'udid': udid,
          },
          fragment: '/distributions',
        )
        .toString();

    return Response(
      statusCode: HttpStatus.movedPermanently,
      headers: {
        'Location': redirectUrl,
        'Content-Length': '0',
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed in registerDevice callback',
    );
  }
}
