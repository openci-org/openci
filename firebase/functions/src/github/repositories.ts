import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { verifyTeamMembership } from "../team/teamAuth.js";
import {
  getInstallationToken,
  githubGet,
  githubGraphql,
  githubPatch,
  githubPost,
  githubPut,
} from "./githubApp.js";
import { getApiBaseUrlFromTeamData } from "./githubUrls.js";

function buildDirectoryTreeFragment(depth: number): string {
  if (depth === 0) {
    return "name type";
  }
  return `name type object { ... on Tree { entries { ${buildDirectoryTreeFragment(depth - 1)} } } }`;
}

const directoryTreeQuery = `
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            ${buildDirectoryTreeFragment(7)}
          }
        }
      }
    }
  }
`;

const openciDirQuery = `
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            name
            type
            object {
              ... on Blob { text }
            }
          }
        }
      }
    }
  }
`;

interface TeamIdRequest {
  teamId: string;
}

interface RepoRequest extends TeamIdRequest {
  repository: string;
}

interface ListWorkflowFilesRequest extends RepoRequest {
  branch?: string;
}

interface CreateWorkflowFileRequest extends RepoRequest {
  branch: string;
  fileName: string;
  content: string;
  commitMode: string;
  commitMessage?: string;
}

export interface GitHubRepositoryResponse {
  fullName: string;
  name: string;
  owner: string;
  private: boolean;
  defaultBranch: string;
}

export interface ListRepositoriesResponse {
  repositories: GitHubRepositoryResponse[];
}

export interface ListBranchesResponse {
  branches: string[];
}

export interface ListDirectoriesResponse {
  directories: string[];
}

export interface WorkflowFileResponse {
  name: string;
  path: string;
  content: string;
}

export interface ListWorkflowFilesResponse {
  files: WorkflowFileResponse[];
}

export interface CreateWorkflowFileResponse {
  mode: "direct" | "pull_request";
  commitSha?: string;
  pullRequestUrl?: string;
  pullRequestNumber?: number;
  branch: string;
}

interface GitHubInstallationRepositoriesResponse extends Record<string, unknown> {
  repositories?: Array<{
    full_name?: unknown;
    name?: unknown;
    owner?: { login?: unknown };
    private?: unknown;
    default_branch?: unknown;
  }>;
}

interface BranchRestResponse {
  name?: unknown;
}

interface RepositoryRestResponse {
  default_branch?: unknown;
}

interface ContentRestResponse {
  sha?: unknown;
}

interface TreeEntry {
  name?: unknown;
  type?: unknown;
  object?: {
    entries?: TreeEntry[];
  } | null;
}

interface DirectoryTreeGraphqlResponse extends Record<string, unknown> {
  data?: {
    repository?: {
      object?: {
        entries?: TreeEntry[];
      } | null;
    } | null;
  };
}

interface OpenciDirEntry {
  name?: unknown;
  type?: unknown;
  object?: {
    text?: unknown;
  } | null;
}

interface OpenciDirGraphqlResponse extends Record<string, unknown> {
  data?: {
    repository?: {
      object?: {
        entries?: OpenciDirEntry[];
      } | null;
    } | null;
  };
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

function getInstallationIds(teamData: FirebaseFirestore.DocumentData): number[] {
  const installationIds = Array.isArray(teamData.installationIds) ? teamData.installationIds : [];
  const ids = installationIds.filter((id): id is number => typeof id === "number");
  if (ids.length === 0) {
    throw new HttpsError("failed-precondition", "GitHub App is not installed for this team");
  }
  return ids;
}

function flattenTreeEntries(entries: TreeEntry[], prefix = ""): string[] {
  const directories: string[] = [];
  for (const entry of entries) {
    if (entry.type !== "tree" || typeof entry.name !== "string") {
      continue;
    }
    const path = prefix.length === 0 ? entry.name : `${prefix}/${entry.name}`;
    directories.push(path);
    if (entry.object?.entries) {
      directories.push(...flattenTreeEntries(entry.object.entries, path));
    }
  }
  return directories;
}

function githubErrorStatus(error: unknown): number | undefined {
  if (typeof error !== "object" || error === null || !("status" in error)) {
    return undefined;
  }
  const status = (error as { status?: unknown }).status;
  return typeof status === "number" ? status : undefined;
}

async function resolveWritableBranch({
  owner,
  repo,
  requestedBranch,
  token,
  apiBaseUrl,
}: {
  owner: string;
  repo: string;
  requestedBranch: string;
  token: string;
  apiBaseUrl: string;
}): Promise<string> {
  const branch = requestedBranch.trim();
  if (branch.length === 0) {
    throw new HttpsError("invalid-argument", "branch is required");
  }
  if (branch !== "HEAD") {
    return branch;
  }

  const repository = await githubGet<RepositoryRestResponse>(`/repos/${owner}/${repo}`, token, {
    apiBaseUrl,
  });
  return requireNonEmptyString(repository.default_branch, "defaultBranch");
}

async function getExistingContentSha({
  owner,
  repo,
  filePath,
  branch,
  token,
  apiBaseUrl,
}: {
  owner: string;
  repo: string;
  filePath: string;
  branch: string;
  token: string;
  apiBaseUrl: string;
}): Promise<string | undefined> {
  try {
    const content = await githubGet<ContentRestResponse>(
      `/repos/${owner}/${repo}/contents/${filePath}`,
      token,
      {
        queryParameters: { ref: branch },
        apiBaseUrl,
      },
    );
    return typeof content.sha === "string" && content.sha.length > 0 ? content.sha : undefined;
  } catch (error) {
    if (githubErrorStatus(error) === 404) {
      return undefined;
    }
    throw error;
  }
}

export const listRepositories = onCall<TeamIdRequest, Promise<ListRepositoriesResponse>>(
  async (request) => {
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    const teamData = await verifyTeamMembership(request.auth, teamId);
    const installationIds = getInstallationIds(teamData);
    const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

    try {
      const allRepositories: GitHubRepositoryResponse[] = [];

      for (const installationId of installationIds) {
        const { token } = await getInstallationToken(installationId, { apiBaseUrl });
        let page = 1;

        while (true) {
          const data = await githubGet<GitHubInstallationRepositoriesResponse>(
            "/installation/repositories",
            token,
            {
              queryParameters: { per_page: 100, page },
              apiBaseUrl,
            },
          );
          const repositories = data.repositories ?? [];

          for (const repo of repositories) {
            allRepositories.push({
              fullName: String(repo.full_name ?? ""),
              name: String(repo.name ?? ""),
              owner: String(repo.owner?.login ?? ""),
              private: repo.private === true,
              defaultBranch: String(repo.default_branch ?? ""),
            });
          }

          if (repositories.length < 100) {
            break;
          }
          page += 1;
        }
      }

      return { repositories: allRepositories };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("Failed to list repositories", { teamId, error });
      throw new HttpsError("internal", "Failed to list repositories");
    }
  },
);

export const listBranches = onCall<RepoRequest, Promise<ListBranchesResponse>>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const repository = requireNonEmptyString(request.data?.repository, "repository");
  const [owner, repo] = repository.split("/");
  if (!owner || !repo) {
    throw new HttpsError("invalid-argument", "repository must be in owner/repo format");
  }

  const teamData = await verifyTeamMembership(request.auth, teamId);
  const installationIds = getInstallationIds(teamData);
  const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

  try {
    for (const installationId of installationIds) {
      try {
        const { token } = await getInstallationToken(installationId, { apiBaseUrl });
        const repositoryData = await githubGet<RepositoryRestResponse>(
          `/repos/${owner}/${repo}`,
          token,
          { apiBaseUrl },
        );
        const defaultBranchName =
          typeof repositoryData.default_branch === "string"
            ? repositoryData.default_branch
            : undefined;
        const branches: string[] = [];
        let page = 1;

        while (true) {
          const pageBranches = await githubGet<BranchRestResponse[]>(
            `/repos/${owner}/${repo}/branches`,
            token,
            {
              queryParameters: { per_page: 100, page },
              apiBaseUrl,
            },
          );

          branches.push(
            ...pageBranches
              .map((branch) => branch.name)
              .filter((branch): branch is string => typeof branch === "string"),
          );

          if (pageBranches.length < 100) {
            break;
          }
          page += 1;
        }

        branches.sort((a, b) => {
          if (a === defaultBranchName) return -1;
          if (b === defaultBranchName) return 1;
          return a.localeCompare(b);
        });

        const db = getFirestore();
        const repositoryId = repository.replace("/", ":");
        const repoRef = db
          .collection("teams_v0")
          .doc(teamId)
          .collection("repositories_v0")
          .doc(repositoryId);

        await repoRef.set(
          {
            repository,
            defaultBranch: defaultBranchName ?? "main",
            branches,
            updatedAt: new Date().toISOString(),
          },
          { merge: true },
        );

        return {
          branches,
        };
      } catch {
        continue;
      }
    }

    throw new HttpsError("not-found", "Repository not found in any installation");
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Failed to list branches", { teamId, repository, error });
    throw new HttpsError("internal", "Failed to list branches");
  }
});

export const listDirectories = onCall<RepoRequest, Promise<ListDirectoriesResponse>>(
  async (request) => {
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    const repository = requireNonEmptyString(request.data?.repository, "repository");
    const [owner, repo] = repository.split("/");
    if (!owner || !repo) {
      throw new HttpsError("invalid-argument", "repository must be in owner/repo format");
    }

    const teamData = await verifyTeamMembership(request.auth, teamId);
    const installationIds = getInstallationIds(teamData);
    const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

    try {
      for (const installationId of installationIds) {
        try {
          const { token } = await getInstallationToken(installationId, { apiBaseUrl });
          const result = await githubGraphql<DirectoryTreeGraphqlResponse>(
            directoryTreeQuery,
            token,
            {
              variables: { owner, repo, expression: "HEAD:" },
              apiBaseUrl,
            },
          );

          const entries = result.data?.repository?.object?.entries ?? [];
          const directories = flattenTreeEntries(entries).sort();
          return { directories: [".", ...directories] };
        } catch {
          continue;
        }
      }

      throw new HttpsError("not-found", "Repository not found in any installation");
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("Failed to list directories", { teamId, repository, error });
      throw new HttpsError("internal", "Failed to list directories");
    }
  },
);

export const listWorkflowFiles = onCall<
  ListWorkflowFilesRequest,
  Promise<ListWorkflowFilesResponse>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const repository = requireNonEmptyString(request.data?.repository, "repository");
  const [owner, repo] = repository.split("/");
  if (!owner || !repo) {
    throw new HttpsError("invalid-argument", "repository must be in owner/repo format");
  }

  const teamData = await verifyTeamMembership(request.auth, teamId);
  const installationIds = getInstallationIds(teamData);
  const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

  try {
    for (const installationId of installationIds) {
      try {
        const { token } = await getInstallationToken(installationId, { apiBaseUrl });
        const branch = typeof request.data?.branch === "string" ? request.data.branch : "HEAD";
        const expression = `${branch}:.openci`;

        let entries: OpenciDirEntry[];
        try {
          const result = await githubGraphql<OpenciDirGraphqlResponse>(openciDirQuery, token, {
            variables: { owner, repo, expression },
            apiBaseUrl,
          });
          entries = result.data?.repository?.object?.entries ?? [];
        } catch (error) {
          if (String(error).includes("Could not resolve to an object")) {
            return { files: [] };
          }
          throw error;
        }

        const files = entries
          .filter((entry) => {
            if (entry.type !== "blob" || typeof entry.name !== "string") {
              return false;
            }
            const text = entry.object?.text;
            return (
              (entry.name.endsWith(".yaml") || entry.name.endsWith(".yml")) &&
              typeof text === "string"
            );
          })
          .map((entry) => ({
            name: entry.name as string,
            path: `.openci/${entry.name as string}`,
            content: entry.object?.text as string,
          }));

        return { files };
      } catch (error) {
        if (error instanceof HttpsError) {
          throw error;
        }
        continue;
      }
    }

    throw new HttpsError("not-found", "Repository not found in any installation");
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Failed to list workflow files", { teamId, repository, error });
    throw new HttpsError("internal", "Failed to list workflow files");
  }
});

export const createWorkflowFile = onCall<
  CreateWorkflowFileRequest,
  Promise<CreateWorkflowFileResponse>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const repository = requireNonEmptyString(request.data?.repository, "repository");
  const branch = requireNonEmptyString(request.data?.branch, "branch");
  const fileName = requireNonEmptyString(request.data?.fileName, "fileName");
  const content = requireNonEmptyString(request.data?.content, "content");
  const commitMode = requireNonEmptyString(request.data?.commitMode, "commitMode");
  if (!fileName.endsWith(".yaml") && !fileName.endsWith(".yml")) {
    throw new HttpsError("invalid-argument", "File name must end with .yaml or .yml");
  }
  const [owner, repo] = repository.split("/");
  if (!owner || !repo) {
    throw new HttpsError("invalid-argument", "repository must be in owner/repo format");
  }

  const teamData = await verifyTeamMembership(request.auth, teamId);
  const installationIds = getInstallationIds(teamData);
  const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);
  const filePath = `.openci/${fileName}`;
  const message =
    typeof request.data?.commitMessage === "string"
      ? request.data.commitMessage
      : `Add workflow: ${fileName}`;
  const contentBase64 = Buffer.from(content, "utf8").toString("base64");

  try {
    let workflowCreateError: unknown;
    for (const installationId of installationIds) {
      try {
        const { token } = await getInstallationToken(installationId, { apiBaseUrl });
        const targetBranch = await resolveWritableBranch({
          owner,
          repo,
          requestedBranch: branch,
          token,
          apiBaseUrl,
        });

        if (commitMode === "direct") {
          const refData = await githubGet<{ object?: { sha?: string } }>(
            `/repos/${owner}/${repo}/git/ref/heads/${targetBranch}`,
            token,
            { apiBaseUrl },
          );
          const latestCommitSha = requireNonEmptyString(refData.object?.sha, "latestCommitSha");
          const blobData = await githubPost<{ sha?: string }>(
            `/repos/${owner}/${repo}/git/blobs`,
            token,
            { content: contentBase64, encoding: "base64" },
            { apiBaseUrl },
          );
          const latestCommit = await githubGet<{ tree?: { sha?: string } }>(
            `/repos/${owner}/${repo}/git/commits/${latestCommitSha}`,
            token,
            { apiBaseUrl },
          );
          const treeData = await githubPost<{ sha?: string }>(
            `/repos/${owner}/${repo}/git/trees`,
            token,
            {
              base_tree: requireNonEmptyString(latestCommit.tree?.sha, "baseTreeSha"),
              tree: [{ path: filePath, mode: "100644", type: "blob", sha: blobData.sha }],
            },
            { apiBaseUrl },
          );
          const newCommit = await githubPost<{ sha?: string }>(
            `/repos/${owner}/${repo}/git/commits`,
            token,
            {
              message,
              tree: treeData.sha,
              parents: [latestCommitSha],
            },
            { apiBaseUrl },
          );
          const commitSha = requireNonEmptyString(newCommit.sha, "commitSha");
          await githubPatch(
            `/repos/${owner}/${repo}/git/refs/heads/${targetBranch}`,
            token,
            { sha: commitSha },
            { apiBaseUrl },
          );

          return { mode: "direct", commitSha, branch: targetBranch };
        }

        const branchSlug = fileName.replace(/\.(yaml|yml)$/u, "");
        const newBranchName = `openci/add-${branchSlug}-${Date.now()}`;
        const refData = await githubGet<{ object?: { sha?: string } }>(
          `/repos/${owner}/${repo}/git/ref/heads/${targetBranch}`,
          token,
          { apiBaseUrl },
        );
        await githubPost(
          `/repos/${owner}/${repo}/git/refs`,
          token,
          { ref: `refs/heads/${newBranchName}`, sha: refData.object?.sha },
          { apiBaseUrl },
        );
        const existingContentSha = await getExistingContentSha({
          owner,
          repo,
          filePath,
          branch: newBranchName,
          token,
          apiBaseUrl,
        });
        await githubPut(
          `/repos/${owner}/${repo}/contents/${filePath}`,
          token,
          {
            message,
            content: contentBase64,
            branch: newBranchName,
            ...(existingContentSha === undefined ? {} : { sha: existingContentSha }),
          },
          { apiBaseUrl },
        );
        const pr = await githubPost<{ html_url?: string; number?: number }>(
          `/repos/${owner}/${repo}/pulls`,
          token,
          {
            title: message,
            head: newBranchName,
            base: targetBranch,
            body: `This workflow file was created by OpenCI.\n\nFile: \`${filePath}\``,
          },
          { apiBaseUrl },
        );

        return {
          mode: "pull_request",
          pullRequestUrl: requireNonEmptyString(pr.html_url, "pullRequestUrl"),
          pullRequestNumber: typeof pr.number === "number" ? pr.number : undefined,
          branch: newBranchName,
        };
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        workflowCreateError = error;
        logger.warn("Failed to create workflow file with installation", {
          teamId,
          repository,
          branch,
          installationId,
          error,
        });
        continue;
      }
    }

    logger.warn("Repository lookup failed for all installations while creating workflow file", {
      teamId,
      repository,
      branch,
      error: workflowCreateError,
    });
    throw new HttpsError("not-found", "Repository not found in any installation");
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Failed to create workflow file", { teamId, repository, error });
    throw new HttpsError("internal", "Failed to create workflow file");
  }
});
