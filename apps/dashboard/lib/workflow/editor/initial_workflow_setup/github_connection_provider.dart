import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openci_shared/callable_function_names.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

part 'github_connection_provider.g.dart';

@riverpod
bool isGitHubConnected(Ref ref) {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return false;
  return team.installationIds.isNotEmpty;
}

Future<void> launchGitHubSetup(WidgetRef ref) async {
  final team = ref.read(teamStateProvider).value;
  if (team == null) throw StateError('team is not loaded yet');

  final result = await firebaseFunctions
      .httpsCallable(createGitHubSetupUrlFunction)
      .call<Map<String, dynamic>>({'teamId': team.id});
  final urlValue = result.data['url'];
  if (urlValue is! String || urlValue.isEmpty) {
    throw StateError('GitHub setup URL was not returned');
  }
  await url_launcher.launchUrl(Uri.parse(urlValue));
}
