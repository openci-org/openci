import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'store_release_provider.g.dart';

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

  factory AscApp.fromMap(Map<String, dynamic> map) => AscApp(
    id: map['id'] as String,
    name: map['name'] as String,
    bundleId: map['bundleId'] as String,
    sku: map['sku'] as String?,
  );
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

  bool get isProcessingComplete => processingState == 'VALID';

  bool get isInReview =>
      appStoreState == 'WAITING_FOR_REVIEW' || appStoreState == 'IN_REVIEW';

  bool get isSubmitted =>
      appStoreState != null &&
      appStoreState != 'PREPARE_FOR_SUBMISSION' &&
      appStoreState != 'REJECTED';

  factory AscBuild.fromMap(Map<String, dynamic> map) => AscBuild(
    id: map['id'] as String,
    version: map['version'] as String? ?? '',
    buildNumber: map['buildNumber'] as String? ?? '',
    platform: map['platform'] as String? ?? 'IOS',
    uploadedDate: map['uploadedDate'] as String?,
    processingState: map['processingState'] as String?,
    iconUrl: map['iconUrl'] as String?,
    externalBuildState: map['externalBuildState'] as String?,
    internalBuildState: map['internalBuildState'] as String?,
    appStoreState: map['appStoreState'] as String?,
  );
}

String _requireTeamId(dynamic ref) {
  final teamId = ref.read(teamStateProvider).value?.id as String?;
  if (teamId == null) throw StateError('team is not loaded yet');
  return teamId;
}

@riverpod
Future<bool> isAscConfigured(Ref ref) async {
  final secrets = await ref.watch(secretManagerProvider.future);
  final requiredKeys = {
    'OPENCI_ASC_ISSUER_ID',
    'OPENCI_ASC_KEY_ID',
    'OPENCI_ASC_PRIVATE_KEY',
    'OPENCI_IOS_CERTIFICATE_PRIVATE_KEY',
  };
  final existingKeys = secrets.map((s) => s.name).toSet();
  return requiredKeys.every(existingKeys.contains);
}

@riverpod
class AscApps extends _$AscApps {
  @override
  Future<List<AscApp>> build() async {
    final serverUrl = ref.watch(openciServerUrlProvider);
    final teamId = _requireTeamId(ref);
    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams/$teamId/asc/apps');
    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to fetch ASC apps: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = body['apps'] as List<dynamic>? ?? [];

    final apps = dataList
        .map((e) => AscApp.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return apps;
  }
}

@riverpod
class AscBuilds extends _$AscBuilds {
  @override
  Future<List<AscBuild>> build(String appId) async {
    final serverUrl = ref.watch(openciServerUrlProvider);
    final teamId = _requireTeamId(ref);
    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams/$teamId/asc/apps/$appId/builds');
    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to fetch ASC builds: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = body['builds'] as List<dynamic>? ?? [];

    final builds = dataList
        .map((e) => AscBuild.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return builds;
  }
}

@riverpod
class SubmitToTestFlight extends _$SubmitToTestFlight {
  @override
  FutureOr<void> build() {}

  Future<String> submit(String buildId) async {
    final serverUrl = ref.watch(openciServerUrlProvider);
    final teamId = _requireTeamId(ref);
    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse(
      '$serverUrl/teams/$teamId/asc/builds/$buildId/submit-testflight',
    );
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to submit build to TestFlight: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['betaGroupName'] as String? ?? 'External Testers';
  }
}

@riverpod
class SubmitForReview extends _$SubmitForReview {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String appId,
    required String buildId,
    required String versionString,
    required String whatsNew,
    String platform = 'IOS',
  }) async {
    final serverUrl = ref.watch(openciServerUrlProvider);
    final teamId = _requireTeamId(ref);
    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams/$teamId/asc/builds/submit-review');
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'appId': appId,
            'buildId': buildId,
            'versionString': versionString,
            'whatsNew': whatsNew,
            'platform': platform,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to submit build for review: ${response.statusCode} ${response.body}',
      );
    }
  }
}

@riverpod
class SetupAscCredentials extends _$SetupAscCredentials {
  @override
  FutureOr<void> build() {}

  Future<void> setup({
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final functions = firebaseFunctions;
    final teamId = _requireTeamId(ref);

    await functions.httpsCallable('setupAscApiKeyV1').call({
      'teamId': teamId,
      'issuerId': issuerId,
      'keyId': keyId,
      'privateKey': privateKey,
    });
  }
}
