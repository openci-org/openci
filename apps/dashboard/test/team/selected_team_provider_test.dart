import 'dart:async';

import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ConnectionProfile profile(String id) => ConnectionProfile(
  id: id,
  name: id,
  apiUrl: 'https://$id.example.com',
  firebase: const {},
);

Team team(String id) => Team(
  id: id,
  name: id,
  members: const [],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cloud = profile('cloud');
  final selfHosted = profile('self-hosted');
  final first = team('first');
  final second = team('second');
  late SharedPreferences prefs;
  late ConnectionStore store;
  late Map<String, FutureOr<List<Team>>> teams;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'selected_team_id': second.id});
    prefs = await SharedPreferences.getInstance();
    store = ConnectionStore(prefs, cloud);
    await store.save(
      ConnectionSnapshot(profiles: [cloud, selfHosted], activeId: cloud.id),
    );
    teams = {
      cloud.id: [first, second],
      selfHosted.id: [first, second],
    };
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        connectionStoreProvider.overrideWithValue(store),
        teamListProvider.overrideWith((ref) async {
          final profile = await ref.watch(
            activeConnectionProfileProvider(store).future,
          );
          return teams[profile.id]!;
        }),
      ],
    );
    container.listen(selectedTeamIdProvider, (_, _) {});
    return container;
  }

  Future<void> selectProfile(ProviderContainer container, String id) =>
      container
          .read(activeConnectionProfileProvider(store).notifier)
          .select(id);

  test(
    'selects the first team without migrating the legacy selection',
    () async {
      final container = createContainer();

      expect(await container.read(selectedTeamIdProvider.future), first.id);
      expect(prefs.getString('selected_team_id:cloud'), first.id);
      expect(prefs.getString('selected_team_id:self-hosted'), isNull);
      expect(prefs.getString('selected_team_id'), second.id);
    },
  );

  test(
    'saves and restores an independent selection for each profile',
    () async {
      final container = createContainer();
      await container.read(selectedTeamIdProvider.future);
      await container
          .read(selectedTeamIdProvider.notifier)
          .saveSelectedTeamId(second.id);

      await selectProfile(container, selfHosted.id);
      expect(await container.read(selectedTeamIdProvider.future), first.id);
      await container
          .read(selectedTeamIdProvider.notifier)
          .saveSelectedTeamId(first.id);
      expect(prefs.getString('selected_team_id:cloud'), second.id);
      expect(prefs.getString('selected_team_id:self-hosted'), first.id);

      await selectProfile(container, cloud.id);
      expect(await container.read(selectedTeamIdProvider.future), second.id);
      await selectProfile(container, selfHosted.id);
      expect(await container.read(selectedTeamIdProvider.future), first.id);
    },
  );

  test('restores the saved profile and team after restarting', () async {
    final container = createContainer();
    await container.read(selectedTeamIdProvider.future);
    await selectProfile(container, selfHosted.id);
    await container.read(selectedTeamIdProvider.future);
    await container
        .read(selectedTeamIdProvider.notifier)
        .saveSelectedTeamId(second.id);
    container.dispose();

    store = ConnectionStore(prefs, cloud);
    final restarted = createContainer();
    expect(await restarted.read(selectedTeamIdProvider.future), second.id);
    expect(store.load().activeId, selfHosted.id);
    expect(prefs.getString('selected_team_id:cloud'), first.id);
  });

  test(
    'replaces an unavailable saved team with the first available team',
    () async {
      await prefs.setString('selected_team_id:self-hosted', 'removed-team');
      await prefs.setString('selected_team_id:cloud', second.id);
      final container = createContainer();
      await container.read(selectedTeamIdProvider.future);

      await selectProfile(container, selfHosted.id);

      expect(await container.read(selectedTeamIdProvider.future), first.id);
      expect(prefs.getString('selected_team_id:self-hosted'), first.id);
      expect(prefs.getString('selected_team_id:cloud'), second.id);
    },
  );

  test('returns no selection when the selected profile has no teams', () async {
    teams[selfHosted.id] = [];
    final container = createContainer();
    await container.read(selectedTeamIdProvider.future);

    await selectProfile(container, selfHosted.id);

    expect(await container.read(selectedTeamIdProvider.future), isNull);
    expect(prefs.getString('selected_team_id:self-hosted'), isNull);
    expect(prefs.getString('selected_team_id:cloud'), first.id);
  });

  test(
    'ignores a previous profile team lookup that completes after switching',
    () async {
      final pending = Completer<List<Team>>();
      teams[cloud.id] = pending.future;
      final container = createContainer();
      await container.pump();

      await selectProfile(container, selfHosted.id);
      expect(await container.read(selectedTeamIdProvider.future), first.id);
      pending.complete([team('late-team')]);
      await container.pump();

      expect(container.read(selectedTeamIdProvider).requireValue, first.id);
      expect(prefs.getString('selected_team_id:cloud'), isNull);
      expect(prefs.getString('selected_team_id:self-hosted'), first.id);
    },
  );
}
