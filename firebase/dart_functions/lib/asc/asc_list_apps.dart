import 'package:firebase_functions/firebase_functions.dart';

import 'asc_client.dart';
import 'asc_models.dart';
import 'asc_requests.dart';

/// Handler for the `ascListApps` callable function.
///
/// Fetches a list of apps from App Store Connect for the given team.
Future<Map<String, dynamic>> handleAscListApps(
  CallableRequest<TeamRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final teamId = request.data.teamId;
  await verifyAndGetTeam(teamId, auth.uid);

  final creds = await getAscCredentials(teamId);
  final token = generateAscJwt(
    issuerId: creds.issuerId,
    keyId: creds.keyId,
    privateKey: creds.privateKey,
  );

  final result = await ascApiFetch(
    token: token,
    path: '/apps?fields[apps]=name,bundleId,sku&limit=100',
  );

  final rawApps = (result['data'] as List<dynamic>?) ?? [];
  final apps = rawApps
      .map((e) => AscApp.fromJsonApi(e as Map<String, dynamic>))
      .map((app) => app.toJson())
      .toList();

  return <String, dynamic>{'apps': apps};
}
