import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';

import '../secret_manager.dart' show accessSecret;
import '../util/logger.dart';
import '../util/team_auth.dart';

class GenerateAiWorkflowRequest {
  const GenerateAiWorkflowRequest({
    required this.teamId,
    required this.messages,
    this.repoContext,
  });

  factory GenerateAiWorkflowRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final messages = json['messages'] as List<dynamic>?;
    if (teamId == null ||
        teamId.isEmpty ||
        messages == null ||
        messages.isEmpty) {
      throw InvalidArgumentError('Missing required fields');
    }
    return GenerateAiWorkflowRequest(
      teamId: teamId,
      messages: messages.map((m) => m as Map<String, dynamic>).toList(),
      repoContext: json['repoContext'] as String?,
    );
  }

  final String teamId;
  final List<Map<String, dynamic>> messages;
  final String? repoContext;
}

const _systemPrompt =
    r'''You are an AI assistant that helps developers create CI/CD workflow files for OpenCI.

OpenCI workflow YAML format is similar to GitHub Actions but simplified. Here is the structure:

```yaml
name: workflow-name

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    steps:
      - name: Step Name
        run: echo "command here"
      - name: Another Step
        uses: some/action@v1
        with:
          key: value
```

Available triggers: push, pull_request, tag, release.
push and pull_request support "branches" list. tag and release do not.

Step types:
- "run": executes a shell command (can be multi-line with |)
- "uses": references a reusable action with optional "with" parameters

IMPORTANT rules for generated YAML:
- The first step MUST always be "uses: actions/checkout@v4" to check out the repository code. Without this, the working directory will be empty and all subsequent steps will fail.
- Every job MUST have "runs-on: macos-latest". Always use macos-latest, no other value.

Common workflows by project type:
- Flutter: flutter pub get, flutter analyze, flutter test, flutter build ipa/appbundle
- iOS Native: pod install, swiftlint, xcodebuild test, xcodebuild archive
- Android Native: ./gradlew lint, ./gradlew test, ./gradlew assembleRelease
- Node.js: npm ci, npm run lint, npm test, npm run build
- React Native: npm ci, npx react-native build-android, npx react-native build-ios

Your behavior:
1. Guide the user step by step to create a workflow. Ask about their project type, what they want to do (build, test, lint, deploy), and when it should run (triggers).
2. Keep responses concise and friendly. One question at a time.
3. When you have enough information, generate the complete YAML.
4. When you include the generated YAML, wrap it EXACTLY like this:
   <<<YAML>>>
   (yaml content here)
   <<<END_YAML>>>
5. After generating YAML, offer to make changes.
6. Always respond in the same language the user is using.''';

Future<Map<String, dynamic>> handleGenerateAiWorkflow(
  CallableRequest<GenerateAiWorkflowRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  await verifyTeamMembership(auth: request.auth, teamId: request.data.teamId);

  try {
    final apiKey = await accessSecret('ANTHROPIC_API_KEY');

    final systemPrompt = request.data.repoContext != null
        ? '$_systemPrompt\n\n--- Repository Context ---\n'
              'The user is working on the following repository. '
              'Use this information to suggest appropriate workflow steps and commands.\n\n'
              '${request.data.repoContext}'
        : _systemPrompt;

    final dio = Dio();
    try {
      final apiResponse = await dio.post<Map<String, dynamic>>(
        'https://api.anthropic.com/v1/messages',
        data: {
          'model': 'claude-opus-4-6',
          'max_tokens': 4096,
          'system': systemPrompt,
          'messages': request.data.messages
              .map((msg) => {'role': msg['role'], 'content': msg['content']})
              .toList(),
        },
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
        ),
      );

      final content = apiResponse.data?['content'] as List<dynamic>? ?? [];
      final responseText = content
          .where((block) => (block as Map<String, dynamic>)['type'] == 'text')
          .map((block) => (block as Map<String, dynamic>)['text'] as String)
          .join('');

      String? yaml;
      final yamlMatch = RegExp(
        r'<<<YAML>>>\s*([\s\S]*?)\s*<<<END_YAML>>>',
      ).firstMatch(responseText);
      if (yamlMatch != null) {
        yaml = yamlMatch.group(1)?.trim();
      }

      final displayText = responseText
          .replaceAll(RegExp(r'<<<YAML>>>[\s\S]*?<<<END_YAML>>>'), '')
          .trim();

      return <String, dynamic>{'message': displayText, 'yaml': yaml};
    } finally {
      dio.close();
    }
  } catch (e) {
    if (e is HttpsError) rethrow;
    await logError('Failed to generate workflow', null, e);
    throw InternalError('Failed to generate workflow: $e');
  }
}
