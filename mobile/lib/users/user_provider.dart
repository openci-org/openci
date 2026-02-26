import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/supabase/supabase_provider.dart';
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
    required String selectedOrgId,
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
    final supabase = ref.read(supabaseClientProvider);
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }

    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', currentUserId)
        .map((rows) {
          if (rows.isEmpty) throw Exception('User profile not found');
          final row = rows.first;
          return _profileToUser(row, currentUserId);
        });
  }

  OpenCIUser _profileToUser(Map<String, dynamic> row, String userId) {
    final fcmTokens =
        (row['fcm_tokens'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    return OpenCIUser(
      id: userId,
      selectedOrgId: '',
      notificationPreference: NotificationPreference.fromDbValue(
        row['notification_preference'] as String? ?? 'all',
      ),
      fcmTokens: fcmTokens,
    );
  }

  Future<void> updateNotificationPreference(
    NotificationPreference preference,
  ) async {
    final supabase = ref.read(supabaseClientProvider);
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await supabase
        .from('profiles')
        .update({
          'notification_preference': preference.toDbValue(),
        })
        .eq('id', currentUserId);
  }

  Future<void> updateSelectedTeamId(String teamId) async {
    final supabase = ref.read(supabaseClientProvider);
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await supabase
        .from('profiles')
        .update({'selected_org_id': teamId})
        .eq('id', currentUserId);
  }

  Future<void> addFcmToken(String token) async {
    final supabase = ref.read(supabaseClientProvider);
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    final row = await supabase
        .from('profiles')
        .select('fcm_tokens')
        .eq('id', currentUserId)
        .single();
    final existingTokens = List<String>.from(row['fcm_tokens'] as List? ?? []);
    if (!existingTokens.contains(token)) {
      existingTokens.add(token);
      await supabase
          .from('profiles')
          .update({
            'fcm_tokens': existingTokens,
          })
          .eq('id', currentUserId);
    }
  }
}
