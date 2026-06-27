import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

@freezed
abstract class OpenCIUser with _$OpenCIUser {
  const factory OpenCIUser({
    required String id,
    @Default({}) Map<String, String> teamUdids,
    @Default({}) Map<String, String> teamDeviceProducts,
    @Default({}) Map<String, String> teamDeviceOsVersions,
  }) = _OpenCIUser;

  const OpenCIUser._();

  String? currentTeamUdid(String? selectedTeamId) =>
      selectedTeamId != null ? teamUdids[selectedTeamId] : null;
  String? currentTeamDeviceProduct(String? selectedTeamId) =>
      selectedTeamId != null ? teamDeviceProducts[selectedTeamId] : null;
  String? currentTeamDeviceOsVersion(String? selectedTeamId) =>
      selectedTeamId != null ? teamDeviceOsVersions[selectedTeamId] : null;

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
    if (!snapshot.exists) {
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

  Future<void> _ensureDefaultUserProfile() async {
    await firebaseFunctions.httpsCallable('ensureUserProfile').call<void>();
  }
}

OpenCIUser _openCIUserFromSnapshot(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  final data = snapshot.data();
  if (data == null) throw Exception('User profile not found');
  return OpenCIUser(
    id: snapshot.id,
    teamUdids: Map<String, String>.from(data['teamUdids'] as Map? ?? {}),
    teamDeviceProducts: Map<String, String>.from(
      data['teamDeviceProducts'] as Map? ?? {},
    ),
    teamDeviceOsVersions: Map<String, String>.from(
      data['teamDeviceOsVersions'] as Map? ?? {},
    ),
  );
}
