import { createAppAuth } from "@octokit/auth-app";
import { request } from "@octokit/request";
import { readFileSync } from "node:fs";
import { rootCertificates } from "node:tls";
import { EnvHttpProxyAgent, fetch as proxyFetch } from "undici";
import { mapConcurrent } from "./concurrent.js";
import type { AppConfig, Environment } from "./config.js";
import type { Deadline } from "./deadline.js";
import {
  type Json,
  jsonObject,
  jsonObjects,
  object,
  Repository,
  RetryException,
} from "./models.js";

export class ApiException extends Error {
  constructor(
    readonly method: string,
    readonly path: string,
    readonly status: number,
  ) {
    super(`GitHub API ${method} ${path.split("?")[0]} returned ${status}`);
  }
}
/** SDK authentication and a bounded, non-redirecting transport for GitHub and GHES. */
export class GitHubApi {
  private readonly transport: typeof request;
  private readonly auth: ReturnType<typeof createAppAuth>;
  private readonly dispatcher?: EnvHttpProxyAgent;
  private app?: Json;
  constructor(
    readonly config: AppConfig,
    options: { fetch?: typeof fetch; deadline?: Deadline; environment?: Environment } = {},
  ) {
    const env = options.environment ?? process.env;
    if (!options.fetch) {
      const ca = env.GITHUB_CA_FILE
        ? [...rootCertificates, readFileSync(env.GITHUB_CA_FILE, "utf8")]
        : undefined;
      this.dispatcher = new EnvHttpProxyAgent({
        httpProxy: env.HTTP_PROXY ?? env.http_proxy,
        httpsProxy: env.HTTPS_PROXY ?? env.https_proxy,
        noProxy: env.NO_PROXY ?? env.no_proxy,
        connect: { ca, timeout: 30_000 },
        requestTls: { ca },
        proxyTls: { ca },
      });
    }
    const guardedFetch: typeof fetch = async (input, init) => {
      const url = new URL(typeof input === "string" || input instanceof URL ? input : input.url);
      if (url.origin !== new URL(config.apiUrl).origin)
        throw new Error("Unexpected GitHub API origin");
      const signal = AbortSignal.timeout(options.deadline?.limit(30_000) ?? 30_000);
      const settings = {
        ...init,
        redirect: "error" as const,
        signal: init?.signal ? AbortSignal.any([init.signal, signal]) : signal,
      };
      if (options.fetch) return options.fetch(input, settings);
      return (await proxyFetch(url, { ...settings, dispatcher: this.dispatcher } as Parameters<
        typeof proxyFetch
      >[1])) as unknown as Response;
    };
    this.transport = request.defaults({
      baseUrl: config.apiUrl,
      headers: { "user-agent": "stacked-pr-app", "x-github-api-version": "2022-11-28" },
      request: { fetch: guardedFetch },
    });
    this.auth = createAppAuth({
      appId: config.appId,
      privateKey: config.privateKey,
      request: this.transport,
    });
  }
  async raw(
    token: string,
    method: string,
    path: string,
    body?: Json,
    onLink?: (link: string | undefined) => void,
  ): Promise<unknown> {
    if (!path.startsWith("/") || path.startsWith("//")) throw new Error("Invalid API path");
    try {
      const response = await this.transport({
        method: method as "GET" | "POST" | "PATCH",
        url: path === "/graphql" ? this.config.graphqlUrl : `${this.config.apiUrl}${path}`,
        headers: { authorization: `Bearer ${token}`, accept: "application/vnd.github+json" },
        ...(body === undefined ? {} : { data: body }),
      });
      onLink?.(response.headers.link);
      return response.status === 204 ? null : response.data;
    } catch (error) {
      // Octokit errors retain request/response bodies and credentials. Do not propagate them.
      throw new ApiException(
        method,
        path,
        typeof object(error).status === "number" ? (object(error).status as number) : 0,
      );
    }
  }
  async identity(): Promise<Json> {
    if (!this.app)
      this.app = jsonObject(
        await this.raw((await this.auth({ type: "app" })).token, "GET", "/app"),
      );
    return this.app;
  }
  async token(installation: number, refresh = false): Promise<string> {
    try {
      return (await this.auth({ type: "installation", installationId: installation, refresh }))
        .token;
    } catch (error) {
      throw new ApiException(
        "POST",
        `/app/installations/${installation}/access_tokens`,
        typeof object(error).status === "number" ? (object(error).status as number) : 0,
      );
    }
  }
  async request(
    installation: number,
    method: string,
    path: string,
    body?: Json,
    onLink?: (link: string | undefined) => void,
  ): Promise<unknown> {
    try {
      return await this.raw(await this.token(installation), method, path, body, onLink);
    } catch (error) {
      if (!(error instanceof ApiException) || error.status !== 401) throw error;
      return this.raw(await this.token(installation, true), method, path, body, onLink);
    }
  }
  async list(installation: number, path: string, field?: string): Promise<Json[]> {
    const result: Json[] = [];
    let nextPage = 1,
      lastPage = 1;
    for (;;) {
      // Link is only a page-count hint. Always construct requests on the configured origin.
      const pages = Array.from(
        { length: Math.min(4, Math.max(1, lastPage - nextPage + 1)) },
        (_, index) => nextPage + index,
      );
      const batches = await mapConcurrent(pages, async (page) => {
        const data = await this.request(
          installation,
          "GET",
          `${path}${path.includes("?") ? "&" : "?"}per_page=100&page=${page}`,
          undefined,
          (link) => {
            lastPage = Math.max(lastPage, lastPageHint(link, this.config.apiUrl));
          },
        );
        return jsonObjects(field === undefined ? data : jsonObject(data)[field]);
      });
      for (const items of batches) {
        result.push(...items);
        if (items.length < 100) return result;
      }
      nextPage += pages.length;
    }
  }
  async canWrite(installation: number, repoPath: string, login?: string): Promise<boolean> {
    if (!login) return false;
    try {
      const value = jsonObject(
        await this.request(
          installation,
          "GET",
          `${repoPath}/collaborators/${encodeURIComponent(login)}/permission`,
        ),
      );
      return (
        object(object(value.user).permissions).push === true ||
        ["admin", "write", "maintain"].includes(value.permission as string)
      );
    } catch (error) {
      if (error instanceof ApiException && error.status === 404) return false;
      throw error;
    }
  }
  async timeline(installation: number, repo: Repository, number: number): Promise<Json[]> {
    const [owner, name] = repo.fullName.split("/");
    const result: Json[] = [];
    let cursor: string | null = null;
    for (;;) {
      const response = jsonObject(
        await this.request(installation, "POST", "/graphql", {
          query: `query StackHistory($owner: String!, $name: String!, $number: Int!, $cursor: String) {
          repository(owner: $owner, name: $name) { pullRequest(number: $number) {
            timelineItems(first: 100, after: $cursor, itemTypes: [HEAD_REF_FORCE_PUSHED_EVENT, BASE_REF_CHANGED_EVENT, AUTOMATIC_BASE_CHANGE_SUCCEEDED_EVENT]) {
              ${historyFields}
            }
          } }
        }`,
          variables: { owner, name, number, cursor },
        }),
      );
      if (response.errors != null) throw new RetryException("GitHub history query failed");
      const repository = object(object(response.data).repository);
      if (!repository.pullRequest) throw new RetryException("Pull request history unavailable");
      const items = jsonObject(jsonObject(repository.pullRequest).timelineItems);
      result.push(...jsonObjects(items.nodes));
      const page = jsonObject(items.pageInfo);
      if (page.hasNextPage !== true) break;
      const next = page.endCursor;
      if (typeof next !== "string" || next === cursor)
        throw new RetryException("Incomplete PR history");
      cursor = next;
    }
    return result;
  }
  async timelines(
    installation: number,
    repo: Repository,
    numbers: number[],
  ): Promise<Map<number, Json[]>> {
    const [owner, name] = repo.fullName.split("/");
    if (numbers.some((n) => !Number.isSafeInteger(n) || n <= 0))
      throw new Error("Invalid PR number");
    const batches: number[][] = [];
    for (let start = 0; start < numbers.length; start += 20) {
      batches.push(numbers.slice(start, start + 20));
    }
    const entries = await mapConcurrent(batches, async (batch) => {
      const result = new Map<number, Json[]>();
      const fields = batch
        .map(
          (n) => `pr${n}: pullRequest(number: ${n}) {
        timelineItems(first: 100, itemTypes: [HEAD_REF_FORCE_PUSHED_EVENT, BASE_REF_CHANGED_EVENT, AUTOMATIC_BASE_CHANGE_SUCCEEDED_EVENT]) { ${historyFields} }
      }`,
        )
        .join("\n");
      const response = jsonObject(
        await this.request(installation, "POST", "/graphql", {
          query: `query StackHistories($owner: String!, $name: String!) { repository(owner: $owner, name: $name) { ${fields} } }`,
          variables: { owner, name },
        }),
      );
      if (response.errors != null) throw new RetryException("GitHub history query failed");
      const repository = jsonObject(jsonObject(response.data).repository);
      for (const number of batch) {
        if (repository[`pr${number}`] == null) throw new RetryException("PR history unavailable");
        const items = jsonObject(jsonObject(repository[`pr${number}`]).timelineItems);
        result.set(
          number,
          jsonObject(items.pageInfo).hasNextPage === true
            ? await this.timeline(installation, repo, number)
            : jsonObjects(items.nodes),
        );
      }
      return [...result];
    });
    return new Map(entries.flat());
  }
  async installationActive(installation: number): Promise<boolean> {
    try {
      const value = jsonObject(
        await this.raw(
          (await this.auth({ type: "app" })).token,
          "GET",
          `/app/installations/${installation}`,
        ),
      );
      return value.id === installation && value.suspended_at == null;
    } catch (error) {
      if (error instanceof ApiException && error.status === 404) return false;
      throw error;
    }
  }
  async close(): Promise<void> {
    await this.dispatcher?.close();
  }
}
function lastPageHint(link: string | undefined, apiUrl: string): number {
  const match = link?.match(/<([^>]+)>;\s*rel="last"/);
  if (!match) return 1;
  try {
    const url = new URL(match[1]),
      page = Number(url.searchParams.get("page"));
    return url.origin === new URL(apiUrl).origin && Number.isSafeInteger(page) && page > 0
      ? page
      : 1;
  } catch {
    return 1;
  }
}
const historyFields = `nodes {
  __typename
  ... on HeadRefForcePushedEvent { createdAt beforeCommit { oid } afterCommit { oid } }
  ... on BaseRefChangedEvent { createdAt previousRefName currentRefName }
  ... on AutomaticBaseChangeSucceededEvent { createdAt oldBase newBase }
} pageInfo { hasNextPage endCursor }`;
