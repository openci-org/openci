import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
    final firestore = FirebaseFirestore.instance;
    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) return Stream.value([]);
    return firestore
        .collection(secretsCollection)
        .withConverter(
          fromFirestore: (snapshot, _) => Secret.fromJson(snapshot.data()!),
          toFirestore: (secret, _) => secret.toJson(),
        )
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addSecret(String name, String value) async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('create-secret-v1'))
        .call({
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
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('update-secret-v1'))
        .call({
      'documentId': documentId,
      'name': name,
      if (value != null && value.isNotEmpty) 'value': value,
      'teamId': teamId,
    });
  }

  Future<void> deleteSecret({required String documentId}) async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('delete-secret-v1'))
        .call({
      'documentId': documentId,
      'teamId': teamId,
    });
  }

  Future<void> generateCertificateKey() async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('generate-certificate-key-v1'))
        .call({
      'teamId': teamId,
    });
  }

  Future<void> setupAscApiKey({
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('setup-asc-api-key-v1'))
        .call({
      'teamId': teamId,
      'issuerId': issuerId,
      'keyId': keyId,
      'privateKey': privateKey,
    });
  }
}

@freezed
abstract class Secret with _$Secret {
  const factory Secret({
    required String id,
    required String name,
    required String teamId,
    String? pathToSecret,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Secret;

  factory Secret.fromJson(Map<String, Object?> json) => _$SecretFromJson(json);
}
