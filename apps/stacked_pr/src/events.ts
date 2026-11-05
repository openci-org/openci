import { type Json, object } from "./models.js";

/** Restack already refreshes the affected stack; its own writes need no new pass. */
export function isSelfUpdate(event: string, payload: Json, botLogin?: string): boolean {
  const sender = object(payload.sender);
  return (
    !!botLogin &&
    sender.type === "Bot" &&
    typeof sender.login === "string" &&
    sender.login.toLowerCase() === botLogin.toLowerCase() &&
    (event === "push" ||
      (event === "pull_request" && ["synchronize", "edited"].includes(payload.action as string)))
  );
}
