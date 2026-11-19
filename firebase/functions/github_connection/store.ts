import * as sdk from "@openci/github-admin";
import type { DataConnect } from "firebase-admin/data-connect";
import { ConnectionError, type RepositoryCandidate } from "./github.js";
import type { ConnectionConfig } from "./config.js";
import type { ConnectionStore } from "./service.js";

async function operation<T>(work: () => Promise<T>): Promise<T> {
  try {
    return await work();
  } catch (error) {
    const message = error instanceof Error ? error.message : "";
    if (
      message.includes("Team access denied") ||
      message.includes("GitHub installation is already connected") ||
      message.includes("GitHub repository is already connected")
    )
      throw new ConnectionError("permission-denied", "GitHub connection access denied");
    if (/Invalid or expired GitHub|GitHub (request|session) already consumed/.test(message))
      throw new ConnectionError("failed-precondition", "Restart GitHub authorization");
    throw new ConnectionError("unavailable", "GitHub connection storage is unavailable");
  }
}

export class GitHubConnectionStore implements ConnectionStore {
  constructor(
    readonly dc: DataConnect,
    readonly config: ConnectionConfig,
  ) {}
  async authorize(teamId: string, userId: string) {
    await operation(() => sdk.getGitHubConnectionContext(this.dc, { teamId, userId }));
  }
  async createRequest(input: sdk.CreateGitHubConnectionRequestVariables) {
    await operation(() => sdk.createGitHubConnectionRequest(this.dc, input));
  }
  async consumeRequest(stateHash: string) {
    const result = await operation(() =>
      sdk.consumeGitHubConnectionRequest(this.dc, { stateHash }),
    );
    const request = result.data.query?.request;
    if (!request) throw new ConnectionError("failed-precondition", "Restart GitHub authorization");
    return request;
  }
  async createSession(input: sdk.CreateGitHubConnectionSessionVariables) {
    await operation(() =>
      sdk.createGitHubConnectionSession(this.dc, {
        ...input,
        githubIssuer: `${this.config.apiBaseUrl}:${this.config.appId}`,
      }),
    );
  }
  async session(teamId: string, userId: string, referenceHash: string) {
    return (
      (
        await operation(() =>
          sdk.getGitHubConnectionSession(this.dc, { teamId, userId, referenceHash }),
        )
      ).data.session ?? null
    );
  }
  async unavailableRepositories(teamId: string, userId: string, candidates: RepositoryCandidate[]) {
    if (candidates.length === 0) return new Set<number>();
    const result = await operation(() =>
      sdk.getUnavailableGitHubRepositories(this.dc, {
        teamId,
        userId,
        githubApiBaseUrl: this.config.apiBaseUrl,
        githubAppId: this.config.appId,
        installationIds: [...new Set(candidates.map((item) => String(item.installationId)))],
        repositoryIds: candidates.map((item) => String(item.repositoryId)),
      }),
    );
    const installations = new Set(
      result.data.legacyConnections.map(({ installationId }) => Number(installationId)),
    );
    const repositories = new Set(
      result.data.repositories.map(({ repositoryId }) => Number(repositoryId)),
    );
    return new Set(
      candidates
        .filter(
          (item) => installations.has(item.installationId) || repositories.has(item.repositoryId),
        )
        .map((item) => item.repositoryId),
    );
  }
  async confirm(
    teamId: string,
    userId: string,
    referenceHash: string,
    installation: RepositoryCandidate,
  ) {
    await operation(() =>
      sdk.confirmGitHubConnection(this.dc, {
        teamId,
        userId,
        referenceHash,
        githubApiBaseUrl: this.config.apiBaseUrl,
        githubAppId: this.config.appId,
        installationId: String(installation.installationId),
        accountId: String(installation.accountId),
        accountType: installation.accountType,
        accountLogin: installation.accountLogin,
        repositoryId: String(installation.repositoryId),
        repositoryName: installation.repositoryName,
      }),
    );
  }
  async expired() {
    return (await sdk.getExpiredGitHubConnectionCredentials(this.dc)).data;
  }
  async deleteExpired(kind: "request" | "session", id: string) {
    if (kind === "request") await sdk.deleteExpiredGitHubConnectionRequest(this.dc, { id });
    else await sdk.deleteExpiredGitHubConnectionSession(this.dc, { id });
  }
}
