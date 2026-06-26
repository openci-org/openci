import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/github/repository_aliases.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

@freezed
abstract class OpenCIUser with _$OpenCIUser {
  const factory OpenCIUser({
    required String id,
    required String selectedTeamId,
    String? selectedRepository,
    String? selectedBranch,
    @Default({}) Map<String, String> teamUdids,
    @Default({}) Map<String, String> teamDeviceProducts,
    @Default({}) Map<String, String> teamDeviceOsVersions,
  }) = _OpenCIUser;

  const OpenCIUser._();

  String? get currentTeamUdid => teamUdids[selectedTeamId];
  String? get currentTeamDeviceProduct => teamDeviceProducts[selectedTeamId];
  String? get currentTeamDeviceOsVersion =>
      teamDeviceOsVersions[selectedTeamId];

  factory OpenCIUser.fromJson(Map<String, Object?> json) =>
      _$OpenCIUserFromJson(json);
}

@Riverpod(keepAlive: true)
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
    final currentUserId = ref.watch(nonNullCurrentUserIdProvider);
    var snapshot = await firestore
        .collection(usersCollection)
        .doc(currentUserId)
        .get();
    final data = snapshot.data();
    final selectedTeamId = data?['selectedTeamId'] as String?;
    if (!snapshot.exists || selectedTeamId == null || selectedTeamId.isEmpty) {
      await _ensureDefaultUserProfile();
      snapshot = await firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .get();
    }
    return _openCIUserFromSnapshot(snapshot);
  }

  Stream<OpenCIUser> watchUser() {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null) return const Stream.empty();
    return firestore
        .collection(usersCollection)
        .doc(currentUserId)
        .snapshots()
        .map(_openCIUserFromSnapshot);
  }

  Future<void> updateSelectedTeamId(String teamId) async {
    final currentUserId = ref.watch(nonNullCurrentUserIdProvider);
    await firestore.collection(usersCollection).doc(currentUserId).set({
      'id': currentUserId,
      'selectedTeamId': teamId,
      'selectedRepository': null,
      'selectedBranch': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSelectedRepository({
    required String repository,
    required String defaultBranch,
  }) async {
    final currentUserId = ref.watch(nonNullCurrentUserIdProvider);
    final canonicalRepository = canonicalRepositoryFullName(repository);
    await firestore.collection(usersCollection).doc(currentUserId).set({
      'id': currentUserId,
      'selectedRepository': canonicalRepository,
      'selectedBranch': defaultBranch,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSelectedBranch(String branch) async {
    final currentUserId = ref.watch(nonNullCurrentUserIdProvider);
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

    selectedRepository: switch (data['selectedRepository']) {
      final String repository => canonicalRepositoryFullName(repository),
      _ => null,
    },
    selectedBranch: data['selectedBranch'] as String?,
    teamUdids: Map<String, String>.from(data['teamUdids'] as Map? ?? {}),
    teamDeviceProducts: Map<String, String>.from(
      data['teamDeviceProducts'] as Map? ?? {},
    ),
    teamDeviceOsVersions: Map<String, String>.from(
      data['teamDeviceOsVersions'] as Map? ?? {},
    ),
  );
}
