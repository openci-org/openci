import 'package:dashboard/auth/auth_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

enum NotificationPreference {
  all,
  successOnly,
  failureOnly,
  none
  ;

  String toDbValue() {
    switch (this) {
      case NotificationPreference.all:
        return 'all';
      case NotificationPreference.successOnly:
        return 'success_only';
      case NotificationPreference.failureOnly:
        return 'failure_only';
      case NotificationPreference.none:
        return 'none';
    }
  }

  static NotificationPreference fromDbValue(String value) {
    switch (value) {
      case 'all':
        return NotificationPreference.all;
      case 'success_only':
        return NotificationPreference.successOnly;
      case 'failure_only':
        return NotificationPreference.failureOnly;
      case 'none':
        return NotificationPreference.none;
      default:
        return NotificationPreference.all;
    }
  }
}

@freezed
abstract class OpenCIUser with _$OpenCIUser {
  const factory OpenCIUser({
    required String id,
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
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }

    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> updateNotificationPreference(
    NotificationPreference preference,
  ) async {
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> updateSelectedTeamId(String teamId) async {
    throw UnimplementedError(
      'selected_team_id column does not exist in profiles yet',
    );
  }

  Future<void> addFcmToken(String token) async {
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }
}
