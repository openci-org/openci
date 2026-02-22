import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

enum NotificationPreference {
  all,
  successOnly,
  failureOnly,
  none,
}

@freezed
abstract class OpenCIUser with _$OpenCIUser {
  const factory OpenCIUser({
    required String id,
    required String selectedTeamId,
    @Default(NotificationPreference.all)
    NotificationPreference notificationPreference,
    @Default([]) List<String> fcmTokens,
  }) = _OpenCIUser;
  factory OpenCIUser.fromJson(Map<String, Object?> json) =>
      _$OpenCIUserFromJson(json);
}

@riverpod
class User extends _$User {
  @override
  Stream<OpenCIUser> build() => fetchUser();

  Stream<OpenCIUser> fetchUser() {
    final firestore = ref.read(firestoreProvider);
    final auth = ref.read(authProvider);
    final currentUserId = auth.requireValue?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    return firestore
        .collection(usersCollection)
        .doc(currentUserId)
        .withConverter(
          fromFirestore: (snapshot, _) => OpenCIUser.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots()
        .map((qs) => qs.data()!);
  }

  Future<void> updateSelectedTeamId(String teamId) async {
    final firestore = ref.read(firestoreProvider);
    final auth = ref.read(authProvider);
    final currentUserId = auth.requireValue?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await firestore.collection(usersCollection).doc(currentUserId).update({
      'selectedTeamId': teamId,
    });
  }

  Future<void> updateNotificationPreference(
    NotificationPreference preference,
  ) async {
    final firestore = ref.read(firestoreProvider);
    final auth = ref.read(authProvider);
    final currentUserId = auth.requireValue?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await firestore.collection(usersCollection).doc(currentUserId).update({
      'notificationPreference': preference.name,
    });
  }

  Future<void> addFcmToken(String token) async {
    final firestore = ref.read(firestoreProvider);
    final auth = ref.read(authProvider);
    final currentUserId = auth.requireValue?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    final docRef = firestore.collection(usersCollection).doc(currentUserId);
    final doc = await docRef.get();
    final data = doc.data();
    final existingTokens = List<String>.from(data?['fcmTokens'] as List? ?? []);
    if (!existingTokens.contains(token)) {
      existingTokens.add(token);
      await docRef.update({'fcmTokens': existingTokens});
    }
  }
}
