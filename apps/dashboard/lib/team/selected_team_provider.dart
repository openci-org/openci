import 'package:dashboard/shared_preferences_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_team_provider.g.dart';

@riverpod
class SelectedTeamId extends _$SelectedTeamId {
  static const _key = 'selected_team_id';

  @override
  Future<String> build() async {
    final teams = await ref.watch(teamListProvider.future);
    if (teams.isEmpty) {
      throw StateError("No teams available");
    }

    final selectedId = fetchSelectedId();
    if (selectedId != null && teams.any((t) => t.id == selectedId)) {
      return selectedId;
    }

    final firstTeamId = teams.first.id;
    await saveSelectedTeamId(firstTeamId);
    return firstTeamId;
  }

  String? fetchSelectedId() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedId = prefs.getString(_key);
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }
    return null;
  }

  Future<void> saveSelectedTeamId(String teamId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, teamId);
    state = AsyncData(teamId);
  }
}
