import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';

class AscApp {
  final String id;
  final String name;
  final String bundleId;
  final String? sku;

  const AscApp({
    required this.id,
    required this.name,
    required this.bundleId,
    this.sku,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bundleId': bundleId,
    'sku': sku,
  };
}

class AscBuild {
  final String id;
  final String version;
  final String buildNumber;
  final String platform;
  final String? uploadedDate;
  final String? processingState;
  final String? iconUrl;
  final String? externalBuildState;
  final String? internalBuildState;
  final String? appStoreState;

  const AscBuild({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.platform,
    this.uploadedDate,
    this.processingState,
    this.iconUrl,
    this.externalBuildState,
    this.internalBuildState,
    this.appStoreState,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'buildNumber': buildNumber,
    'platform': platform,
    if (uploadedDate != null) 'uploadedDate': uploadedDate,
    if (processingState != null) 'processingState': processingState,
    if (iconUrl != null) 'iconUrl': iconUrl,
    if (externalBuildState != null) 'externalBuildState': externalBuildState,
    if (internalBuildState != null) 'internalBuildState': internalBuildState,
    if (appStoreState != null) 'appStoreState': appStoreState,
  };
}

class AscService {
  const AscService();

  Future<List<AscBuild>> listBuilds(
    AppDatabase db,
    String teamId,
    String appId,
    SecretCrypter crypter,
  ) async {
    final issuerSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_ISSUER_ID',
    );
    final keyIdSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_KEY_ID',
    );
    final privateKeySecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_PRIVATE_KEY',
    );

    if (issuerSecret == null ||
        keyIdSecret == null ||
        privateKeySecret == null) {
      throw StateError(
        'App Store Connect API credentials are not configured for team $teamId',
      );
    }

    final issuerId = await crypter.decrypt(issuerSecret.encryptedValue);
    final keyId = await crypter.decrypt(keyIdSecret.encryptedValue);
    final privateKey = await crypter.decrypt(privateKeySecret.encryptedValue);

    if (issuerId.isEmpty || keyId.isEmpty || privateKey.isEmpty) {
      throw StateError('ASC API credentials are empty or invalid.');
    }

    final jwt = JWT(
      {
        'iss': issuerId,
        'exp':
            DateTime.now()
                .add(const Duration(minutes: 20))
                .millisecondsSinceEpoch ~/
            1000,
        'aud': 'appstoreconnect-v1',
      },
      header: {
        'alg': 'ES256',
        'kid': keyId,
        'typ': 'JWT',
      },
    );

    final token = jwt.sign(
      ECPrivateKey(privateKey),
      algorithm: JWTAlgorithm.ES256,
    );

    final path =
        '/builds?filter[app]=${Uri.encodeComponent(appId)}'
        '&sort=-uploadedDate'
        '&limit=20'
        '&include=preReleaseVersion,buildBetaDetail,appStoreVersion'
        '&fields[preReleaseVersions]=version,platform'
        '&fields[buildBetaDetails]=externalBuildState,internalBuildState'
        '&fields[appStoreVersions]=versionString,appStoreState';

    final url = Uri.parse('https://api.appstoreconnect.apple.com/v1$path');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>? ?? [];
    final includedList = body['included'] as List<dynamic>? ?? [];

    final preReleaseVersions = <String, Map<String, dynamic>>{};
    final buildBetaDetails = <String, Map<String, dynamic>>{};
    final appStoreVersions = <String, Map<String, dynamic>>{};

    for (final item in includedList) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'] as String?;
      final type = item['type'] as String?;
      if (id == null || type == null) continue;
      final attributes = item['attributes'] as Map<String, dynamic>? ?? {};

      if (type == 'preReleaseVersions') preReleaseVersions[id] = attributes;
      if (type == 'buildBetaDetails') buildBetaDetails[id] = attributes;
      if (type == 'appStoreVersions') appStoreVersions[id] = attributes;
    }

    final builds = <AscBuild>[];
    for (final item in dataList) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'] as String? ?? '';
      final attributes = item['attributes'] as Map<String, dynamic>? ?? {};

      final relationships =
          item['relationships'] as Map<String, dynamic>? ?? {};

      String? getRelId(String key) {
        final rel = relationships[key] as Map<String, dynamic>?;
        final data = rel?['data'] as Map<String, dynamic>?;
        return data?['id'] as String?;
      }

      final preReleaseVersionId = getRelId('preReleaseVersion');
      final betaDetailId = getRelId('buildBetaDetail');
      final appStoreVersionId = getRelId('appStoreVersion');

      final preRelease = preReleaseVersionId != null
          ? preReleaseVersions[preReleaseVersionId]
          : null;
      final betaDetail = betaDetailId != null
          ? buildBetaDetails[betaDetailId]
          : null;
      final appStoreVersion = appStoreVersionId != null
          ? appStoreVersions[appStoreVersionId]
          : null;

      final version =
          preRelease?['version'] as String? ??
          attributes['version'] as String? ??
          '';
      final buildNumber = attributes['version'] as String? ?? '';
      final platform = preRelease?['platform'] as String? ?? 'IOS';

      final uploadedDate = attributes['uploadedDate'] as String?;
      final processingState = attributes['processingState'] as String?;

      final iconAssetToken =
          attributes['iconAssetToken'] as Map<String, dynamic>?;
      final templateUrl = iconAssetToken?['templateUrl'] as String?;
      final iconUrl = templateUrl
          ?.replaceAll('{w}', '64')
          .replaceAll('{h}', '64')
          .replaceAll('{f}', 'png');

      final externalBuildState = betaDetail?['externalBuildState'] as String?;
      final internalBuildState = betaDetail?['internalBuildState'] as String?;
      final appStoreState = appStoreVersion?['appStoreState'] as String?;

      builds.add(
        AscBuild(
          id: id,
          version: version,
          buildNumber: buildNumber,
          platform: platform,
          uploadedDate: uploadedDate,
          processingState: processingState,
          iconUrl: iconUrl,
          externalBuildState: externalBuildState,
          internalBuildState: internalBuildState,
          appStoreState: appStoreState,
        ),
      );
    }

    return builds;
  }
  Future<List<AscApp>> listApps(
    AppDatabase db,
    String teamId,
    SecretCrypter crypter,
  ) async {
    final issuerSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_ISSUER_ID',
    );
    final keyIdSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_KEY_ID',
    );
    final privateKeySecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_PRIVATE_KEY',
    );

    if (issuerSecret == null ||
        keyIdSecret == null ||
        privateKeySecret == null) {
      throw StateError(
        'App Store Connect API credentials are not configured for team $teamId',
      );
    }

    final issuerId = await crypter.decrypt(issuerSecret.encryptedValue);
    final keyId = await crypter.decrypt(keyIdSecret.encryptedValue);
    final privateKey = await crypter.decrypt(privateKeySecret.encryptedValue);

    if (issuerId.isEmpty || keyId.isEmpty || privateKey.isEmpty) {
      throw StateError('ASC API credentials are empty or invalid.');
    }

    final jwt = JWT(
      {
        'iss': issuerId,
        'exp':
            DateTime.now()
                .add(const Duration(minutes: 20))
                .millisecondsSinceEpoch ~/
            1000,
        'aud': 'appstoreconnect-v1',
      },
      header: {
        'alg': 'ES256',
        'kid': keyId,
        'typ': 'JWT',
      },
    );

    final token = jwt.sign(
      ECPrivateKey(privateKey),
      algorithm: JWTAlgorithm.ES256,
    );

    final url = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/apps?fields[apps]=name,bundleId,sku&limit=100',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>? ?? [];

    final apps = <AscApp>[];
    for (final item in dataList) {
      final id = item['id'] as String;
      final attributes = item['attributes'] as Map<String, dynamic>? ?? {};
      final name = attributes['name'] as String? ?? '';
      final bundleId = attributes['bundleId'] as String? ?? '';
      final sku = attributes['sku'] as String?;

      apps.add(
        AscApp(
          id: id,
          name: name,
          bundleId: bundleId,
          sku: sku,
        ),
      );
    }

    return apps;
  }

  Future<String> submitToTestFlight(
    AppDatabase db,
    String teamId,
    String buildId,
    SecretCrypter crypter,
  ) async {
    final issuerSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_ISSUER_ID',
    );
    final keyIdSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_KEY_ID',
    );
    final privateKeySecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_PRIVATE_KEY',
    );

    if (issuerSecret == null ||
        keyIdSecret == null ||
        privateKeySecret == null) {
      throw StateError(
        'App Store Connect API credentials are not configured for team $teamId',
      );
    }

    final issuerId = await crypter.decrypt(issuerSecret.encryptedValue);
    final keyId = await crypter.decrypt(keyIdSecret.encryptedValue);
    final privateKey = await crypter.decrypt(privateKeySecret.encryptedValue);

    if (issuerId.isEmpty || keyId.isEmpty || privateKey.isEmpty) {
      throw StateError('ASC API credentials are empty or invalid.');
    }

    final jwt = JWT(
      {
        'iss': issuerId,
        'exp':
            DateTime.now()
                .add(const Duration(minutes: 20))
                .millisecondsSinceEpoch ~/
            1000,
        'aud': 'appstoreconnect-v1',
      },
      header: {
        'alg': 'ES256',
        'kid': keyId,
        'typ': 'JWT',
      },
    );

    final token = jwt.sign(
      ECPrivateKey(privateKey),
      algorithm: JWTAlgorithm.ES256,
    );

    final listGroupsUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/betaGroups?limit=50',
    );
    final listResponse = await http.get(
      listGroupsUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (listResponse.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error (${listResponse.statusCode}): ${listResponse.body}',
      );
    }

    final listBody = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final dataList = listBody['data'] as List<dynamic>? ?? [];

    String? externalGroupId;
    String? externalGroupName;

    for (final item in dataList) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'] as String?;
      final attributes = item['attributes'] as Map<String, dynamic>? ?? {};
      final isInternalGroup = attributes['isInternalGroup'] as bool? ?? false;
      final name = attributes['name'] as String? ?? '';

      if (!isInternalGroup && id != null) {
        externalGroupId = id;
        externalGroupName = name;
        break;
      }
    }

    if (externalGroupId == null) {
      throw StateError(
        'No external beta groups found. Create a beta group in App Store Connect first.',
      );
    }

    final submitUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/betaGroups/$externalGroupId/relationships/builds',
    );
    final submitResponse = await http.post(
      submitUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': [
          {'type': 'builds', 'id': buildId},
        ],
      }),
    );

    if (submitResponse.statusCode != 204 && submitResponse.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error (${submitResponse.statusCode}): ${submitResponse.body}',
      );
    }

    return externalGroupName ?? '';
  }

  Future<String> submitForReview(
    AppDatabase db,
    String teamId, {
    required String appId,
    required String buildId,
    required String versionString,
    required String whatsNew,
    String platform = 'IOS',
    required SecretCrypter crypter,
  }) async {
    final issuerSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_ISSUER_ID',
    );
    final keyIdSecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_KEY_ID',
    );
    final privateKeySecret = await db.secretDao.getSecret(
      teamId,
      'OPENCI_ASC_PRIVATE_KEY',
    );

    if (issuerSecret == null ||
        keyIdSecret == null ||
        privateKeySecret == null) {
      throw StateError(
        'App Store Connect API credentials are not configured for team $teamId',
      );
    }

    final issuerId = await crypter.decrypt(issuerSecret.encryptedValue);
    final keyId = await crypter.decrypt(keyIdSecret.encryptedValue);
    final privateKey = await crypter.decrypt(privateKeySecret.encryptedValue);

    final jwt = JWT(
      {
        'iss': issuerId,
        'exp':
            DateTime.now()
                .add(const Duration(minutes: 20))
                .millisecondsSinceEpoch ~/
            1000,
        'aud': 'appstoreconnect-v1',
      },
      header: {
        'alg': 'ES256',
        'kid': keyId,
        'typ': 'JWT',
      },
    );

    final token = jwt.sign(
      ECPrivateKey(privateKey),
      algorithm: JWTAlgorithm.ES256,
    );

    // 1. Resolve App Store Version
    final versionsUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/apps/$appId/appStoreVersions'
      '?filter[versionString]=${Uri.encodeComponent(versionString)}'
      '&filter[platform]=$platform',
    );
    final versionsResponse = await http.get(
      versionsUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (versionsResponse.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error resolves version (${versionsResponse.statusCode}): ${versionsResponse.body}',
      );
    }

    final versionsBody =
        jsonDecode(versionsResponse.body) as Map<String, dynamic>;
    final versionsData = versionsBody['data'] as List<dynamic>? ?? [];

    String appStoreVersionId;
    if (versionsData.isNotEmpty) {
      final versionMap = versionsData[0] as Map<String, dynamic>;
      final attributes =
          versionMap['attributes'] as Map<String, dynamic>? ?? {};
      final state = attributes['appStoreState'] as String?;
      const editableStates = {
        'PREPARE_FOR_SUBMISSION',
        'DEVELOPER_REJECTED',
        'REJECTED',
      };
      if (state != null && editableStates.contains(state)) {
        appStoreVersionId = versionMap['id'] as String;
      } else {
        throw StateError(
          'Version $versionString is already in state: $state. Cannot submit.',
        );
      }
    } else {
      final createVersionUrl = Uri.parse(
        'https://api.appstoreconnect.apple.com/v1/appStoreVersions',
      );
      final createVersionResponse = await http.post(
        createVersionUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
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
        }),
      );

      if (createVersionResponse.statusCode != 201) {
        throw HttpException(
          'App Store Connect API error creating version (${createVersionResponse.statusCode}): ${createVersionResponse.body}',
        );
      }

      final createVersionBody =
          jsonDecode(createVersionResponse.body) as Map<String, dynamic>;
      appStoreVersionId = createVersionBody['data']['id'] as String;
    }

    // 2. Set What's New (Localizations)
    final locUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/appStoreVersions/$appStoreVersionId/appStoreVersionLocalizations',
    );
    final locResponse = await http.get(
      locUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (locResponse.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error fetching localizations (${locResponse.statusCode}): ${locResponse.body}',
      );
    }

    final locBody = jsonDecode(locResponse.body) as Map<String, dynamic>;
    final localizations = locBody['data'] as List<dynamic>? ?? [];

    if (localizations.isNotEmpty) {
      for (final loc in localizations) {
        if (loc is! Map<String, dynamic>) continue;
        final locId = loc['id'] as String;
        final updateLocUrl = Uri.parse(
          'https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$locId',
        );
        await http.patch(
          updateLocUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {
              'type': 'appStoreVersionLocalizations',
              'id': locId,
              'attributes': {'whatsNew': whatsNew},
            },
          }),
        );
      }
    } else {
      final createLocUrl = Uri.parse(
        'https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations',
      );
      await http.post(
        createLocUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'type': 'appStoreVersionLocalizations',
            'attributes': {'locale': 'en-US', 'whatsNew': whatsNew},
            'relationships': {
              'appStoreVersion': {
                'data': {'type': 'appStoreVersions', 'id': appStoreVersionId},
              },
            },
          },
        }),
      );
    }

    // 3. Link Build to App Store Version
    final linkBuildUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/appStoreVersions/$appStoreVersionId/relationships/build',
    );
    final linkBuildResponse = await http.patch(
      linkBuildUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': {'type': 'builds', 'id': buildId},
      }),
    );

    if (linkBuildResponse.statusCode != 204 &&
        linkBuildResponse.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error linking build (${linkBuildResponse.statusCode}): ${linkBuildResponse.body}',
      );
    }

    // 4. Update usesNonExemptEncryption on build
    try {
      final patchBuildUrl = Uri.parse(
        'https://api.appstoreconnect.apple.com/v1/builds/$buildId',
      );
      await http.patch(
        patchBuildUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'type': 'builds',
            'id': buildId,
            'attributes': {'usesNonExemptEncryption': false},
          },
        }),
      );
    } catch (e) {
      stderr.writeln('Failed to set usesNonExemptEncryption: $e');
    }

    // 5. Create Review Submission
    final createReviewUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/reviewSubmissions',
    );
    final createReviewResponse = await http.post(
      createReviewUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': {
          'type': 'reviewSubmissions',
          'relationships': {
            'app': {
              'data': {'type': 'apps', 'id': appId},
            },
          },
        },
      }),
    );

    if (createReviewResponse.statusCode != 201) {
      throw HttpException(
        'App Store Connect API error creating review submission (${createReviewResponse.statusCode}): ${createReviewResponse.body}',
      );
    }

    final createReviewBody =
        jsonDecode(createReviewResponse.body) as Map<String, dynamic>;
    final reviewSubmissionId = createReviewBody['data']['id'] as String;

    // 6. Add App Store Version to Review Submission Items
    final createItemUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/reviewSubmissionItems',
    );
    final createItemResponse = await http.post(
      createItemUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
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
              'data': {'type': 'appStoreVersions', 'id': appStoreVersionId},
            },
          },
        },
      }),
    );

    if (createItemResponse.statusCode != 201) {
      throw HttpException(
        'App Store Connect API error creating review submission item (${createItemResponse.statusCode}): ${createItemResponse.body}',
      );
    }

    // 7. Submit Review Submission
    final submitReviewUrl = Uri.parse(
      'https://api.appstoreconnect.apple.com/v1/reviewSubmissions/$reviewSubmissionId',
    );
    final submitReviewResponse = await http.patch(
      submitReviewUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': {
          'type': 'reviewSubmissions',
          'id': reviewSubmissionId,
          'attributes': {'submitted': true},
        },
      }),
    );

    if (submitReviewResponse.statusCode != 200) {
      throw HttpException(
        'App Store Connect API error submitting review (${submitReviewResponse.statusCode}): ${submitReviewResponse.body}',
      );
    }

    return appStoreVersionId;
  }
}
