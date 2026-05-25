import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/github/repository_aliases.dart';
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
    String? selectedRepository,
    String? selectedBranch,
    String? udid,
  }) = _OpenCIUser;
  factory OpenCIUser.fromJson(Map<String, Object?> json) =>
      _$OpenCIUserFromJson(json);
}

@riverpod
class User extends _$User {
  @override
  Stream<OpenCIUser> build() async* {
    yield await fetchUser().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Timed out while loading user from Firestore',
      ),
    );

    yield* watchUser();
  }

  Future<OpenCIUser> fetchUser() async {
    final auth = ref.read(authProvider);
    final currentUser = auth.value;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }
    var snapshot = await firestore
        .collection(usersCollection)
        .doc(currentUser.uid)
        .get();
    final data = snapshot.data();
    final selectedTeamId = data?['selectedTeamId'] as String?;
    if (!snapshot.exists || selectedTeamId == null || selectedTeamId.isEmpty) {
      await _ensureDefaultUserProfile();
      snapshot = await firestore
          .collection(usersCollection)
          .doc(currentUser.uid)
          .get();
    }
    return _openCIUserFromSnapshot(snapshot);
  }

  Stream<OpenCIUser> watchUser() {
    final currentUserId = ref.read(authProvider).value?.uid;
    if (currentUserId == null) return const Stream.empty();
    return firestore
        .collection(usersCollection)
        .doc(currentUserId)
        .snapshots()
        .map(_openCIUserFromSnapshot);
  }

  Future<void> updateSelectedTeamId(String teamId) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await firestore.collection(usersCollection).doc(currentUserId).set({
      'id': currentUserId,
      'selectedTeamId': teamId,
      'selectedRepository': null,
      'selectedBranch': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotificationPreference(
    NotificationPreference preference,
  ) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await firestore.collection(usersCollection).doc(currentUserId).set({
      'id': currentUserId,
      'notificationPreference': preference.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addFcmToken(String token) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await firestore.collection(usersCollection).doc(currentUserId).set({
      'id': currentUserId,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSelectedRepository({
    required String repository,
    required String defaultBranch,
  }) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    final canonicalRepository = canonicalRepositoryFullName(repository);
    await firestore.collection(usersCollection).doc(currentUserId).set({
      'id': currentUserId,
      'selectedRepository': canonicalRepository,
      'selectedBranch': defaultBranch,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSelectedBranch(String branch) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await firestore.collection(usersCollection).doc(currentUserId).set({
      'id': currentUserId,
      'selectedBranch': branch,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _ensureDefaultUserProfile() async {
    await firebaseFunctions.httpsCallable('ensureUserProfile').call<void>();
  }
}

OpenCIUser _openCIUserFromSnapshot(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  final data = snapshot.data();
  if (data == null) throw Exception('User profile not found');
  final selectedTeamId = data['selectedTeamId'] as String?;
  if (selectedTeamId == null || selectedTeamId.isEmpty) {
    throw Exception('Selected team is not configured');
  }
  return OpenCIUser(
    id: snapshot.id,
    selectedTeamId: selectedTeamId,
    notificationPreference: NotificationPreference.values.byName(
      data['notificationPreference'] as String? ??
          NotificationPreference.all.name,
    ),
    fcmTokens:
        (data['fcmTokens'] as List?)?.whereType<String>().toList() ?? const [],
    selectedRepository: switch (data['selectedRepository']) {
      final String repository => canonicalRepositoryFullName(repository),
      _ => null,
    },
    selectedBranch: data['selectedBranch'] as String?,
    udid: data['udid'] as String?,
  );
}
