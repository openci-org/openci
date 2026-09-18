import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_team_provider.g.dart';

@riverpod
class SelectedTeamId extends _$SelectedTeamId {
  String _key(String profileId) => 'selected_team_id:$profileId';

  @override
  Future<String?> build() async {
    final ref = this.ref;
    final prefs = ref.watch(sharedPreferencesProvider);
    final store = ref.watch(connectionStoreProvider);
    final profile = await ref.watch(
      activeConnectionProfileProvider(store).future,
    );
    if (!ref.mounted) return null;

    final teams = await ref.watch(teamListProvider.future);
    if (!ref.mounted || teams.isEmpty) {
      return null;
    }

    final selectedId = prefs.getString(_key(profile.id));
    if (selectedId != null && teams.any((t) => t.id == selectedId)) {
      return selectedId;
    }

    final firstTeamId = teams.first.id;
    await prefs.setString(_key(profile.id), firstTeamId);
    return firstTeamId;
  }

  Future<void> saveSelectedTeamId(String teamId) async {
    final ref = this.ref;
    final prefs = ref.read(sharedPreferencesProvider);
    final store = ref.read(connectionStoreProvider);
    final profile = await ref.read(
      activeConnectionProfileProvider(store).future,
    );
    await prefs.setString(_key(profile.id), teamId);
    if (ref.mounted) state = AsyncData(teamId);
  }
}
