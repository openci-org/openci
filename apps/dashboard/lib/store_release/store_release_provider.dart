import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'store_release_provider.g.dart';

// ── Models ──

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
      appStoreState == 'WAITING_FOR_REVIEW' ||
      appStoreState == 'IN_REVIEW';

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

// ── Providers ──

String _requireTeamId(dynamic ref) {
  final teamId = ref.read(teamStateProvider).value?.id as String?;
  if (teamId == null) throw StateError('team is not loaded yet');
  return teamId;
}

/// Whether ASC API credentials are configured for the current team.
@riverpod
class IsAscConfigured extends _$IsAscConfigured {
  @override
  Stream<bool> build() {
    final firestore = ref.read(firestoreProvider);
    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) return Stream.value(false);

    return firestore
        .collection(secretsCollection)
        .where('teamId', isEqualTo: teamId)
        .where('name', isEqualTo: 'OPENCI_ASC_ISSUER_ID')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}

/// Fetch the list of apps from App Store Connect.
@riverpod
class AscApps extends _$AscApps {
  @override
  Future<List<AscApp>> build() async {
    final functions = ref.read(functionsProvider);
    final teamId = _requireTeamId(ref);

    final result =
        await functions.httpsCallable(ascListAppsFunction).call({
      'teamId': teamId,
    });

    final data = result.data as Map<String, dynamic>;
    final apps = (data['apps'] as List<dynamic>)
        .map((e) => AscApp.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return apps;
  }
}

/// Fetch builds for a specific app.
@riverpod
class AscBuilds extends _$AscBuilds {
  @override
  Future<List<AscBuild>> build(String appId) async {
    final functions = ref.read(functionsProvider);
    final teamId = _requireTeamId(ref);

    final result =
        await functions.httpsCallable(ascListBuildsFunction).call({
      'teamId': teamId,
      'appId': appId,
    });

    final data = result.data as Map<String, dynamic>;
    final builds = (data['builds'] as List<dynamic>)
        .map((e) => AscBuild.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return builds;
  }
}

/// Submit a build to TestFlight (external beta testing).
@riverpod
class SubmitToTestFlight extends _$SubmitToTestFlight {
  @override
  FutureOr<void> build() {}

  Future<String> submit(String buildId) async {
    final functions = ref.read(functionsProvider);
    final teamId = _requireTeamId(ref);

    final result =
        await functions.httpsCallable(ascSubmitToTestFlightFunction).call({
      'teamId': teamId,
      'buildId': buildId,
    });

    final data = result.data as Map<String, dynamic>;
    return data['betaGroupName'] as String? ?? 'External Testers';
  }
}

/// Submit a build for App Store Review.
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
    final functions = ref.read(functionsProvider);
    final teamId = _requireTeamId(ref);

    await functions.httpsCallable(ascSubmitForReviewFunction).call({
      'teamId': teamId,
      'appId': appId,
      'buildId': buildId,
      'versionString': versionString,
      'whatsNew': whatsNew,
      'platform': platform,
    });
  }
}

/// Setup ASC API credentials.
@riverpod
class SetupAscCredentials extends _$SetupAscCredentials {
  @override
  FutureOr<void> build() {}

  Future<void> setup({
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final functions = ref.read(functionsProvider);
    final teamId = _requireTeamId(ref);

    await functions.httpsCallable(setupAscApiKeyFunction).call({
      'teamId': teamId,
      'issuerId': issuerId,
      'keyId': keyId,
      'privateKey': privateKey,
    });
  }
}
