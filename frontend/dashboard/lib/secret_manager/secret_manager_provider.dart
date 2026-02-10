import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/firebase/functions_provider.dart';
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
    final firestore = ref.read(firestoreProvider.notifier).state;
    final teamId = ref.watch(teamStateProvider).requireValue.id;
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
    final functions = ref.read(functionsProvider);
    final teamId = ref.read(teamStateProvider).requireValue.id;
    await functions.httpsCallable(callableFunctionPath).call({
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
    final functions = ref.read(functionsProvider);
    final teamId = ref.read(teamStateProvider).requireValue.id;
    await functions.httpsCallable(updateSecretCallableFunctionPath).call({
      'documentId': documentId,
      'name': name,
      if (value != null && value.isNotEmpty) 'value': value,
      'teamId': teamId,
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
