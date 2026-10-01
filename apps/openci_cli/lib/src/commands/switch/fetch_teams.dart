import 'dart:io';

import 'package:openci_shared/openci_shared.dart';

Future<List<Team>> fetchTeams(OpenCIApiService api) async {
  final response = await api.getTeams();
  if (response.statusCode != HttpStatus.ok) {
    throw TeamsHttpException(response.statusCode);
  }
  final teams = response.body;
  if (teams == null || teams.any((team) => team.id.trim().isEmpty)) {
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
