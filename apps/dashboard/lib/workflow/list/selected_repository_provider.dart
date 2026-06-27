import 'package:dashboard/shared_preferences_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_repository_provider.g.dart';

@riverpod
class SelectedRepository extends _$SelectedRepository {
  @override
  Future<String?> build() async {
    final teamId = await ref.watch(selectedTeamIdProvider.future);
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('selected_repository_$teamId');
  }

  Future<void> save(String repository) async {
    final teamId = await ref.read(selectedTeamIdProvider.future);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('selected_repository_$teamId', repository);
    state = AsyncData(repository);
  }
}
