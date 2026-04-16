import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../secret_manager.dart';

const _ascBaseUrl = 'https://api.appstoreconnect.apple.com/v1';

/// ASC API credentials retrieved from Secret Manager.
class AscCredentials {
  const AscCredentials({
    required this.issuerId,
    required this.keyId,
    required this.privateKey,
  });

  final String issuerId;
  final String keyId;
  final String privateKey;
}

/// Retrieves ASC API credentials from Firestore + Secret Manager.
Future<AscCredentials> getAscCredentials(String teamId) async {
  final snapshot = await firestore
      .collection(secretsCollection)
      .where('teamId', WhereFilter.equal, teamId)
      .where('name', WhereFilter.isIn, [
        'OPENCI_ASC_ISSUER_ID',
        'OPENCI_ASC_KEY_ID',
        'OPENCI_ASC_PRIVATE_KEY',
      ])
      .get();

  if (snapshot.empty || snapshot.size < 3) {
    throw AscException(
      'ASC API credentials not configured. '
      'Please set up your App Store Connect API key first.',
    );
  }

  final secrets = <String, String>{};
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final name = data['name'] as String;
    final pathToSecret = data['pathToSecret'] as String;
    secrets[name] = await _getSecretValue(pathToSecret);
  }

  return AscCredentials(
    issuerId: secrets['OPENCI_ASC_ISSUER_ID']!,
    keyId: secrets['OPENCI_ASC_KEY_ID']!,
    privateKey: secrets['OPENCI_ASC_PRIVATE_KEY']!,
  );
}

/// Reads a secret value from Secret Manager by its full resource path.
Future<String> _getSecretValue(String pathToSecret) async {
  // pathToSecret is like "projects/xxx/secrets/yyy"
  // We need to extract the secret ID and use accessSecret.
  // However, the TS version accesses by full path, so we replicate that.
  final parts = pathToSecret.split('/');
  // Expected format: projects/{project}/secrets/{secretId}
  if (parts.length >= 4 && parts[2] == 'secrets') {
    return accessSecret(parts[3]);
  }
  throw AscException('Invalid secret path: $pathToSecret');
}

/// Generates a JWT for App Store Connect API authentication.
String generateAscJwt({
  required String issuerId,
  required String keyId,
  required String privateKey,
}) {
  final jwt = JWT(
    {},
    issuer: issuerId,
    audience: Audience(['appstoreconnect-v1']),
  );

  return jwt.sign(
    ECPrivateKey(privateKey),
    algorithm: JWTAlgorithm.ES256,
    expiresIn: const Duration(minutes: 20),
    noIssueAt: false,
  );
}

/// Makes a request to the App Store Connect API.
Future<Map<String, dynamic>> ascApiFetch({
  required String token,
  required String path,
  String method = 'GET',
  Map<String, dynamic>? body,
}) async {
  final url = path.startsWith('http') ? path : '$_ascBaseUrl$path';
  final dio = Dio();

  try {
    final response = await dio.request<String>(
      url,
      options: Options(
        method: method,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      ),
      data: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 204 ||
        response.data == null ||
        response.data!.isEmpty) {
      return {};
    }

    return jsonDecode(response.data!) as Map<String, dynamic>;
  } on DioException catch (e) {
    final status = e.response?.statusCode ?? 0;
    final errorBody = e.response?.data?.toString() ?? e.message ?? 'Unknown';
    throw AscException('App Store Connect API error ($status): $errorBody');
  }
}

/// Verifies that the caller is a member of the team and returns team data.
Future<Map<String, dynamic>> verifyAndGetTeam(
  String teamId,
  String callerUid,
) async {
  final teamDoc = await firestore.collection(teamsCollection).doc(teamId).get();
  if (!teamDoc.exists) {
    throw AscException('Team not found');
  }

  final teamData = teamDoc.data()!;
  final members = (teamData['members'] as List<dynamic>?)?.cast<String>() ?? [];
  if (!members.contains(callerUid)) {
    throw AscException('You are not a member of this team');
  }

  return teamData;
}

/// Exception class for ASC-related errors.
class AscException implements Exception {
  const AscException(this.message);
  final String message;

  @override
  String toString() => 'AscException: $message';
}
