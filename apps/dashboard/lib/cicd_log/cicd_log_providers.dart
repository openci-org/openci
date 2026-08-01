import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'cicd_log_providers.g.dart';

@riverpod
Stream<List<CicdCommitGroup>> cicdCommitGroups(Ref ref) async* {
  final teamId = ref.watch(selectedTeamIdProvider).value;
  if (teamId == null || teamId.isEmpty) {
    yield const [];
    return;
  }

  final api = ref.watch(openciApiServiceProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final token = await auth.currentUser?.getIdToken();

  Future<List<CicdCommitGroup>> fetchGroups() async {
    try {
      final response = await api.getCommitGroups(teamId, 100);
      if (response.isSuccessful) {
        return response.body ?? const [];
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  final initial = await fetchGroups();
  yield initial;

  final baseUrl = api.client.baseUrl.toString();
  final wsScheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
  final host = baseUrl
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceAll('/', '');

  final queryParams = <String, String>{
    'teamId': teamId,
    if (token != null && token.isNotEmpty) 'token': token,
  };

  final wsUri = Uri(
    scheme: wsScheme,
    host: host.contains(':') ? host.split(':').first : host,
    port: host.contains(':') ? int.tryParse(host.split(':').last) : null,
    path: '/builds/commits/stream',
    queryParameters: queryParams,
  );

  WebSocketChannel? channel;

  try {
    channel = WebSocketChannel.connect(wsUri);
    await channel.ready;
    await for (final rawMessage in channel.stream) {
      try {
        final messageStr = rawMessage.toString();
        final rawList = jsonDecode(messageStr) as List<dynamic>;
        final groups = rawList
            .map(
              (item) => CicdCommitGroup.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        yield groups;
      } catch (_) {}
    }
  } catch (_) {
    // WebSocket 接続エラー時は初回データを維持し、未捕捉例外を出さない
  } finally {
    try {
      await channel?.sink.close();
    } catch (_) {}
  }
}
