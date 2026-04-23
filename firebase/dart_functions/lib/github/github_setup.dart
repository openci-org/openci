import 'package:openci_shared/firestore_paths.dart';
import 'package:shelf/shelf.dart';

import '../firebase.dart';
import '../util/logger.dart';

Future<Response> handleGitHubSetup(Request request) async {
  try {
    final installationId = request.url.queryParameters['installation_id'];
    final teamId = request.url.queryParameters['state'];
    final setupAction = request.url.queryParameters['setup_action'];

    logInfo('GitHub Setup callback received', {
      'installationId': installationId,
      'teamId': teamId,
      'setupAction': setupAction,
    });

    if (installationId == null || teamId == null) {
      return Response(400, body: 'Missing installation_id or state (teamId)');
    }

    final teamRef = firestore.collection(teamsCollection).doc(teamId);
    final teamDoc = await teamRef.get();

    if (!teamDoc.exists) {
      return Response.notFound('Team not found');
    }

    final teamData = teamDoc.data()!;
    final currentIds =
        (teamData['installationIds'] as List<dynamic>?)?.cast<int>() ?? [];
    final newId = int.parse(installationId);
    if (!currentIds.contains(newId)) {
      currentIds.add(newId);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await teamRef.update({'installationIds': currentIds, 'updatedAt': now});

    logInfo('Linked installationId $installationId to team $teamId');

    return Response.ok(
      '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>OpenCI - GitHub Connected</title>
    <style>
      body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100dvh; margin: 0; background: #0d1117; color: #f0f6fc; }
      .container { text-align: center; padding: 24px; }
      h1 { font-size: 24px; margin-bottom: 8px; }
      p { color: #8b949e; font-size: 16px; }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>✅ GitHub Connected!</h1>
      <p>You can close this page and return to the app.</p>
    </div>
  </body>
</html>
      ''',
      headers: {'Content-Type': 'text/html'},
    );
  } catch (e) {
    logError('Failed to link GitHub installation', null, e);
    return Response.internalServerError(body: 'Internal server error');
  }
}
