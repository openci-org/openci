import 'package:firebase_functions/firebase_functions.dart';

import 'asc_client.dart';
import 'asc_models.dart';
import 'asc_requests.dart';

Future<Map<String, dynamic>> handleAscListBuilds(
  CallableRequest<ListBuildsRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final teamId = request.data.teamId;
  final appId = request.data.appId;

  await verifyAndGetTeam(teamId, auth.uid);

  final creds = await getAscCredentials(teamId);
  final token = generateAscJwt(
    issuerId: creds.issuerId,
    keyId: creds.keyId,
    privateKey: creds.privateKey,
  );

  final result = await ascApiFetch(
    token: token,
    path:
        '/builds'
        '?filter[app]=$appId'
        '&sort=-uploadedDate'
        '&limit=20'
        '&include=preReleaseVersion,buildBetaDetail,appStoreVersion'
        '&fields[preReleaseVersions]=version,platform'
        '&fields[buildBetaDetails]=externalBuildState,internalBuildState'
        '&fields[appStoreVersions]=versionString,appStoreState',
  );

  final included = (result['included'] as List<dynamic>?) ?? [];
  final resources = parseIncludedResources(included);

  final rawBuilds = (result['data'] as List<dynamic>?) ?? [];
  final builds = rawBuilds
      .map(
        (e) => AscBuild.fromJsonApi(
          e as Map<String, dynamic>,
          preReleaseVersions: resources.preReleaseVersions,
          buildBetaDetails: resources.buildBetaDetails,
          appStoreVersions: resources.appStoreVersions,
        ),
      )
      .map((b) => b.toJson())
      .toList();

  return <String, dynamic>{'builds': builds};
}
