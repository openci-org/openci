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
}
