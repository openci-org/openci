import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final serverUrl =
      Platform.environment['OPENCI_SERVER_URL'] ?? 'http://localhost:8080';
  final teamId =
      Platform.environment['TEAM_ID'] ??
      args
          .firstWhere((arg) => arg.startsWith('--team-id='), orElse: () => '')
          .replaceFirst('--team-id=', '')
          .trim();

  print('🧹 Clearing build jobs via API ($serverUrl/internal/seed/jobs)...');

  try {
    final uri = Uri.parse('$serverUrl/internal/seed/jobs').replace(
      queryParameters: {
        if (teamId.isNotEmpty) 'teamId': teamId,
      },
    );

    final response = await http.delete(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Build jobs cleared successfully.');
      print('   Body: ${response.body}');
    } else {
      print('❌ Failed to clear build jobs!');
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
