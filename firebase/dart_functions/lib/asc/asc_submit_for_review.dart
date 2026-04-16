import 'package:firebase_functions/firebase_functions.dart';

import '../util/logger.dart';
import 'asc_client.dart';
import 'asc_requests.dart';

/// Handler for the `ascSubmitForReview` callable function.
///
/// Creates or finds an App Store version, sets release notes,
/// attaches a build, and submits for App Store review.
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

  // 1. Create or find appStoreVersion
  final appStoreVersionId = await _resolveAppStoreVersion(
    token: token,
    appId: req.appId,
    versionString: req.versionString,
    platform: req.platform,
  );

  // 2. Set "What's New" release notes via localizations
  await _setWhatsNew(
    token: token,
    appStoreVersionId: appStoreVersionId,
    whatsNew: req.whatsNew,
  );

  // 3. Attach the build to the version
  await ascApiFetch(
    token: token,
    path: '/appStoreVersions/$appStoreVersionId/relationships/build',
    method: 'PATCH',
    body: {
      'data': {'type': 'builds', 'id': req.buildId},
    },
  );

  // 3.5 Set export compliance (usesNonExemptEncryption)
  try {
    await ascApiFetch(
      token: token,
      path: '/builds/${req.buildId}',
      method: 'PATCH',
      body: {
        'data': {
          'type': 'builds',
          'id': req.buildId,
          'attributes': {
            'usesNonExemptEncryption': false,
          },
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

  // 4. Submit for review using the reviewSubmissions API
  // Step 4a: Create a review submission
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

  // Step 4b: Add the app store version as a review submission item
  await ascApiFetch(
    token: token,
    path: '/reviewSubmissionItems',
    method: 'POST',
    body: {
      'data': {
        'type': 'reviewSubmissionItems',
        'relationships': {
          'reviewSubmission': {
            'data': {
              'type': 'reviewSubmissions',
              'id': reviewSubmissionId,
            },
          },
          'appStoreVersion': {
            'data': {
              'type': 'appStoreVersions',
              'id': appStoreVersionId,
            },
          },
        },
      },
    },
  );

  // Step 4c: Submit the review submission
  await ascApiFetch(
    token: token,
    path: '/reviewSubmissions/$reviewSubmissionId',
    method: 'PATCH',
    body: {
      'data': {
        'type': 'reviewSubmissions',
        'id': reviewSubmissionId,
        'attributes': {
          'submitted': true,
        },
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

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Finds an existing editable version or creates a new one.
Future<String> _resolveAppStoreVersion({
  required String token,
  required String appId,
  required String versionString,
  required String platform,
}) async {
  final existingVersions = await ascApiFetch(
    token: token,
    path: '/apps/$appId/appStoreVersions'
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

  // Create a new appStoreVersion
  final createResponse = await ascApiFetch(
    token: token,
    path: '/appStoreVersions',
    method: 'POST',
    body: {
      'data': {
        'type': 'appStoreVersions',
        'attributes': {
          'versionString': versionString,
          'platform': platform,
        },
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

/// Sets the "What's New" text on all localizations for the version.
Future<void> _setWhatsNew({
  required String token,
  required String appStoreVersionId,
  required String whatsNew,
}) async {
  final locResponse = await ascApiFetch(
    token: token,
    path: '/appStoreVersions/$appStoreVersionId'
        '/appStoreVersionLocalizations',
  );

  final localizations = (locResponse['data'] as List<dynamic>?) ?? [];

  if (localizations.isNotEmpty) {
    // Update existing localization(s)
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
            'attributes': {
              'whatsNew': whatsNew,
            },
          },
        },
      );
    }
  } else {
    // Create a default en-US localization
    await ascApiFetch(
      token: token,
      path: '/appStoreVersionLocalizations',
      method: 'POST',
      body: {
        'data': {
          'type': 'appStoreVersionLocalizations',
          'attributes': {
            'locale': 'en-US',
            'whatsNew': whatsNew,
          },
          'relationships': {
            'appStoreVersion': {
              'data': {
                'type': 'appStoreVersions',
                'id': appStoreVersionId,
              },
            },
          },
        },
      },
    );
  }
}
