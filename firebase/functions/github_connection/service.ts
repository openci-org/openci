import { createHash, randomBytes, randomUUID } from "node:crypto";
import { authorizationUrl, type ConnectionConfig } from "./config.js";
import { ConnectionError, type GitHubConnectionClient, type Installation } from "./github.js";
import type { CredentialVault } from "./vault.js";

interface ConnectionRequest {
  userId: string;
  teamId: string;
  codeVerifierSecretVersionPath: string;
}
export interface ConnectionSession {
  userId: string;
  teamId: string;
  githubUserId: string;
  expiresAt: string;
  accessTokenSecretVersionPath?: string | null;
}
export interface ConnectionStore {
  authorize(teamId: string, userId: string): Promise<void>;
  createRequest(input: ConnectionRequest & { id: string; stateHash: string }): Promise<void>;
  consumeRequest(stateHash: string): Promise<ConnectionRequest>;
  createSession(
    input: Omit<ConnectionSession, "expiresAt"> & {
      id: string;
      referenceHash: string;
      accessTokenSecretVersionPath: string;
    },
  ): Promise<void>;
  session(teamId: string, userId: string, referenceHash: string): Promise<ConnectionSession | null>;
  confirm(
    teamId: string,
    userId: string,
    referenceHash: string,
    installation: Installation,
  ): Promise<void>;
  expired(): Promise<{
    requests: { id: string; codeVerifierSecretVersionPath: string }[];
    sessions: { id: string; accessTokenSecretVersionPath?: string | null }[];
  }>;
  deleteExpired(kind: "request" | "session", id: string): Promise<void>;
}

export const hash = (value: string): string => createHash("sha256").update(value).digest("hex");
const randomReference = () => randomBytes(32).toString("base64url");
const validReference = (value: unknown): value is string =>
  typeof value === "string" && /^[A-Za-z0-9_-]{43}$/.test(value);

export class GitHubConnections {
  constructor(
    readonly config: ConnectionConfig,
    readonly store: ConnectionStore,
    readonly vault: CredentialVault,
    readonly github: GitHubConnectionClient,
    readonly report: (reason: string) => void = () => {},
  ) {}

  async execute(userId: string, value: unknown): Promise<Record<string, unknown>> {
    if (!value || typeof value !== "object" || Array.isArray(value))
      throw new ConnectionError("invalid-argument", "Invalid request");
    const { action, teamId, reference, installationId } = value as Record<string, unknown>;
    if (
      typeof teamId !== "string" ||
      !teamId ||
      teamId.length > 255 ||
      [...teamId].some((char) => char.charCodeAt(0) <= 32)
    )
      throw new ConnectionError("invalid-argument", "Team ID is required");
    if (
      typeof action !== "string" ||
      !["start", "session", "candidates", "confirm"].includes(action)
    )
      throw new ConnectionError("invalid-argument", "Unknown GitHub connection action");
    if (action === "start") return this.start(teamId, userId);
    if (!validReference(reference))
      throw new ConnectionError("invalid-argument", "Invalid connection reference");
    if (
      action === "confirm" &&
      (typeof installationId !== "number" ||
        !Number.isSafeInteger(installationId) ||
        installationId <= 0)
    )
      throw new ConnectionError("invalid-argument", "Invalid installation ID");
    const session = await this.store.session(teamId, userId, hash(reference));
    if (!session || !session.accessTokenSecretVersionPath)
      throw new ConnectionError("failed-precondition", "Restart GitHub authorization");
    if (action === "session")
      return {
        success: true,
        session: {
          teamId: session.teamId,
          githubUserId: Number(session.githubUserId),
          expiresAt: new Date(Number(session.expiresAt) * 1000).toISOString(),
        },
      };
    const token = await this.vault.read(session.accessTokenSecretVersionPath);
    const candidates = await this.github.candidates(token, session.githubUserId);
    if (action === "candidates") {
      // Membership may have changed while GitHub requests were in flight.
      const current = await this.store.session(teamId, userId, hash(reference));
      if (!current || current.accessTokenSecretVersionPath !== session.accessTokenSecretVersionPath)
        throw new ConnectionError("failed-precondition", "Restart GitHub authorization");
      return {
        success: true,
        candidates: candidates.map(({ installationId, accountLogin, accountType }) => ({
          installationId,
          accountLogin,
          accountType,
        })),
        ...(this.config.installationUrl ? { installationUrl: this.config.installationUrl } : {}),
      };
    }
    const selected = candidates.find((candidate) => candidate.installationId === installationId);
    if (!selected)
      throw new ConnectionError("permission-denied", "Installation is not available to connect");
    // Rechecks team membership, session ownership/expiry and the unique
    // host/app/installation owner in the same FSC transaction.
    await this.store.confirm(teamId, userId, hash(reference), selected);
    await this.release(session.accessTokenSecretVersionPath);
    return { success: true };
  }

  private async start(teamId: string, userId: string): Promise<Record<string, unknown>> {
    await this.store.authorize(teamId, userId);
    const state = randomReference();
    const verifier = randomReference();
    const path = await this.vault.create(verifier);
    try {
      await this.store.createRequest({
        id: randomUUID(),
        userId,
        teamId,
        stateHash: hash(state),
        codeVerifierSecretVersionPath: path,
      });
    } catch (error) {
      await this.release(path);
      throw error;
    }
    return {
      success: true,
      authorizationUrl: authorizationUrl(
        this.config,
        state,
        createHash("sha256").update(verifier).digest("base64url"),
      ),
      expiresAt: new Date(Date.now() + 600000).toISOString(),
    };
  }

  async callback(parameters: URLSearchParams): Promise<string> {
    const redirect = (key: "reference" | "error", value: string) => {
      const url = new URL(this.config.returnUrl);
      // The browser consumes and scrubs this fragment before auth/navigation.
      url.hash = new URLSearchParams({ [key]: value }).toString();
      return url.toString();
    };
    const state = parameters.get("state");
    const code = parameters.get("code");
    const error = parameters.get("error");
    if (
      !validReference(state) ||
      parameters.getAll("state").length !== 1 ||
      (error !== null
        ? !error || parameters.getAll("error").length !== 1 || parameters.has("code")
        : !code || !/^[\x21-\x7e]{1,2048}$/.test(code) || parameters.getAll("code").length !== 1)
    )
      return redirect("error", "invalid_callback");
    let request: ConnectionRequest;
    try {
      request = await this.store.consumeRequest(hash(state));
    } catch (cause) {
      if (cause instanceof ConnectionError && cause.code === "failed-precondition")
        return redirect("error", "invalid_state");
      this.report("github_request_consumption_failed");
      return redirect("error", "connection_failed");
    }
    try {
      if (error !== null)
        return redirect("error", error === "access_denied" ? error : "connection_failed");
      await this.store.authorize(request.teamId, request.userId);
      const verifier = await this.vault.read(request.codeVerifierSecretVersionPath);
      const token = await this.github.exchange(code!, verifier);
      const githubUserId = await this.github.user(token);
      await this.store.authorize(request.teamId, request.userId);
      const reference = randomReference();
      const path = await this.vault.create(token);
      try {
        await this.store.createSession({
          id: randomUUID(),
          userId: request.userId,
          teamId: request.teamId,
          githubUserId: String(githubUserId),
          referenceHash: hash(reference),
          accessTokenSecretVersionPath: path,
        });
      } catch (cause) {
        await this.release(path);
        throw cause;
      }
      return redirect("reference", reference);
    } catch (cause) {
      this.report("github_callback_failed");
      return redirect(
        "error",
        cause instanceof ConnectionError && cause.code === "permission-denied"
          ? "forbidden"
          : "connection_failed",
      );
    } finally {
      await this.release(request.codeVerifierSecretVersionPath);
    }
  }

  private async release(path: string): Promise<void> {
    try {
      await this.vault.destroy(path);
    } catch {
      this.report("github_credential_cleanup_failed");
    }
    // Secret Manager's 30-minute TTL also covers lost commit acknowledgements.
  }

  async cleanup(): Promise<void> {
    const expired = await this.store.expired();
    const rows = [
      ...expired.requests.slice(0, 10).map((r) => ({
        kind: "request" as const,
        id: r.id,
        path: r.codeVerifierSecretVersionPath,
      })),
      ...expired.sessions
        .slice(0, 10)
        .map((r) => ({ kind: "session" as const, id: r.id, path: r.accessTokenSecretVersionPath })),
    ];
    for (let i = 0; i < rows.length; i += 4)
      await Promise.all(
        rows.slice(i, i + 4).map(async (row) => {
          try {
            if (row.path) await this.vault.destroy(row.path);
            await this.store.deleteExpired(row.kind, row.id);
          } catch {
            this.report("github_expired_credential_cleanup_failed");
          }
        }),
      );
  }
}
