import { Timestamp } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

export const closedStatusId = "done";
export const reviewStatusId = "review";
export const inProgressStatusIds = new Set(["doing", "review"]);
export const issueWeightModel = "gemini-3.5-flash";
export const branchLogPathPrefix = ".openci/branch-log/";
export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value.trim();
}
export function requireUid(auth: CallableRequest["auth"]): string {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  return auth.uid;
}
export function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}
export function asNumber(value: unknown, fallback = 0): number {
  return typeof value === "number" ? value : fallback;
}
export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
export function errorStack(error: unknown): string | undefined {
  return error instanceof Error ? error.stack : undefined;
}
export function githubRestErrorStatus(error: unknown): number | null {
  const match = /^GitHub request failed: (?<status>\d{3}) /u.exec(errorMessage(error));
  const status = Number(match?.groups?.status);
  return Number.isInteger(status) ? status : null;
}
export function githubRestErrorResponseMessage(error: unknown): string {
  const match = /^GitHub request failed: \d{3} (?<body>[\s\S]*)$/u.exec(errorMessage(error));
  const body = match?.groups?.body?.trim() ?? "";
  if (body.length === 0) {
    return "";
  }
  try {
    const parsed = JSON.parse(body) as { message?: unknown };
    return typeof parsed.message === "string" ? parsed.message : body;
  } catch {
    return body;
  }
}
export function githubMergePreconditionMessage(error: unknown): string | null {
  const status = githubRestErrorStatus(error);
  if (status !== 405 && status !== 409) {
    return null;
  }
  const message = githubRestErrorResponseMessage(error);
  if (message.toLowerCase().includes("merge conflicts")) {
    return "Pull request has merge conflicts. Resolve the conflicts and try again.";
  }
  return message.length > 0 ? message : "Pull request is not mergeable right now.";
}
export function asBoolean(value: unknown, fallback = false): boolean {
  return typeof value === "boolean" ? value : fallback;
}
export function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((item): item is string => typeof item === "string" && item.length > 0);
}
export function asTimestamp(value: unknown): Timestamp | null {
  if (typeof value !== "string") {
    return null;
  }
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : Timestamp.fromDate(date);
}
export function timestampFromValue(value: unknown): Timestamp | null {
  if (value instanceof Timestamp) {
    return value;
  }
  if (value instanceof Date) {
    return Timestamp.fromDate(value);
  }
  return asTimestamp(value);
}
export function roundedHours(milliseconds: number | null): number | null {
  if (milliseconds === null) {
    return null;
  }
  return Math.round((milliseconds / 3_600_000) * 10) / 10;
}
export function median(values: number[]): number | null {
  if (values.length === 0) {
    return null;
  }
  const sorted = values.slice().sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  const middleValue = sorted[middle];
  if (middleValue === undefined) {
    return null;
  }
  if (sorted.length % 2 === 1) {
    return middleValue;
  }
  const previousValue = sorted[middle - 1];
  return previousValue === undefined ? middleValue : (previousValue + middleValue) / 2;
}
export function recordList(value: unknown): Array<Record<string, unknown>> {
  return Array.isArray(value)
    ? value.filter(
        (item): item is Record<string, unknown> => typeof item === "object" && item !== null,
      )
    : [];
}
