import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import Anthropic from "@anthropic-ai/sdk";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

const SYSTEM_PROMPT = `You are an AI assistant that helps developers create CI/CD workflow files for OpenCI.

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

interface ChatMessageInput {
	role: "user" | "assistant";
	content: string;
}

interface GenerateAiWorkflowRequest {
	teamId: string;
	messages: ChatMessageInput[];
	repoContext?: string;
}

export const generateAiWorkflowResponse = onCall(
	{
		region: "asia-northeast1",
		secrets: [ANTHROPIC_API_KEY],
		timeoutSeconds: 60,
	},
	async (request) => {
		if (!request.auth) {
			throw new HttpsError("unauthenticated", "Unauthenticated");
		}

		const { teamId, messages, repoContext } = request.data as GenerateAiWorkflowRequest;

		if (!teamId || !messages || messages.length === 0) {
			throw new HttpsError("invalid-argument", "Missing required fields");
		}

		const teamRef = db.collection(teamsCollectionPath).doc(teamId);
		const teamDoc = await teamRef.get();
		if (!teamDoc.exists) {
			throw new HttpsError("not-found", "Team not found");
		}
		const members: string[] = teamDoc.data()!.members || [];
		if (!members.includes(request.auth.uid)) {
			throw new HttpsError("permission-denied", "You are not a member of this team");
		}

		try {
			const client = new Anthropic({
				apiKey: ANTHROPIC_API_KEY.value(),
			});

			const systemPrompt = repoContext
				? `${SYSTEM_PROMPT}\n\n--- Repository Context ---\nThe user is working on the following repository. Use this information to suggest appropriate workflow steps and commands.\n\n${repoContext}`
				: SYSTEM_PROMPT;

			const response = await client.messages.create({
				model: "claude-opus-4-6",
				max_tokens: 4096,
				system: systemPrompt,
				messages: messages.map((msg) => ({
					role: msg.role,
					content: msg.content,
				})),
			});

			const responseText = response.content
				.filter((block) => block.type === "text")
				.map((block) => ("text" in block ? block.text : ""))
				.join("");

			let yaml: string | null = null;
			const yamlMatch = responseText.match(/<<<YAML>>>\s*([\s\S]*?)\s*<<<END_YAML>>>/);
			if (yamlMatch) {
				yaml = yamlMatch[1].trim();
			}

			const displayText = responseText
				.replace(/<<<YAML>>>[\s\S]*?<<<END_YAML>>>/, "")
				.trim();

			return {
				message: displayText,
				yaml: yaml,
			};
		} catch (error) {
			if (error instanceof HttpsError) throw error;
			logger.error("Failed to generate workflow", { error: String(error), stack: (error as Error)?.stack });
			throw new HttpsError("internal", `Failed to generate workflow: ${error}`);
		}
	},
);
