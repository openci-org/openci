import 'dart:convert';

String encodeTeams(List<Object?> teams) => jsonEncode({
  'result': {'success': true, 'teams': teams},
});

String encodeTeamResponse(Object? body) =>
    body is List<Object?> ? encodeTeams(body) : jsonEncode(body);
