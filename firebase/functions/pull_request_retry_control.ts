import type { EmitterWebhookEvent } from "@octokit/webhooks";
import { validJobId } from "./build_dispatch.js";

const label = "このジョブを再実行";
const unchecked = "- [ ] " + label;
const accepted = "⏳ 再実行を受け付けました。";
const denied = "再実行できませんでした。OpenCIでGitHub連携と権限を確認してください。";
const start = "\n\n<!-- openci-retry:";
const control =
  /\n\n<!-- openci-retry:([A-Za-z0-9_-]{1,340}):(0|[1-9]\d{0,9}) -->\n(?:[^\n]+\n)?- \[([ xX])\] このジョブを再実行\n\n(<!-- openci-pr-result:([a-f0-9]{64}):([a-f0-9]{64}):([1-9]\d{0,20}) -->)$/u;

export function retryControl(
  jobId: string,
  count: number,
  state: "ready" | "accepted" | "denied" = "ready",
) {
  const id = Buffer.from(jobId).toString("base64url");
  const line =
    state === "accepted" ? accepted : state === "denied" ? denied + "\n" + unchecked : unchecked;
  return `<!-- openci-retry:${id}:${count} -->\n${line}`;
}

export function withoutRetryControl(body: string) {
  const index = body.lastIndexOf(start);
  return index < 0 ? body : body.slice(0, index);
}

export function readRetryControl(body: string) {
  if (!body.startsWith("### ❌ ")) return null;
  const match = control.exec(body);
  if (!match) return null;
  const jobId = Buffer.from(match[1], "base64url").toString("utf8");
  const count = Number(match[2]);
  if (
    !validJobId(jobId) ||
    Buffer.from(jobId).toString("base64url") !== match[1] ||
    count >= 2147483647
  )
    return null;
  return {
    jobId,
    count,
    checked: match[3] !== " ",
    marker: match[4],
    scope: match[5],
    team: match[6],
    order: match[7],
  };
}

type EditedComment = EmitterWebhookEvent<"issue_comment.edited">["payload"];

export function retryCheckboxClick(event: EditedComment) {
  if (
    event.action !== "edited" ||
    !event.issue?.pull_request ||
    event.issue.state !== "open" ||
    event.comment?.user?.type !== "Bot" ||
    event.sender?.type !== "User" ||
    !event.changes?.body
  )
    return null;
  const body = event.comment.body?.replaceAll("\r\n", "\n") ?? "";
  const previous = event.changes.body.from?.replaceAll("\r\n", "\n");
  const selected = readRetryControl(body);
  if (
    !selected?.checked ||
    !previous ||
    body.replace(
      /- \[[xX]\] このジョブを再実行(?=\n\n<!-- openci-pr-result:[^\n]+ -->$)/u,
      unchecked,
    ) !== previous
  )
    return null;
  const ids = [
    event.installation?.id,
    event.repository?.id,
    event.issue.number,
    event.comment.id,
    event.sender.id,
  ];
  if (!ids.every((id) => Number.isSafeInteger(id) && Number(id) > 0) || !event.sender.login)
    return null;
  return {
    ...selected,
    installationId: String(event.installation!.id),
    repositoryId: String(event.repository.id),
    pr: String(event.issue.number),
    commentId: event.comment.id,
    actorId: String(event.sender.id),
    login: event.sender.login,
  };
}
export type RetryClick = NonNullable<ReturnType<typeof retryCheckboxClick>>;
