import { createHash } from "node:crypto";
import { renderSVG } from "uqr";
import { prQrOutputDirectory, type Job } from "./model.js";
import type { OrchardExecutor } from "./orchard.js";

type GitHubRequest = (typeof import("@octokit/request"))["request"];
const mediaBranch = "genuineci/pr-qr";
export const qrPublicationFailure =
  "GenuineCI could not publish the QR code to this pull request. Check the GitHub App's Contents and Pull requests write permissions and the genuineci/pr-qr branch rules.";
const maxUrls = 8;
const maxUrlBytes = 2331; // QR version 40, byte mode, medium error correction.
const maxReleaseMetadataBytes = 2048;
const commentText = {
  en: {
    workflow: "Workflow name",
    version: "Version",
    buildNumber: "Build number",
    alt: "QR code for this link",
  },
  ja: {
    workflow: "ワークフロー名",
    version: "バージョン",
    buildNumber: "ビルド番号",
    alt: "このリンクのQRコード",
  },
} as const;
const defaultQrDimension = 180;
const maxQrDimension = 1000;
export type PullRequestQrCode = {
  url: string;
  lang: keyof typeof commentText;
  width: number;
  height: number;
  version?: string;
  buildNumber?: string;
};
export type WithQrCommentLease = (
  key: string,
  work: (renew: () => Promise<void>) => Promise<void>,
) => Promise<void>;

function validatedQrCode(
  url: string,
  lang: string,
  width = defaultQrDimension,
  height = defaultQrDimension,
  metadata: unknown = {},
): PullRequestQrCode {
  if (lang !== "en" && lang !== "ja") throw new Error("Invalid pull request QR language");
  if (
    !Number.isInteger(width) ||
    width < 1 ||
    width > maxQrDimension ||
    !Number.isInteger(height) ||
    height < 1 ||
    height > maxQrDimension
  ) {
    throw new Error("Invalid pull request QR size");
  }
  // The SDK serializes URIs as ASCII. Require a credential-free authority and
  // exclude characters that could terminate a Markdown autolink.
  if (
    url.length > maxUrlBytes ||
    /[^!-~]|[<>\\]/u.test(url) ||
    !/^https?:\/\/[^/@?#]+(?:[/?#]|$)/i.test(url) ||
    !URL.canParse(url)
  ) {
    throw new Error("Invalid pull request QR URL");
  }
  return { url, lang, width, height, ...validatedReleaseMetadata(metadata) };
}

function validatedReleaseMetadata(
  metadata: unknown,
): Pick<PullRequestQrCode, "version" | "buildNumber"> {
  if (typeof metadata !== "object" || metadata === null || Array.isArray(metadata))
    throw new Error("Invalid app release metadata");
  const result: Pick<PullRequestQrCode, "version" | "buildNumber"> = {};
  for (const field of ["version", "buildNumber"] as const) {
    const value = (metadata as Record<string, unknown>)[field];
    if (value === undefined) continue;
    if (
      typeof value !== "string" ||
      !value.length ||
      Buffer.byteLength(value, "utf8") > 256 ||
      [...value].some((character) => character < " " || character === "\u007f") ||
      value.trim() !== value
    ) {
      throw new Error("Invalid app release metadata");
    }
    result[field] = value;
  }
  return result;
}

function decodedOutput(value: string, limit: number): Buffer {
  const bytes = Buffer.from(value, "base64");
  if (bytes.length > limit || bytes.toString("base64") !== value)
    throw new Error("Invalid pull request QR output");
  return bytes;
}

function parseDimensions(raw: string): [number, number] {
  const match = /^([1-9][0-9]{0,3})x([1-9][0-9]{0,3})$/.exec(raw);
  if (!match) throw new Error("Invalid pull request QR size");
  return [Number(match[1]), Number(match[2])];
}

export async function readPullRequestQrCodes(
  orchard: Pick<OrchardExecutor, "exec">,
  vmName: string,
  signal: AbortSignal,
): Promise<PullRequestQrCode[]> {
  // Bound both the legacy URL records and optional metadata before decoding.
  const urlLimit = maxUrls * (13 + maxUrlBytes + 1);
  const limit = Math.ceil(((urlLimit + maxUrls * maxReleaseMetadataBytes) * 4) / 3) + maxUrls * 32;
  let content = "";
  const code = await orchard.exec(
    vmName,
    [
      "set -euo pipefail",
      `dir=${prQrOutputDirectory}`,
      "shopt -s nullglob",
      'files=("$dir"/qr-*/url)',
      'if [ -s "$dir/legacy" ]; then files+=("$dir/legacy"); fi',
      `[ "\${#files[@]}" -le ${maxUrls} ] || exit 1`,
      'for file in "${files[@]}"; do',
      '  [ -f "$file" ] && [ ! -L "$file" ] || exit 1',
      "  printf 'openci-qr\\t'",
      `  /usr/bin/head -c ${urlLimit + 1} "$file" | /usr/bin/base64 | /usr/bin/tr -d '\\r\\n'`,
      "  printf '\\t'",
      '  metadata="${file%/url}/metadata.json"',
      '  if [ -e "$metadata" ] || [ -L "$metadata" ]; then',
      '    [ -f "$metadata" ] && [ ! -L "$metadata" ] || exit 1',
      `    /usr/bin/head -c ${maxReleaseMetadataBytes + 1} "$metadata" | /usr/bin/base64 | /usr/bin/tr -d '\\r\\n'`,
      "  fi",
      "  printf '\\n'",
      "done\n",
    ].join("\n"),
    async (stream, bytes) => {
      if (stream !== "stdout") return;
      if (content.length + bytes.length > limit)
        throw new Error("Pull request QR output exceeds its limit");
      content += bytes.toString("latin1");
    },
    AbortSignal.any([signal, AbortSignal.timeout(10000)]),
  );
  if (code !== 0) throw new Error("Could not read pull request QR URLs");
  if (!content) return [];
  const lines = content.split("\n");
  if (lines.pop() !== "" || lines.length > maxUrls)
    throw new Error("Invalid pull request QR output");
  const records: { line: string; metadata: unknown }[] = [];
  for (const line of lines) {
    if (!line.startsWith("openci-qr\t")) {
      records.push({ line, metadata: {} });
      continue;
    }
    const fields = line.split("\t");
    if (fields.length !== 3) throw new Error("Invalid pull request QR output");
    const urls = decodedOutput(fields[1], urlLimit).toString("latin1").split("\n");
    if (urls.pop() !== "" || !urls.length) throw new Error("Invalid pull request QR output");
    let metadata: unknown = {};
    if (fields[2]) {
      if (urls.length !== 1) throw new Error("Ambiguous app release metadata");
      metadata = JSON.parse(
        new TextDecoder("utf-8", { fatal: true }).decode(
          decodedOutput(fields[2], maxReleaseMetadataBytes),
        ),
      );
    }
    for (const url of urls) records.push({ line: url, metadata });
  }
  if (records.length > maxUrls) throw new Error("Invalid pull request QR output");
  const unique = new Map<string, PullRequestQrCode>();
  for (const { line, metadata } of records) {
    // Earlier SDKs emitted a bare URL or language + URL without dimensions.
    const fields = line.split("\t");
    if (fields.length > 3) throw new Error("Invalid pull request QR output");
    const code =
      fields.length === 1
        ? validatedQrCode(fields[0], "en", undefined, undefined, metadata)
        : fields.length === 2
          ? validatedQrCode(fields[1], fields[0], undefined, undefined, metadata)
          : validatedQrCode(fields[2], fields[0], ...parseDimensions(fields[1]), metadata);
    unique.set(JSON.stringify(code), code);
  }
  return [...unique.values()];
}

function hasStatus(error: unknown, ...codes: number[]): boolean {
  return error instanceof Error && "status" in error && codes.includes(Number(error.status));
}

function imagePath(url: string): string {
  return `qr/${createHash("sha256").update(url).digest("hex")}.svg`;
}

function inlineCode(value: string): string {
  const text = value.replace(/[\r\n]/gu, " ").trim();
  const ticks = Math.max(0, ...(text.match(/`+/gu) ?? []).map((run) => run.length)) + 1;
  const fence = "`".repeat(ticks);
  const padding = text.startsWith("`") || text.endsWith("`") ? " " : "";
  return `${fence}${padding}${text}${padding}${fence}`;
}

// Keep the media in the source repository so its access rules also protect the QR.
// Root the branch at its first image and fast-forward it without changing application branches.
async function saveImages(
  request: GitHubRequest,
  repo: { owner: string; repo: string },
  links: string[],
) {
  const tree = links.map((link) => ({
    path: imagePath(link),
    mode: "100644" as const,
    type: "blob" as const,
    content: renderSVG(link, { border: 4, ecc: "M" }),
  }));
  const ref = `heads/${mediaBranch}`;
  for (let attempt = 0; attempt < 4; attempt++) {
    const tip = await request("GET /repos/{owner}/{repo}/git/ref/{ref}", { ...repo, ref })
      .then(({ data }) => data.object.sha)
      .catch((error: unknown) => {
        if (hasStatus(error, 404)) return null;
        throw error;
      });
    const baseTree = tip
      ? (
          await request("GET /repos/{owner}/{repo}/git/commits/{commit_sha}", {
            ...repo,
            commit_sha: tip,
          })
        ).data.tree.sha
      : undefined;
    const { data: next } = await request("POST /repos/{owner}/{repo}/git/trees", {
      ...repo,
      base_tree: baseTree,
      tree,
    });
    if (tip && next.sha === baseTree) return tip;
    const { data: commit } = await request("POST /repos/{owner}/{repo}/git/commits", {
      ...repo,
      message: "Store workflow QR code",
      tree: next.sha,
      parents: tip ? [tip] : [],
    });
    try {
      if (tip) {
        await request("PATCH /repos/{owner}/{repo}/git/refs/{ref}", {
          ...repo,
          ref,
          sha: commit.sha,
          force: false,
        });
      } else {
        await request("POST /repos/{owner}/{repo}/git/refs", {
          ...repo,
          ref: `refs/${ref}`,
          sha: commit.sha,
        });
      }
      return commit.sha;
    } catch (error) {
      // Concurrent runs may have created or advanced the branch. Rebuild on the new tip.
      if (!hasStatus(error, 409, 422) || attempt === 3) throw error;
    }
  }
  throw new Error("Could not save pull request QR codes");
}

export async function publishPullRequestQrCodes(
  request: GitHubRequest,
  appId: string,
  job: Job,
  accountId: string,
  runNumber: number,
  codes: PullRequestQrCode[],
  withLease: WithQrCommentLease,
): Promise<void> {
  if (!job.pullRequestNumber || !codes.length) return;
  if (codes.length > maxUrls) throw new Error("Too many pull request QR codes");
  for (const code of codes)
    validatedQrCode(code.url, code.lang, code.width, code.height, {
      version: code.version,
      buildNumber: code.buildNumber,
    });
  const repo = { owner: job.owner, repo: job.repo };
  const number = Number(job.pullRequestNumber);
  const target = (await request("GET /repos/{owner}/{repo}", repo)).data;
  if (
    String(target.owner.id) !== accountId ||
    target.full_name.toLowerCase() !== `${repo.owner}/${repo.repo}`.toLowerCase()
  ) {
    throw new Error("Pull request repository owner changed");
  }
  const current = async () => {
    const { data: pr } = await request("GET /repos/{owner}/{repo}/pulls/{pull_number}", {
      ...repo,
      pull_number: number,
    });
    return (
      pr.number === number &&
      pr.state === "open" &&
      pr.base.repo.id === target.id &&
      pr.head.repo?.id === target.id &&
      pr.head.sha === job.commitSha
    );
  };
  if (!(await current())) return;
  const scope = createHash("sha256")
    .update(
      JSON.stringify([
        job.githubBaseUrl ?? "https://github.com",
        appId,
        target.id,
        number,
        job.workflowFileName,
      ]),
    )
    .digest("hex");
  // Run numbers are monotonic within a team. A repository moved to a new
  // team can reuse the comment even if that team's sequence starts lower.
  const team = createHash("sha256").update(job.teamId!).digest("hex");
  const footer = new RegExp(`\\n<!-- openci-pr-qr:${scope}:([a-f0-9]{64}):([1-9][0-9]*) -->$`);
  const marker = `<!-- openci-pr-qr:${scope}:${team}:${runNumber} -->`;
  const issue = { ...repo, issue_number: number };
  const findComment = async (renew: () => Promise<void>) => {
    for (let page = 1; ; page++) {
      if (page > 1) await renew();
      const { data } = await request("GET /repos/{owner}/{repo}/issues/{issue_number}/comments", {
        ...issue,
        page,
        per_page: 100,
      });
      for (const comment of data) {
        if (comment.user?.type !== "Bot" || String(comment.performed_via_github_app?.id) !== appId)
          continue;
        const match = footer.exec(comment.body ?? "");
        if (match) return { id: comment.id, team: match[1], run: BigInt(match[2]) };
      }
      if (data.length < 100) return null;
    }
  };
  const urls = [...new Set(codes.map((code) => code.url))];
  const commit = await saveImages(request, repo, urls);
  const sections: string[] = [];
  for (const lang of new Set(codes.map((code) => code.lang))) {
    const labels = commentText[lang];
    for (const { url, width, height, version, buildNumber } of codes.filter(
      (code) => code.lang === lang,
    )) {
      const details = [
        `${labels.workflow}: ${inlineCode(job.workflowName ?? job.workflowFileName!)}`,
      ];
      if (version) details.push(`${labels.version}: ${inlineCode(version)}`);
      if (buildNumber) details.push(`${labels.buildNumber}: ${inlineCode(buildNumber)}`);
      sections.push(details.join("  \n"));
      // GitHub expands HTML entities inside autolinks, e.g. &copy; in a query.
      const markdownUrl = url.replaceAll("&", "&amp;");
      sections.push(
        `<${markdownUrl}>\n\n<img src="../blob/${commit}/${imagePath(url)}?raw=true" alt="${labels.alt}" width="${width}" height="${height}">`,
      );
    }
  }
  const body = [...sections, marker].join("\n\n");
  await withLease(scope, async (renew) => {
    const existing = await findComment(renew);
    const coversRun = (comment: typeof existing) =>
      comment !== null && comment.team === team && comment.run >= BigInt(runNumber);
    if (coversRun(existing) || !(await current())) return;
    // Only the holder may make the bounded GitHub write; a late old run must
    // re-read the comment if another executor has taken its lease.
    await renew();
    if (existing) {
      try {
        await request("PATCH /repos/{owner}/{repo}/issues/comments/{comment_id}", {
          ...repo,
          comment_id: existing.id,
          body,
        });
        return;
      } catch (error) {
        const observed = await findComment(renew);
        if (coversRun(observed)) return;
        if (!hasStatus(error, 404) || observed) throw error;
        // Someone deleted the comment between the lookup and the edit.
        if (!(await current())) return;
        await renew();
      }
    }
    try {
      await request("POST /repos/{owner}/{repo}/issues/{issue_number}/comments", {
        ...issue,
        body,
      });
    } catch (error) {
      if (!coversRun(await findComment(renew))) throw error;
    }
  });
}
