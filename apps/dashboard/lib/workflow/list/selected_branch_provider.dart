import 'package:dashboard/shared_preferences_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_branch_provider.g.dart';

@riverpod
class SelectedBranch extends _$SelectedBranch {
  @override
  Future<String?> build() async {
    final teamId = await ref.watch(selectedTeamIdProvider.future);
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('selected_branch_$teamId');
  }

  Future<void> save(String branch) async {
    final teamId = await ref.read(selectedTeamIdProvider.future);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('selected_branch_$teamId', branch);
    state = AsyncData(branch);
  }
}
