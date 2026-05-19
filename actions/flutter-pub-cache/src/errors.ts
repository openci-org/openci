export class UsageError extends Error {}
export class OperationError extends Error {}

export function messageFrom(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
