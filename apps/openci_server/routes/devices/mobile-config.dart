import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:uuid/uuid.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context) async {
  try {
    final queryParams = context.request.uri.queryParameters;
    final userId = queryParams['userId'];
    final teamId = queryParams['teamId'];
    final redirectOrigin = queryParams['redirectOrigin'];

    if (userId == null ||
        userId.isEmpty ||
        teamId == null ||
        teamId.isEmpty ||
        redirectOrigin == null ||
        redirectOrigin.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error':
              'Missing required parameters: userId, teamId, redirectOrigin',
        },
      );
    }

    final callbackUrl =
        '$redirectOrigin/register-device'
        '?userId=${Uri.encodeComponent(userId)}'
        '&teamId=${Uri.encodeComponent(teamId)}'
        '&redirectOrigin=${Uri.encodeComponent(redirectOrigin)}';

    final profileUuid = const Uuid().v4();

    final configXml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <dict>
    <key>URL</key>
    <string>$callbackUrl</string>
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
