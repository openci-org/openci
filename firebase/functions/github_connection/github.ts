import type { ConnectionConfig } from "./config.js";

export class ConnectionError extends Error {
  constructor(
    readonly code: "invalid-argument" | "permission-denied" | "failed-precondition" | "unavailable",
    message: string,
  ) {
    super(message);
  }
}

export interface Installation {
  installationId: number;
  accountId: number;
  accountType: "User" | "Organization";
  accountLogin: string;
}
export interface RepositoryCandidate extends Installation {
  repositoryId: number;
  repositoryName: string;
}
export interface GitHubConnectionClient {
  exchange(code: string, verifier: string): Promise<string>;
  user(token: string): Promise<number>;
  candidates(token: string, expectedUserId: string): Promise<RepositoryCandidate[]>;
}

function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new Error("Invalid GitHub response");
  return value as Record<string, unknown>;
}
function id(value: unknown): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= 0)
    throw new Error("Invalid GitHub ID");
  return value;
}
export function credential(value: unknown): string {
  if (typeof value !== "string" || !/^[\x21-\x7e]{1,4096}$/.test(value))
    throw new Error("Invalid GitHub credential");
  return value;
}

export class OctokitConnectionClient implements GitHubConnectionClient {
  constructor(
    readonly config: ConnectionConfig,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  private async request(baseUrl: string, token?: string) {
    const { request } = await import("@octokit/request");
    return request.defaults({
      baseUrl,
      headers: {
        accept: "application/vnd.github+json",
        ...(token ? { authorization: `Bearer ${credential(token)}` } : {}),
      },
      request: {
        fetch: (url: string | URL | Request, init?: RequestInit) =>
          this.fetcher(url, {
            ...init,
            redirect: "error",
            signal: init?.signal
              ? AbortSignal.any([init.signal, AbortSignal.timeout(10000)])
              : AbortSignal.timeout(10000),
          }),
      },
    });
  }

  async exchange(code: string, verifier: string): Promise<string> {
    // oauth-methods does not forward code_verifier; use Octokit's request API
    // so PKCE is included in the token exchange as well as authorization.
    const request = await this.request(this.config.baseUrl);
    const { data } = await request("POST /login/oauth/access_token", {
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      redirect_uri: this.config.callbackUrl,
      code,
      code_verifier: verifier,
      headers: { accept: "application/json" },
    });
    const body = object(data);
    if (
      body.error ||
      typeof body.token_type !== "string" ||
      body.token_type.toLowerCase() !== "bearer"
    )
      throw new ConnectionError("failed-precondition", "Restart GitHub authorization");
    return credential(body.access_token);
  }

  async user(token: string): Promise<number> {
    try {
      const request = await this.request(this.config.apiBaseUrl, token);
      return id((await request("GET /user")).data.id);
    } catch (error) {
      throw this.failure(error);
    }
  }

  async candidates(token: string, expectedUserId: string): Promise<RepositoryCandidate[]> {
    try {
      const userId = await this.user(token);
      if (String(userId) !== expectedUserId)
        throw new ConnectionError("permission-denied", "GitHub user changed");
      const request = await this.request(this.config.apiBaseUrl, token);
      const candidates: RepositoryCandidate[] = [];
      const ids = new Set<number>();
      const repositoryIds = new Set<number>();
      let count: number | undefined;
      for (let page = 1; page <= 10; page++) {
        // Pagination stays on the configured host; never follow Link URLs.
        const { data, headers } = await request("GET /user/installations", { per_page: 100, page });
        if (
          !Number.isSafeInteger(data.total_count) ||
          data.total_count < 0 ||
          data.total_count > 1000 ||
          !Array.isArray(data.installations) ||
          data.installations.length > 100 ||
          (count !== undefined && count !== data.total_count)
        )
          throw new Error("Invalid installation page");
        count = data.total_count;
        for (const item of data.installations) {
          const raw = object(item);
          const installationId = id(raw.id);
          if (ids.has(installationId)) throw new Error("Duplicate installation");
          ids.add(installationId);
          if (String(id(raw.app_id)) !== this.config.appId) continue;
          if (!Object.hasOwn(raw, "suspended_at")) throw new Error("Missing installation state");
          if (raw.suspended_at !== null) continue;
          const account = object(raw.account);
          const accountId = id(account.id);
          const login = account.login;
          if (typeof login !== "string" || !login.trim() || login.length > 255)
            throw new Error("Invalid account");
          if (account.type !== "User" && account.type !== "Organization")
            throw new Error("Invalid account type");
          const installation: Installation = {
            installationId,
            accountId,
            accountLogin: login,
            accountType: account.type,
          };
          try {
            for (const repository of await this.repositories(token, installation)) {
              if (repositoryIds.has(repository.repositoryId))
                throw new Error("Duplicate repository across installations");
              repositoryIds.add(repository.repositoryId);
              candidates.push(repository);
              if (candidates.length > 1000) throw new Error("Repository limit exceeded");
            }
          } catch (error) {
            // A revoked installation does not hide other eligible repositories.
            // Rate limits, token expiry and upstream failures fail the request.
            const status = (error as { status?: number }).status;
            if (status === 404) continue;
            if (status === 403 && !this.rateLimited(error)) continue;
            throw error;
          }
        }
        const hasNext = /rel="next"/.test(headers.link ?? "");
        if (ids.size === count && !hasNext) return candidates;
        if (ids.size >= count || data.installations.length !== 100)
          throw new Error("Incomplete installation page");
      }
      throw new Error("Installation limit exceeded");
    } catch (error) {
      throw this.failure(error);
    }
  }

  private async repositories(
    token: string,
    installation: Installation,
  ): Promise<RepositoryCandidate[]> {
    const request = await this.request(this.config.apiBaseUrl, token);
    const candidates: RepositoryCandidate[] = [];
    const seen = new Set<number>();
    let count: number | undefined;
    for (let page = 1; page <= 10; page++) {
      // This endpoint intersects the user's access with the App installation's
      // repositories. Its permissions are the user's repository permissions.
      const { data, headers } = await request(
        "GET /user/installations/{installation_id}/repositories",
        {
          installation_id: installation.installationId,
          per_page: 100,
          page,
        },
      );
      if (
        !Number.isSafeInteger(data.total_count) ||
        data.total_count < 0 ||
        data.total_count > 1000 ||
        !Array.isArray(data.repositories) ||
        data.repositories.length > 100 ||
        (count !== undefined && count !== data.total_count)
      )
        throw new Error("Invalid repository page");
      count = data.total_count;
      for (const item of data.repositories) {
        const repository = object(item);
        const repositoryId = id(repository.id);
        if (seen.has(repositoryId)) throw new Error("Duplicate repository");
        seen.add(repositoryId);
        const owner = object(repository.owner);
        const name = repository.name;
        if (
          id(owner.id) !== installation.accountId ||
          typeof name !== "string" ||
          !/^[A-Za-z0-9_.-]+$/.test(name) ||
          name.length > 255 ||
          typeof repository.full_name !== "string" ||
          repository.full_name.toLowerCase() !==
            `${installation.accountLogin}/${name}`.toLowerCase()
        )
          throw new Error("Invalid repository identity");
        // Read and triage do not authorize linking CI. Write, maintain and admin
        // all include push; missing permission metadata must not grant access.
        if (repository.permissions && object(repository.permissions).push === true)
          candidates.push({ ...installation, repositoryId, repositoryName: name });
      }
      const hasNext = /rel="next"/.test(headers.link ?? "");
      if (seen.size === count && !hasNext) return candidates;
      if (seen.size >= count || data.repositories.length !== 100)
        throw new Error("Incomplete repository page");
    }
    throw new Error("Repository limit exceeded");
  }

  private rateLimited(error: unknown): boolean {
    const response = (
      error as { response?: { headers?: Record<string, string>; data?: { message?: unknown } } }
    ).response;
    const message = response?.data?.message;
    return (
      response?.headers?.["x-ratelimit-remaining"] === "0" ||
      !!response?.headers?.["retry-after"] ||
      (typeof message === "string" && /rate limit|abuse/i.test(message))
    );
  }
  private failure(error: unknown): ConnectionError {
    if (error instanceof ConnectionError) return error;
    if ((error as { status?: number }).status === 401)
      return new ConnectionError("failed-precondition", "Restart GitHub authorization");
    return new ConnectionError("unavailable", "GitHub verification failed; try again");
  }
}
