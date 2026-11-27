import { stripVTControlCharacters } from "node:util";
import type {
  GetPullRequestCommentExecutionData,
  GetPullRequestFailureLogData,
} from "@openci/dispatch-admin";
import { inlineCode } from "./executor/pull_request_comment.js";
import { dashboardRunUrl, urlSegment } from "./links.js";

type Job = NonNullable<GetPullRequestCommentExecutionData["job"]>;
type Attempt = NonNullable<GetPullRequestCommentExecutionData["latest"]>;
type Log = GetPullRequestFailureLogData["run"];
type Diagnostic = { path: string; line: string; column: string; text: string; severity: string };
const maxRows = 10;

function pathInRepository(path: string): string | null {
  const value = path
    .trim()
    .replace(/^\/Users\/admin\/openci-build\//u, "")
    .replace(/^\.\//u, "");
  if (
    !value ||
    value.length > 400 ||
    /[\\:\p{C}]/u.test(value) ||
    value.split("/").some((part) => !part || part === "." || part === "..")
  )
    return null;
  return value;
}

const flutterDiagnostic =
  /^(?<severity>error|warning|info) +• +(?<text>.+?) +• +(?<path>.+?):(?<line>[1-9]\d{0,6}):(?<column>[1-9]\d{0,5}) +• +[\w-]+$/iu;
const dartDiagnostic =
  /^(?<severity>error|warning|info) +- +(?<path>.+?):(?<line>[1-9]\d{0,6}):(?<column>[1-9]\d{0,5}) +- +(?<text>.+?) +- +[\w-]+$/iu;
const compilerDiagnostic =
  /^(?<path>.+?):(?<line>[1-9]\d{0,6}):(?<column>[1-9]\d{0,5}): +(?<severity>error|warning): +(?<text>.+)$/iu;

function diagnostic(line: string): Diagnostic | null {
  const match = (
    flutterDiagnostic.exec(line) ??
    dartDiagnostic.exec(line) ??
    compilerDiagnostic.exec(line)
  )?.groups;
  if (!match) return null;
  const path = pathInRepository(match.path);
  if (!path) return null;
  return {
    path,
    line: match.line,
    column: match.column,
    severity: match.severity.toLowerCase(),
    text: match.text.replace(/\. Try .+$/u, "."),
  };
}

// Only the failed step's persisted, already-masked output is eligible. The
// workflow SDK delineates completed commands; ignore their output and any
// secondary errors printed by the package runner after the command failed.
function failureDetails(run: Log) {
  const step = run?.failed[0]?.stepId;
  const entries = (run?.tail ?? []).filter((entry) => step && entry.stepId === step).reverse();
  const pending: Record<string, string> = { stdout: "", stderr: "" };
  const lines: string[] = [];
  for (const { stream, message } of entries) {
    const parts = ((pending[stream] ?? "") + message).split(/\r\n?|\n/u);
    pending[stream] = parts.pop()!;
    lines.push(...parts);
  }
  lines.push(...Object.values(pending));
  const diagnostics: Diagnostic[] = [];
  const errors: string[] = [];
  let command = "";
  let exitCode: string | undefined;
  for (const raw of lines) {
    const line = stripVTControlCharacters(raw)
      .replace(/\p{C}/gu, "")
      .trim()
      .replace(/^\[(?:STDOUT|STDERR)\]\s*/u, "")
      .trim();
    if (line.startsWith('[OK] command "') && line.endsWith('" executed successfully')) {
      diagnostics.length = errors.length = 0;
      continue;
    }
    const failed = /^\[ERROR\] command "(.+)" failed with exit code (\d{1,3})$/u.exec(line);
    if (failed) {
      command =
        /^(flutter analyze|dart analyze|flutter test|dart test|npm test)(?:\s|$)/u.exec(
          failed[1],
        )?.[1] ?? "";
      exitCode = failed[2];
      break;
    }
    if (
      !line ||
      line.length > 2000 ||
      /(?:\b(?:bearer|basic)\s+\S{8,}|\b(?:[\w-]*(?:password|token|secret|api[_-]?key)|authorization)\s*[:=]|\b(?:gh[pousr]_|github_pat_)\w+|:\/\/[^\s/]*@|-----BEGIN .*PRIVATE KEY)/iu.test(
        line,
      )
    )
      continue;
    const issue = diagnostic(line);
    if (issue) diagnostics.push(issue);
    else if (
      /^(?:\[(?:error|fatal)\]\s+|(?:error|fatal|exception|failed|failure)(?:[:\s]|$)|(?:expected|actual|which|assertion failed):\s|execution failed for task\s|[\w.]+(?:Error|Exception):\s)/iu.test(
        line,
      )
    )
      errors.push(line.slice(0, 320));
  }
  // Prefer errors, then warnings (which can be fatal), then information-level lints.
  const severity = ["error", "warning", "info"].find((value) =>
    diagnostics.some((d) => d.severity === value),
  );
  return {
    step,
    command,
    exitCode,
    issues: diagnostics.filter((d) => d.severity === severity),
    severity,
    errors: [...new Set(errors)].slice(-3),
  };
}

function repositoryUrl(job: Job) {
  return `${job.githubBaseUrl ?? "https://github.com"}/${encodeURIComponent(job.owner)}/${encodeURIComponent(job.repo)}`;
}
function commitLink(job: Job) {
  return `[${job.commitSha!.slice(0, 7)}](${repositoryUrl(job)}/commit/${job.commitSha})`;
}
function workflowName(job: Job) {
  const value = [job.workflowName || job.workflowFileName, job.matrixLabel]
    .filter(Boolean)
    .join(" · ")
    .slice(0, 180);
  return /^[\p{L}\p{N} .-]+$/u.test(value) ? value : inlineCode(value);
}
function checkLink(job: Job, id: string | null | undefined, label: string) {
  return id && /^\d+$/u.test(id) ? `[${label}](${repositoryUrl(job)}/runs/${id})` : "";
}

export async function failedPullRequestComment(
  job: Job,
  attempt: Attempt,
  log: Log,
  resolveFiles: (paths: string[]) => Promise<Map<string, string>>,
  dashboardOrigin?: string,
) {
  const { step, command, exitCode, issues, severity, errors } = failureDetails(log);
  const failedStep = command || step;
  const name = workflowName(job);
  const commit = commitLink(job);
  const finding = severity === "error" ? "エラー" : "指摘";
  const section = [
    `### ❌ ${name} が${attempt.outcome === "timed_out" ? "タイムアウト" : "失敗"}しました`,
  ];
  section.push(
    issues.length
      ? `${commit} で${command ? " " + inlineCode(command) + " が" : ""} ${issues.length} 件の${finding}を検出しました。`
      : [commit, failedStep && inlineCode(failedStep), exitCode ? "終了コード " + exitCode : null]
          .filter(Boolean)
          .join(" · "),
  );
  section.push(`<!-- openci-failure-details:${issues.length} -->`);
  const visible = issues.slice(0, maxRows);
  const paths = [...new Set(visible.map((issue) => issue.path))];
  const files = await resolveFiles(paths);
  for (const path of paths) {
    const rows = visible.filter((issue) => issue.path === path);
    const source = files.get(path);
    const encoded = source?.split("/").map(urlSegment).join("/");
    const url =
      encoded && encoded.length <= 1200
        ? `${repositoryUrl(job)}/blob/${job.commitSha}/${encoded}`
        : null;
    section.push(url ? `[${inlineCode(source!)}](${url})` : inlineCode(path));
    section.push(
      [
        `| 行・列 | ${finding} |`,
        "| --- | --- |",
        ...rows.map((row) => {
          const position = `${row.line}:${row.column}`;
          const location = url ? `[${position}](${url}#L${row.line})` : position;
          const message = row.text.slice(0, 320);
          const rendered = /^[\p{L}\p{N} '.,:;()?!-]+$/u.test(message)
            ? message.replace(/'[\p{L}\p{N}.]+'/gu, inlineCode)
            : inlineCode(message).replaceAll("|", "\\|");
          return `| ${location} | ${rendered} |`;
        }),
      ].join("\n"),
    );
  }
  if (issues.length > maxRows) section.push(`先頭 ${maxRows} 件を表示しています。`);
  if (!issues.length) {
    if (attempt.failureSummary) section.push(inlineCode(attempt.failureSummary.slice(0, 500)));
    else if (errors.length) section.push(errors.map((s) => inlineCode(s)).join("  \n"));
  }
  const runUrl = dashboardRunUrl(dashboardOrigin, job.id);
  const link = runUrl
    ? `[OpenCI で実行ログを見る](${runUrl})`
    : checkLink(job, attempt.checkRunId, "GitHub でチェックを見る");
  if (link) section.push(link);
  return section.join("\n\n");
}

export function resolvedPullRequestComment(
  job: Job,
  checkId: string | null | undefined,
  previous: string | null,
) {
  if (!previous?.startsWith("### ❌ ")) return null;
  const details = /\n<!-- openci-failure-details:(\d+) -->\n\n([\s\S]+)$/u.exec(previous);
  const section = [
    `### ✅ ${workflowName(job)} のエラーが解消しました`,
    `${commitLink(job)} でワークフローが成功しました。`,
  ];
  if (details)
    section.push(
      `<details>\n<summary>前回のエラーを見る${details[1] === "0" ? "" : "（" + details[1] + "件）"}</summary>\n\n${details[2]}\n\n</details>`,
    );
  const link = checkLink(job, checkId, "成功したチェックを見る");
  if (link) section.push(link);
  return section.join("\n\n");
}

export function successfulPullRequestComment(job: Job, dashboardOrigin?: string) {
  const run = dashboardRunUrl(dashboardOrigin, job.id);
  return [
    `### ✅ ${workflowName(job)} が成功しました`,
    `${commitLink(job)} でワークフローが成功しました。`,
    ...(run ? [`[OpenCI で実行ログを見る](${run})`] : []),
  ].join("\n\n");
}
