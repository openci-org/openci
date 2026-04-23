import 'package:firebase_functions/firebase_functions.dart';

import '../util/logger.dart';
import 'asc_client.dart';
import 'asc_models.dart';
import 'asc_requests.dart';

Future<Map<String, dynamic>> handleAscSubmitToTestFlight(
  CallableRequest<SubmitToTestFlightRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final teamId = request.data.teamId;
  final buildId = request.data.buildId;

  await verifyAndGetTeam(teamId, auth.uid);

  final creds = await getAscCredentials(teamId);
  final token = generateAscJwt(
    issuerId: creds.issuerId,
    keyId: creds.keyId,
    privateKey: creds.privateKey,
  );

  final betaGroupsData = await ascApiFetch(
    token: token,
    path: '/betaGroups?limit=50',
  );

  final allGroups = (betaGroupsData['data'] as List<dynamic>?) ?? [];
  final externalGroups = allGroups
      .map((e) => AscBetaGroup.fromJsonApi(e as Map<String, dynamic>))
      .where((g) => !g.isInternalGroup)
      .toList();

  if (externalGroups.isEmpty) {
    throw AscException(
      'No external beta groups found. '
      'Create a beta group in App Store Connect first.',
    );
  }

  final group = externalGroups.first;
  await ascApiFetch(
    token: token,
    path: '/betaGroups/${group.id}/relationships/builds',
    method: 'POST',
    body: {
      'data': [
        {'type': 'builds', 'id': buildId},
      ],
    },
  );

  logInfo('Build submitted to TestFlight', {
    'buildId': buildId,
    'groupId': group.id,
  });

  return <String, dynamic>{'success': true, 'betaGroupName': group.name};
}
