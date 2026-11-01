import type { GitHubApi } from "./github.js";
import { type Json, object, PullRequest, Repository, RestackException } from "./models.js";
import { stackFor } from "./stack.js";

export const marker = "<!-- stacked-pr-app:stack -->";
export function escapeText(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("|", "&#124;")
    .replaceAll("@", "&#64;")
    .replace(/[\r\n]+/g, " ")
    .replace(/[\\`*_[\]]/g, "\\$&");
}
interface ReportOptions {
  error?: RestackException;
  observeOnly?: boolean;
  closedToUpdate?: number[];
}
export function render(
  pulls: PullRequest[],
  pr: PullRequest,
  { error, observeOnly = false }: ReportOptions = {},
): { body: string; title: string; conclusion: string; connected: boolean } {
  let stack: PullRequest[];
  try {
    stack = stackFor(pulls, pr.number);
  } catch (failure) {
    if (!(failure instanceof RestackException)) throw failure;
    stack = pulls;
  }
  const active = stack.filter((p) => p.isOpen),
    position = active.findIndex((p) => p.number === pr.number) + 1;
  const title = pr.isOpen ? `Stack · ${position} / ${active.length}` : "Stack · closed";
  const lines = [
    marker,
    `## ${title}`,
    "",
    "| PR | 依存先 | 内容 | 状態 |",
    "| --- | --- | --- | --- |",
  ];
  for (const item of stack) {
    const current = item.number === pr.number;
    const status = item.merged ? "Merged" : !item.isOpen ? "Closed" : item.draft ? "Draft" : "Open";
    lines.push(
      `| ${current ? "**→ " : ""}#${item.number}${current ? "**" : ""} | ${item.parent === undefined ? "—" : `#${item.parent}`} | ${escapeText(item.title)} | ${status} |`,
    );
  }
  const parent = pulls.find((p) => p.number === pr.parent && p.isOpen);
  let conclusion = parent ? "action_required" : "success";
  if (
    error &&
    (error.number === undefined || stack.some((member) => member.number === error.number))
  ) {
    conclusion = "failure";
    lines.push(
      "",
      `**Restack停止${error.number === undefined ? "" : ` · #${error.number}`}：${escapeText(error.message)}**`,
    );
    if (error.files.length)
      lines.push(
        "",
        "競合ファイル：",
        ...error.files.slice(0, 30).map((f) => `- ${escapeText(f)}`),
      );
    lines.push("", "履歴または設定を修正してから `/stack sync` を実行してください。");
  } else {
    lines.push(
      "",
      parent
        ? `依存先：#${parent.number}。親PRを先にmergeしてください。`
        : "依存する未mergeの親PRはありません。",
      "",
      observeOnly
        ? "観察モード：自動rebaseは無効です。`/stack sync` で実行できます。"
        : "親の更新・merge後は、子PR固有の変更を自動でrebaseします。",
    );
  }
  lines.push(
    "",
    "`/stack sync`：状態を再確認し、必要なrebaseを実行",
    "",
    "自動更新後は `git fetch origin` で最新の履歴を取得してください。ローカル変更がある場合の同期方法は、このAppのREADMEを参照してください。",
  );
  return { body: lines.join("\n"), title, conclusion, connected: stack.length > 1 };
}
export class Reporter {
  constructor(readonly api: GitHubApi) {}
  async publish(
    installation: number,
    repo: Repository,
    pulls: PullRequest[],
    options: ReportOptions = {},
  ): Promise<void> {
    const app = await this.api.identity(),
      path = repo.apiPath;
    for (const pr of pulls) {
      if (!pr.sameRepo || (!pr.isOpen && !options.closedToUpdate?.includes(pr.number))) continue;
      const view = render(pulls, pr, options);
      const comments = await this.api.list(installation, `${path}/issues/${pr.number}/comments`);
      const existing = comments.find(
        (c) =>
          typeof c.body === "string" &&
          c.body.startsWith(marker) &&
          (object(c.performed_via_github_app).id === app.id ||
            (object(c.user).type === "Bot" && object(c.user).login === `${app.slug}[bot]`)),
      );
      if (!view.connected && !existing && view.conclusion !== "failure") continue;
      if (!existing)
        await this.api.request(installation, "POST", `${path}/issues/${pr.number}/comments`, {
          body: view.body,
        });
      else if (existing.body !== view.body)
        await this.api.request(installation, "PATCH", `${path}/issues/comments/${existing.id}`, {
          body: view.body,
        });
      if (!pr.isOpen) continue;
      const externalId = `stacked-pr:${repo.id}:${pr.number}`;
      const checks = await this.api.list(
        installation,
        `${path}/commits/${pr.head}/check-runs?filter=all`,
        "check_runs",
      );
      const check = checks.find((c) => object(c.app).id === app.id && c.external_id === externalId);
      const body: Json = {
        status: "completed",
        conclusion: view.conclusion,
        output: { title: view.title, summary: view.body },
        actions: [
          {
            label: "Sync",
            description: "Synchronize dependent pull requests",
            identifier: "restack",
          },
        ],
      };
      if (!check)
        await this.api.request(installation, "POST", `${path}/check-runs`, {
          ...body,
          name: "Stacked PR",
          head_sha: pr.head,
          external_id: externalId,
        });
      else if (check.conclusion !== view.conclusion || object(check.output).summary !== view.body)
        await this.api.request(installation, "PATCH", `${path}/check-runs/${check.id}`, body);
    }
  }
}
