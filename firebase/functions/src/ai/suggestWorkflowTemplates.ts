import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  getInstallationToken,
  githubAppId,
  githubGet,
  githubPrivateKey,
} from "../github/githubApp.js";
import { getApiBaseUrlFromTeamData } from "../github/githubUrls.js";
import { verifyTeamMembership } from "../team/teamAuth.js";

interface SuggestWorkflowTemplatesRequest {
  teamId: string;
  repository: string;
  branch: string;
}

interface WorkflowSuggestion {
  title: string;
  description: string;
  fileName: string;
  steps: string[];
  requiredSecrets: string[];
  yaml: string;
}

interface SuggestWorkflowTemplatesResponse {
  repository: string;
  branch: string;
  headSha: string;
  detectedProjectType: string;
  analysisSummary: string;
  suggestions: WorkflowSuggestion[];
}

interface GitTreeResponse {
  sha?: unknown;
  tree?: Array<{
    path?: unknown;
    type?: unknown;
  }>;
  truncated?: unknown;
}

const excludedPathParts = new Set([
  ".git",
  ".dart_tool",
  ".firebase",
  ".next",
  ".turbo",
  "Pods",
  "build",
  "coverage",
  "dist",
  "node_modules",
  "vendor",
]);

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

function errorDetails(error: unknown): Record<string, unknown> {
  if (error instanceof Error) {
    const extraDetails = Object.fromEntries(
      Object.getOwnPropertyNames(error)
        .filter((key) => !["name", "message", "stack", "cause"].includes(key))
        .map((key) => [key, (error as unknown as Record<string, unknown>)[key]]),
    );
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
      cause: error.cause instanceof Error ? error.cause.message : error.cause,
      ...extraDetails,
    };
  }
  if (typeof error === "object" && error !== null) {
    return Object.fromEntries(
      Object.getOwnPropertyNames(error).map((key) => [
        key,
        (error as Record<string, unknown>)[key],
      ]),
    );
  }
  return { message: String(error) };
}

function getInstallationIds(teamData: FirebaseFirestore.DocumentData): number[] {
  const installationIds = Array.isArray(teamData.installationIds) ? teamData.installationIds : [];
  const ids = installationIds.filter((id): id is number => typeof id === "number");
  if (ids.length === 0) {
    throw new HttpsError("failed-precondition", "GitHub App is not installed for this team");
  }
  return ids;
}

function shouldSkipPath(path: string): boolean {
  return path.split("/").some((part) => excludedPathParts.has(part));
}

function directoryOf(path: string): string {
  const index = path.lastIndexOf("/");
  return index < 0 ? "." : path.slice(0, index);
}

function fileNameOf(path: string): string {
  return path.split("/").at(-1) ?? path;
}

function findDirectories(paths: string[], fileName: string): string[] {
  const directories = paths.filter((path) => fileNameOf(path) === fileName).map(directoryOf);
  return [...new Set(directories)].sort((a, b) => {
    if (a === ".") return -1;
    if (b === ".") return 1;
    return a.localeCompare(b);
  });
}

function hasFile(paths: Set<string>, directory: string, fileName: string): boolean {
  return paths.has(directory === "." ? fileName : `${directory}/${fileName}`);
}

function hasAnyPath(paths: string[], candidates: string[]): boolean {
  return paths.some((path) =>
    candidates.some((candidate) => path === candidate || path.startsWith(`${candidate}/`)),
  );
}

function yamlString(value: string): string {
  return `'${value.replace(/'/g, "''")}'`;
}

function workingDirectoryBlock(directory: string): string {
  if (directory === ".") return "";
  return `
defaults:
  run:
    working-directory: ${yamlString(directory)}
`;
}

function nodePackageManager(
  paths: Set<string>,
  directory: string,
): {
  setupSteps: string;
  installCommand: string;
  runCommand: string;
} {
  if (hasFile(paths, directory, "pnpm-lock.yaml")) {
    return {
      setupSteps: `      - name: Enable pnpm
        run: corepack enable pnpm
`,
      installCommand: "pnpm install --frozen-lockfile",
      runCommand: "pnpm",
    };
  }

  if (hasFile(paths, directory, "yarn.lock")) {
    return {
      setupSteps: `      - name: Enable yarn
        run: corepack enable yarn
`,
      installCommand: "yarn install --frozen-lockfile",
      runCommand: "yarn",
    };
  }

  return {
    setupSteps: "",
    installCommand: hasFile(paths, directory, "package-lock.json") ? "npm ci" : "npm install",
    runCommand: "npm run",
  };
}

function flutterSuggestion(directory: string): WorkflowSuggestion {
  return {
    title: "Flutter の基本チェック",
    description: "Flutter プロジェクト向けに依存関係の取得、静的解析、テストを実行します。",
    fileName: "flutter-check.yaml",
    steps: ["flutter pub get", "flutter analyze", "flutter test"],
    requiredSecrets: [],
    yaml: `name: Flutter checks

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop
${workingDirectoryBlock(directory)}
jobs:
  checks:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: openci-org/flutter-setup@v1
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze
      - name: Test
        run: flutter test
`,
  };
}

function dartSuggestion(directory: string): WorkflowSuggestion {
  return {
    title: "Dart の基本チェック",
    description: "Dart パッケージ向けに依存関係の取得、静的解析、テストを実行します。",
    fileName: "dart-check.yaml",
    steps: ["dart pub get", "dart analyze", "dart test"],
    requiredSecrets: [],
    yaml: `name: Dart checks

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop
${workingDirectoryBlock(directory)}
jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: openci-org/dart-setup@v1
      - name: Install dependencies
        run: dart pub get
      - name: Analyze
        run: dart analyze
      - name: Test
        run: dart test
`,
  };
}

function nodeSuggestion(
  paths: Set<string>,
  directory: string,
  firebaseFunctions: boolean,
): WorkflowSuggestion {
  const packageManager = nodePackageManager(paths, directory);
  return {
    title: firebaseFunctions ? "Firebase Functions のチェック" : "Node.js の基本チェック",
    description: firebaseFunctions
      ? "Firebase Functions 向けに依存関係の取得、lint、test、build を実行します。"
      : "Node.js プロジェクト向けに依存関係の取得、lint、test、build を実行します。",
    fileName: firebaseFunctions ? "firebase-functions-check.yaml" : "node-check.yaml",
    steps: [packageManager.installCommand, "lint", "test", "build"],
    requiredSecrets: [],
    yaml: `name: ${firebaseFunctions ? "Firebase Functions checks" : "Node checks"}

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop
${workingDirectoryBlock(directory)}
jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
${packageManager.setupSteps}      - name: Install dependencies
        run: ${packageManager.installCommand}
      - name: Lint
        run: ${packageManager.runCommand} lint --if-present
      - name: Test
        run: ${packageManager.runCommand} test --if-present
      - name: Build
        run: ${packageManager.runCommand} build --if-present
`,
  };
}

function fallbackSuggestion(): WorkflowSuggestion {
  return {
    title: "最小構成のシェルチェック",
    description:
      "プロジェクト種別を絞り込めない場合の、checkout と確認用コマンドだけを含む最小テンプレートです。",
    fileName: "basic-check.yaml",
    steps: ["checkout", "確認コマンドを追加"],
    requiredSecrets: [],
    yaml: `name: Basic check

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Add project checks
        run: echo "Add lint, test, or build commands for this project"
`,
  };
}

async function collectRepositoryContext({
  owner,
  repo,
  branch,
  token,
  apiBaseUrl,
}: {
  owner: string;
  repo: string;
  branch: string;
  token: string;
  apiBaseUrl: string;
}): Promise<{
  headSha: string;
  treeSummary: string;
  paths: string[];
}> {
  const tree = await githubGet<GitTreeResponse>(
    `/repos/${owner}/${repo}/git/trees/${encodeURIComponent(branch)}`,
    token,
    {
      queryParameters: { recursive: "1" },
      apiBaseUrl,
    },
  );
  const entries = tree.tree ?? [];
  const paths = entries
    .filter((entry) => entry.type === "blob")
    .map((entry) => (typeof entry.path === "string" ? entry.path : ""))
    .filter((path) => path.length > 0 && !shouldSkipPath(path))
    .sort((a, b) => a.localeCompare(b));

  const treeSummary = paths.slice(0, 2000).join("\n");

  return {
    headSha: typeof tree.sha === "string" ? tree.sha : branch,
    treeSummary,
    paths,
  };
}

function suggestFromRepositoryTree(
  paths: string[],
): Omit<SuggestWorkflowTemplatesResponse, "repository" | "branch" | "headSha"> {
  const pathSet = new Set(paths);
  const suggestions: WorkflowSuggestion[] = [];
  const pubspecDirectories = findDirectories(paths, "pubspec.yaml");
  const packageJsonDirectories = findDirectories(paths, "package.json");

  for (const directory of pubspecDirectories) {
    const flutterProject =
      hasFile(pathSet, directory, "flutter_launcher_icons.yaml") ||
      hasFile(pathSet, directory, "android/app/build.gradle") ||
      hasFile(pathSet, directory, "android/app/build.gradle.kts") ||
      hasFile(pathSet, directory, "ios/Runner/Info.plist") ||
      hasFile(pathSet, directory, "web/index.html") ||
      hasFile(pathSet, directory, "macos/Runner/Info.plist");
    suggestions.push(flutterProject ? flutterSuggestion(directory) : dartSuggestion(directory));
    if (suggestions.length >= 3) break;
  }

  for (const directory of packageJsonDirectories) {
    if (suggestions.length >= 4) break;
    if (pubspecDirectories.includes(directory)) continue;
    const firebaseFunctions =
      directory.endsWith("functions") ||
      hasFile(pathSet, directory, "firebase.json") ||
      hasAnyPath(paths, [directory === "." ? "firebase.json" : `${directory}/firebase.json`]);
    suggestions.push(nodeSuggestion(pathSet, directory, firebaseFunctions));
  }

  if (suggestions.length === 0) {
    suggestions.push(fallbackSuggestion());
  }

  const projectTypes = [
    pubspecDirectories.length > 0 ? "Dart/Flutter" : "",
    packageJsonDirectories.length > 0 ? "Node.js" : "",
    hasAnyPath(paths, ["firebase.json", "firebase"]) ? "Firebase" : "",
  ].filter((value) => value.length > 0);

  return {
    detectedProjectType:
      projectTypes.length > 0 ? `${projectTypes.join(" + ")} プロジェクト` : "汎用プロジェクト",
    analysisSummary:
      "リポジトリツリーから主要な manifest ファイルを検出し、すぐに編集して使える定番の OpenCI workflow を選びました。",
    suggestions: suggestions.slice(0, 4),
  };
}

export const suggestWorkflowTemplates = onCall<
  SuggestWorkflowTemplatesRequest,
  Promise<SuggestWorkflowTemplatesResponse>
>(
  {
    timeoutSeconds: 30,
    memory: "512MiB",
    secrets: [githubAppId, githubPrivateKey],
  },
  async (request) => {
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    const repository = requireNonEmptyString(request.data?.repository, "repository");
    const branch = requireNonEmptyString(request.data?.branch, "branch");
    const [owner, repo] = repository.split("/");
    if (!owner || !repo) {
      throw new HttpsError("invalid-argument", "repository must be in owner/repo format");
    }

    const teamData = await verifyTeamMembership(request.auth, teamId);
    const installationIds = getInstallationIds(teamData);
    const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

    try {
      let repositoryLookupError: unknown;
      for (const installationId of installationIds) {
        let context: Awaited<ReturnType<typeof collectRepositoryContext>>;
        try {
          const { token } = await getInstallationToken(installationId, { apiBaseUrl });
          context = await collectRepositoryContext({
            owner,
            repo,
            branch,
            token,
            apiBaseUrl,
          });
        } catch (error) {
          repositoryLookupError = error;
          logger.warn("Failed to suggest workflows for installation", {
            teamId,
            repository,
            branch,
            installationId,
            error: errorDetails(error),
          });
          continue;
        }

        const parsed = suggestFromRepositoryTree(context.paths);
        logger.info("Generated workflow suggestions from repository tree", {
          teamId,
          repository,
          branch,
          headSha: context.headSha,
          pathCount: context.paths.length,
          treeSummaryCharacters: context.treeSummary.length,
          suggestionCount: parsed.suggestions.length,
        });
        return {
          repository,
          branch,
          headSha: context.headSha,
          ...parsed,
        };
      }

      logger.warn("Repository lookup failed for all installations", {
        teamId,
        repository,
        branch,
        error: errorDetails(repositoryLookupError),
      });
      throw new HttpsError("not-found", "Repository not found in any installation");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      const details = errorDetails(error);
      logger.error("Failed to suggest workflow templates", {
        teamId,
        repository,
        branch,
        error: details,
      });
      throw new HttpsError(
        "internal",
        `Failed to suggest workflow templates: ${String(details.message ?? error)}`,
      );
    }
  },
);
