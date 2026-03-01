import 'dart:convert';

import 'package:http/http.dart' as http;

import 'supabase_client.dart';

Future<void> updateCheckRunStatus(
  Build build, {
  required String status,
  String? conclusion,
  String? summary,
}) async {
  if (build.checkRunId == null || build.installationToken == null) return;

  final url = Uri.parse(
    'https://api.github.com/repos/${build.githubOwner}/${build.githubRepo}/check-runs/${build.checkRunId}',
  );

  final body = <String, dynamic>{'status': status};

  if (status == 'in_progress') {
    body['started_at'] = DateTime.now().toUtc().toIso8601String();
  } else if (status == 'completed') {
    body['conclusion'] = conclusion;
    body['completed_at'] = DateTime.now().toUtc().toIso8601String();
    if (summary != null) {
      body['output'] = {
        'title': conclusion == 'success' ? 'Build Passed' : 'Build Failed',
        'summary': summary,
      };
    }
  }

  try {
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'token ${build.installationToken}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'OpenCI-Worker',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 300) {
      print(
        'Failed to update check run: ${response.statusCode} ${response.body}',
      );
    }
  } catch (e) {
    print('Failed to update check run: $e');
  }
}
