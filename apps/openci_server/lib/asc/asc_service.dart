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

class AscService {
  const AscService();

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
