import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/api/ws_uri_builder.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket/web_socket.dart';

part 'cicd_log_providers.g.dart';

@riverpod
class CicdCommitGroups extends _$CicdCommitGroups {
  @override
  Stream<List<CicdCommitGroup>> build() async* {
    final teamId = ref.watch(selectedTeamIdProvider).value;
    if (teamId == null || teamId.isEmpty) {
      throw StateError('Selected team ID is missing or empty.');
    }

    final initialData = await _fetchGroups(teamId);
    yield initialData;

    final wsUri = await buildAuthedWebSocketUri(
      ref,
      '/builds/commits/stream',
      queryParameters: {'teamId': teamId},
    );

    final socket = await WebSocket.connect(wsUri);
    ref.onDispose(socket.close);

    await for (final event in socket.events) {
      switch (event) {
        case TextDataReceived(:final text):
          final rawList = jsonDecode(text) as List<dynamic>;
          final groups = rawList
              .map(
                (item) =>
                    CicdCommitGroup.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          yield groups;
        case CloseReceived():
        case BinaryDataReceived():
          break;
      }
    }
  }

  Future<List<CicdCommitGroup>> _fetchGroups(String teamId) async {
    final api = ref.read(openciApiServiceProvider);
    const limit = 100;
    final response = await api.getCommitGroups(teamId, limit);
    if (!response.isSuccessful || response.body == null) {
      throw Exception(
        'Failed to fetch commit groups: ${response.statusCode} - ${response.error}',
      );
    }
    return response.body!;
  }
}
