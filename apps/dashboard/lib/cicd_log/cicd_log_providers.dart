import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cicd_log_providers.g.dart';

@riverpod
Stream<List<CicdCommitGroup>> cicdCommitGroups(Ref ref) async* {
  final teamId = ref.watch(selectedTeamIdProvider).value;
  if (teamId == null) {
    yield const [];
    return;
  }

  final api = ref.watch(openciApiServiceProvider);

  await ref.watch(authedFirebaseIdTokenProvider.future);

  Future<List<CicdCommitGroup>> fetchGroups() async {
    try {
      final response = await api.getCommitGroups(teamId, 100);
      if (response.isSuccessful) {
        return response.body ?? const [];
      }
      // ignore: avoid_print
      print('API Error: ${response.statusCode} - ${response.error}');
      return const [];
    } catch (e, s) {
      // ignore: avoid_print
      print('Fetch Error: $e');
      // ignore: avoid_print
      print(s);
      return const [];
    }
  }

  final initial = await fetchGroups();
  yield initial;

  yield* Stream.periodic(const Duration(seconds: 5))
      .asyncMap((_) async {
        return await fetchGroups();
      })
      .distinct(
        (prev, next) => const DeepCollectionEquality().equals(prev, next),
      );
}
