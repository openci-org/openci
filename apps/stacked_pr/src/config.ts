import { createPrivateKey } from "node:crypto";
import { resolve } from "node:path";

export type Environment = Record<string, string | undefined>;
export function required(env: Environment, name: string): string {
  const value = env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}
export interface AppConfig {
  githubUrl: string;
  apiUrl: string;
  graphqlUrl: string;
  appId: string;
  privateKey: string;
  dataDir: string;
  autoRestack: boolean;
  allowedRepos: Set<string>;
}
export function configFromEnvironment(env: Environment, dataDir: string): AppConfig {
  const origin = new URL(required(env, "GITHUB_URL"));
  if (
    origin.protocol !== "https:" ||
    !origin.hostname ||
    origin.username ||
    origin.password ||
    !["", "/"].includes(origin.pathname) ||
    origin.search ||
    origin.hash
  ) {
    throw new Error("GITHUB_URL must be an HTTPS origin");
  }
  const appId = required(env, "GITHUB_APP_ID");
  if (!/^\d+$/.test(appId)) throw new Error("GITHUB_APP_ID must be numeric");
  const privateKey = required(env, "GITHUB_APP_PRIVATE_KEY");
  if (createPrivateKey(privateKey).asymmetricKeyType !== "rsa")
    throw new Error("GitHub App requires an RSA private key");
  if (env.AUTO_RESTACK !== undefined && !["true", "false"].includes(env.AUTO_RESTACK))
    throw new Error("AUTO_RESTACK must be true or false");
  return {
    githubUrl: origin.origin,
    appId,
    privateKey,
    apiUrl: origin.hostname === "github.com" ? "https://api.github.com" : `${origin.origin}/api/v3`,
    graphqlUrl:
      origin.hostname === "github.com"
        ? "https://api.github.com/graphql"
        : `${origin.origin}/api/graphql`,
    dataDir: resolve(dataDir),
    autoRestack: env.AUTO_RESTACK !== "false",
    allowedRepos: new Set(
      (env.ALLOWED_REPOSITORIES ?? "")
        .split(",")
        .map((s) => s.trim().toLowerCase())
        .filter(Boolean),
    ),
  };
}
