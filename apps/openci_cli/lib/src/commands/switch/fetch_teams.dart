import 'dart:io';

import 'package:openci_shared/openci_shared.dart';

import '../../teams/teams_api.dart';

Future<List<Team>> fetchTeams(TeamsApi api) async {
  final response = await api.getTeams();
  if (response.statusCode != HttpStatus.ok) {
    throw TeamsHttpException(response.statusCode);
  }
  final data = response.body;
  if (data?['success'] != true || data?['teams'] is! List) {
    throw const FormatException('Invalid teams response');
  }
  final teams = (data!['teams'] as List)
      .map((team) => Team.fromJson(Map<String, dynamic>.from(team as Map)))
      .toList();
  if (teams.any((team) => team.id.trim().isEmpty)) {
    throw const FormatException('Invalid teams response');
  }

  teams.sort((a, b) {
    final byName = a.name.compareTo(b.name);
    return byName != 0 ? byName : a.id.compareTo(b.id);
  });
  return teams;
}

class TeamsHttpException implements Exception {
  const TeamsHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Failed to fetch teams (HTTP $statusCode).';
}
