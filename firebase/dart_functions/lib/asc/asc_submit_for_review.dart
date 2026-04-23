import 'package:firebase_functions/firebase_functions.dart';

import '../util/logger.dart';
import 'asc_client.dart';
import 'asc_requests.dart';

Future<Map<String, dynamic>> handleAscSubmitForReview(
  CallableRequest<SubmitForReviewRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final req = request.data;
  await verifyAndGetTeam(req.teamId, auth.uid);

  final creds = await getAscCredentials(req.teamId);
  final token = generateAscJwt(
    issuerId: creds.issuerId,
    keyId: creds.keyId,
    privateKey: creds.privateKey,
  );

  final appStoreVersionId = await _resolveAppStoreVersion(
    token: token,
    appId: req.appId,
    versionString: req.versionString,
    platform: req.platform,
  );

  await _setWhatsNew(
    token: token,
    appStoreVersionId: appStoreVersionId,
    whatsNew: req.whatsNew,
  );

  await ascApiFetch(
    token: token,
    path: '/appStoreVersions/$appStoreVersionId/relationships/build',
    method: 'PATCH',
    body: {
      'data': {'type': 'builds', 'id': req.buildId},
    },
  );

  try {
    await ascApiFetch(
      token: token,
      path: '/builds/${req.buildId}',
      method: 'PATCH',
      body: {
        'data': {
          'type': 'builds',
          'id': req.buildId,
          'attributes': {'usesNonExemptEncryption': false},
        },
      },
    );
    logInfo('Set usesNonExemptEncryption=false on build', {
      'buildId': req.buildId,
    });
  } catch (e) {
    logWarning(
      'Failed to set usesNonExemptEncryption, trying via Info.plist key',
      {'buildId': req.buildId, 'error': e.toString()},
    );
  }

  final reviewSubmission = await ascApiFetch(
    token: token,
    path: '/reviewSubmissions',
    method: 'POST',
    body: {
      'data': {
        'type': 'reviewSubmissions',
        'relationships': {
          'app': {
            'data': {'type': 'apps', 'id': req.appId},
          },
        },
      },
    },
  );

  final reviewSubmissionId =
      (reviewSubmission['data'] as Map<String, dynamic>)['id'] as String;

  await ascApiFetch(
    token: token,
    path: '/reviewSubmissionItems',
    method: 'POST',
    body: {
      'data': {
        'type': 'reviewSubmissionItems',
        'relationships': {
          'reviewSubmission': {
            'data': {'type': 'reviewSubmissions', 'id': reviewSubmissionId},
          },
          'appStoreVersion': {
            'data': {'type': 'appStoreVersions', 'id': appStoreVersionId},
          },
        },
      },
    },
  );

  await ascApiFetch(
    token: token,
    path: '/reviewSubmissions/$reviewSubmissionId',
    method: 'PATCH',
    body: {
      'data': {
        'type': 'reviewSubmissions',
        'id': reviewSubmissionId,
        'attributes': {'submitted': true},
      },
    },
  );

  logInfo('Build submitted for App Store Review', {
    'appId': req.appId,
    'buildId': req.buildId,
    'versionString': req.versionString,
    'appStoreVersionId': appStoreVersionId,
  });

  return <String, dynamic>{
    'success': true,
    'appStoreVersionId': appStoreVersionId,
  };
}

Future<String> _resolveAppStoreVersion({
  required String token,
  required String appId,
  required String versionString,
  required String platform,
}) async {
  final existingVersions = await ascApiFetch(
    token: token,
    path:
        '/apps/$appId/appStoreVersions'
        '?filter[versionString]=$versionString'
        '&filter[platform]=$platform',
  );

  final versions = (existingVersions['data'] as List<dynamic>?) ?? [];
  if (versions.isNotEmpty) {
    final version = versions.first as Map<String, dynamic>;
    final state =
        (version['attributes'] as Map<String, dynamic>)['appStoreState']
            as String?;

    const editableStates = {
      'PREPARE_FOR_SUBMISSION',
      'DEVELOPER_REJECTED',
      'REJECTED',
    };

    if (editableStates.contains(state)) {
      return version['id'] as String;
    }

    throw AscException(
      'Version $versionString is already in state: $state. Cannot submit.',
    );
  }

  final createResponse = await ascApiFetch(
    token: token,
    path: '/appStoreVersions',
    method: 'POST',
    body: {
      'data': {
        'type': 'appStoreVersions',
        'attributes': {'versionString': versionString, 'platform': platform},
        'relationships': {
          'app': {
            'data': {'type': 'apps', 'id': appId},
          },
        },
      },
    },
  );

  return (createResponse['data'] as Map<String, dynamic>)['id'] as String;
}

Future<void> _setWhatsNew({
  required String token,
  required String appStoreVersionId,
  required String whatsNew,
}) async {
  final locResponse = await ascApiFetch(
    token: token,
    path:
        '/appStoreVersions/$appStoreVersionId'
        '/appStoreVersionLocalizations',
  );

  final localizations = (locResponse['data'] as List<dynamic>?) ?? [];

  if (localizations.isNotEmpty) {
    for (final loc in localizations) {
      final locId = (loc as Map<String, dynamic>)['id'] as String;
      await ascApiFetch(
        token: token,
        path: '/appStoreVersionLocalizations/$locId',
        method: 'PATCH',
        body: {
          'data': {
            'type': 'appStoreVersionLocalizations',
            'id': locId,
            'attributes': {'whatsNew': whatsNew},
          },
        },
      );
    }
  } else {
    await ascApiFetch(
      token: token,
      path: '/appStoreVersionLocalizations',
      method: 'POST',
      body: {
        'data': {
          'type': 'appStoreVersionLocalizations',
          'attributes': {'locale': 'en-US', 'whatsNew': whatsNew},
          'relationships': {
            'appStoreVersion': {
              'data': {'type': 'appStoreVersions', 'id': appStoreVersionId},
            },
          },
        },
      },
    );
  }
}
