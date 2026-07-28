import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final serverUrl =
      Platform.environment['OPENCI_SERVER_URL'] ?? 'http://localhost:8080';
  final userId =
      Platform.environment['USER_ID'] ??
      Platform.environment['USER_UID'] ??
      args
          .firstWhere((arg) => arg.startsWith('--user-id='), orElse: () => '')
          .replaceFirst('--user-id=', '')
          .trim();
  final teamId =
      Platform.environment['TEAM_ID'] ??
      args
          .firstWhere((arg) => arg.startsWith('--team-id='), orElse: () => '')
          .replaceFirst('--team-id=', '')
          .trim();

  print('🌱 Ensuring test team via API ($serverUrl/internal/seed/teams)...');

  try {
    final payload = <String, dynamic>{
      if (userId.isNotEmpty) 'userId': userId,
      if (teamId.isNotEmpty) 'teamId': teamId,
    };

    final response = await http.post(
      Uri.parse('$serverUrl/internal/seed/teams'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Test team configured successfully via API.');
      print('   Body: ${response.body}');
    } else {
      print('❌ Failed to configure test team via API!');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
      exit(1);
    }
  } catch (e, st) {
    print('❌ Error connecting to openci-server API: $e');
    print(st);
    exit(1);
  }
}
