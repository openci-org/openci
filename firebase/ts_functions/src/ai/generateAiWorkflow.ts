import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { createAnthropicMessage } from "./anthropic";
import { verifyTeamMembership } from "../team/teamAuth";

interface GenerateAiWorkflowRequest {
  teamId: string;
  messages: Array<{ role: string; content: string }>;
  repoContext?: string;
}

const systemPrompt = `You are an AI assistant that helps developers create CI/CD workflow files for OpenCI.

OpenCI workflow YAML format is similar to GitHub Actions but simplified. Here is the structure:

\`\`\`yaml
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
\`\`\`

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
6. Always respond in the same language the user is using.`;

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

export const generateAiWorkflowResponse = onCall<
  GenerateAiWorkflowRequest,
  Promise<{ message: string; yaml?: string }>
>(
  { timeoutSeconds: 60 },
  async (request) => {
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    if (!Array.isArray(request.data?.messages) || request.data.messages.length === 0) {
      throw new HttpsError("invalid-argument", "messages is required");
    }
    await verifyTeamMembership(request.auth, teamId);

    try {
      const prompt = request.data.repoContext
        ? `${systemPrompt}\n\n--- Repository Context ---\nThe user is working on the following repository. Use this information to suggest appropriate workflow steps and commands.\n\n${request.data.repoContext}`
        : systemPrompt;
      const responseText = await createAnthropicMessage({
        model: "claude-opus-4-6",
        maxTokens: 4096,
        system: prompt,
        messages: request.data.messages.map((message) => ({
          role: message.role,
          content: message.content,
        })),
      });

      const yamlMatch = /<<<YAML>>>\s*([\s\S]*?)\s*<<<END_YAML>>>/u.exec(responseText);
      const yaml = yamlMatch?.[1]?.trim();
      const message = responseText.replace(/<<<YAML>>>[\s\S]*?<<<END_YAML>>>/u, "").trim();
      return { message, ...(yaml ? { yaml } : {}) };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to generate workflow", { teamId, error });
      throw new HttpsError("internal", `Failed to generate workflow: ${String(error)}`);
    }
  },
);
