import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secret_manager_provider.freezed.dart';
part 'secret_manager_provider.g.dart';

@riverpod
class SecretManager extends _$SecretManager {
  @override
  Stream<List<Secret>> build() {
    return secretsStream();
  }

  Stream<List<Secret>> secretsStream() {
    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) return Stream.value([]);
    return firestore
        .collection(secretsCollection)
        .where('teamId', isEqualTo: teamId)
        .orderBy('name')
        .snapshots()
        .map(
          (result) => result.docs.map((doc) {
            final data = doc.data();
            return Secret(
              id: doc.id,
              name: data['name'] as String? ?? '',
              teamId: data['teamId'] as String? ?? '',
              createdAt: dateTimeFromFirestore(data['createdAt']),
              updatedAt: dateTimeFromFirestore(data['updatedAt']),
            );
          }).toList(),
        );
  }

  Future<void> addSecret(String name, String value) async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('createSecretV1').call({
      'name': name,
      'value': value,
      'teamId': teamId,
    });
  }

  Future<void> updateSecret({
    required String documentId,
    required String name,
    String? value,
  }) async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('updateSecretV1').call({
      'documentId': documentId,
      'name': name,
      if (value != null && value.isNotEmpty) 'value': value,
      'teamId': teamId,
    });
  }

  Future<void> deleteSecret({required String documentId}) async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('deleteSecretV1').call({
      'documentId': documentId,
      'teamId': teamId,
    });
  }

  Future<void> generateCertificateKey() async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('generateCertificateKeyV1').call({
      'teamId': teamId,
    });
  }

  Future<void> setupAscApiKey({
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('setupAscApiKeyV1').call({
      'teamId': teamId,
      'issuerId': issuerId,
      'keyId': keyId,
      'privateKey': privateKey,
    });
  }

  Future<String> generateDeveloperIdCsr() async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    final result = await functions
        .httpsCallable('generateDeveloperIdCsrV1')
        .call({
          'teamId': teamId,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['csrPem'] as String? ?? '';
  }

  Future<void> registerDeveloperIdCertificate({
    required String certificateBase64,
  }) async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('registerDeveloperIdCertificateV1').call({
      'teamId': teamId,
      'certificateBase64': certificateBase64,
    });
  }
}

@freezed
abstract class Secret with _$Secret {
  const factory Secret({
    required String id,
    required String name,
    required String teamId,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Secret;

  factory Secret.fromJson(Map<String, Object?> json) => _$SecretFromJson(json);
}
