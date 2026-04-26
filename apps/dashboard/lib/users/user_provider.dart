import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/dataconnect.dart';
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
  }) = _OpenCIUser;
  factory OpenCIUser.fromJson(Map<String, Object?> json) =>
      _$OpenCIUserFromJson(json);
}

@riverpod
class User extends _$User {
  @override
  Stream<OpenCIUser> build() => fetchUser();

  Stream<OpenCIUser> fetchUser() {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    return dataConnector.getCurrentUser().ref().subscribe().map((result) {
      final user = result.data.user;
      if (user == null) throw Exception('User profile not found');
      final selectedTeamId = user.selectedTeamId;
      if (selectedTeamId == null || selectedTeamId.isEmpty) {
        throw Exception('Selected team is not configured');
      }
      return OpenCIUser(
        id: user.id,
        selectedTeamId: selectedTeamId,
        notificationPreference: NotificationPreference.values.byName(
          user.notificationPreference ?? NotificationPreference.all.name,
        ),
        fcmTokens: user.fcmTokens ?? const [],
        selectedRepository: user.selectedRepository,
        selectedBranch: user.selectedBranch,
      );
    });
  }

  Future<void> updateSelectedTeamId(String teamId) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await dataConnector.updateCurrentUserSelectedTeam(teamId: teamId).execute();
  }

  Future<void> updateNotificationPreference(
    NotificationPreference preference,
  ) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await dataConnector
        .updateCurrentUserNotificationPreference(
          notificationPreference: preference.name,
        )
        .execute();
  }

  Future<void> addFcmToken(String token) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await dataConnector.addCurrentUserFcmToken(token: token).execute();
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
    await dataConnector
        .updateCurrentUserRepositorySelection(
          repository: repository,
          branch: defaultBranch,
        )
        .execute();
  }

  Future<void> updateSelectedBranch(String branch) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await dataConnector
        .updateCurrentUserSelectedBranch(branch: branch)
        .execute();
  }
}
