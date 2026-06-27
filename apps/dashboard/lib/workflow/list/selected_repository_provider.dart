import 'package:dashboard/shared_preferences_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_repository_provider.g.dart';

@riverpod
class SelectedRepository extends _$SelectedRepository {
  @override
  String? build() {
    final teamId = ref.watch(selectedTeamIdProvider).value;
    if (teamId == null) return null;

    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('selected_repository_$teamId');
  }

  Future<void> save(String repository) async {
    final teamId = ref.read(selectedTeamIdProvider).value;
    if (teamId == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('selected_repository_$teamId', repository);
    state = repository;
  }
}
