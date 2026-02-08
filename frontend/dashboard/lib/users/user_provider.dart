import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

@freezed
abstract class OpenCIUser with _$OpenCIUser {
  const factory OpenCIUser({
    required String id,
    required String selectedTeamId,
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
}
