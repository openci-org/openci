import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secret_manager_provider.freezed.dart';
part 'secret_manager_provider.g.dart';

@riverpod
class SecretManager extends _$SecretManager {
  @override
  Stream build() {
    return secretsStream();
  }

  Stream secretsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return throw Exception('User not logged in');
    }

    final firestore = ref.read(firestoreProvider.notifier).state;
    return firestore
        .collection(secretsCollection)
        .withConverter(
          fromFirestore: (snapshot, _) => Secret.fromJson(snapshot.data()!),
          toFirestore: (secret, _) => secret.toJson(),
        )
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

Future<void> addSecret(String name, String value) async {
  try {
    final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
    await functions.httpsCallable(callableFunctionPath).call({
      'name': name,
      'value': value,
    });
  } catch (e) {
    throw Exception('Failed to add secret: $e');
  }
}

@freezed
abstract class Secret with _$Secret {
  const factory Secret({
    required String id,
    required String name,
    required String userId,
    String? pathToSecret,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Secret;

  factory Secret.fromJson(Map<String, Object?> json) => _$SecretFromJson(json);
}

class DateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const DateTimeConverter();

  @override
  DateTime fromJson(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError(
      'Invalid type for DateTime conversion: ${value.runtimeType}',
    );
  }

  @override
  dynamic toJson(DateTime date) => Timestamp.fromDate(date);
}
