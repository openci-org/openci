import { createHash } from "node:crypto";
import { renderSVG } from "uqr";
import { fadPrOutputPath, type Dispatch, type Job } from "./model.js";
import type { OrchardExecutor } from "./orchard.js";

type GitHubRequest = (typeof import("@octokit/request"))["request"];
const mediaBranch = "genuineci/fad-qr";
export const fadPrPublicationFailure =
  "Firebase accepted the IPA, but GenuineCI could not publish the QR code. Check the GitHub App's Contents and Pull requests write permissions and the genuineci/fad-qr branch rules.";
const testerLink =
  /^https:\/\/appdistribution\.firebase\.google\.com\/testerapps\/\d{1,3}:\d{1,30}:ios:[A-Za-z0-9]{1,80}\/releases\/[A-Za-z0-9_-]{1,128}$/;

export async function readFadTesterLinks(
  orchard: Pick<OrchardExecutor, "exec">,
  vmName: string,
  signal: AbortSignal,
): Promise<string[]> {
  const limit = 4096;
  let content = "";
  const code = await orchard.exec(
    vmName,
    `set -eu\nfile=${fadPrOutputPath}\n[ -f "$file" ] && [ ! -L "$file" ] || exit 1\n/usr/bin/head -c ${limit + 1} "$file"\n`,
    async (stream, bytes) => {
      if (stream !== "stdout") return;
      if (content.length + bytes.length > limit) throw new Error("FAD output exceeds its limit");
      content += bytes.toString("latin1");
    },
    AbortSignal.any([signal, AbortSignal.timeout(10000)]),
  );
  if (code !== 0) throw new Error("Could not read the FAD tester links");
  if (!content) return [];
  const lines = content.split("\n");
  if (lines.pop() !== "" || lines.length > 8 || !lines.every((line) => testerLink.test(line))) {
    throw new Error("Invalid FAD tester link output");
  }
  return [...new Set(lines)];
}

function hasStatus(error: unknown, ...codes: number[]): boolean {
  return error instanceof Error && "status" in error && codes.includes(Number(error.status));
}

// Keep the media in the source repository so its access rules also protect the QR.
// Root the branch at its first image and fast-forward it without changing application branches.
async function saveImages(
  request: GitHubRequest,
  repo: { owner: string; repo: string },
  links: string[],
) {
  const tree = links.map((link) => ({
    path: `fad/${createHash("sha256").update(link).digest("hex")}.svg`,
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
    if (tip && next.sha === baseTree) return { commit: tip, paths: tree.map((file) => file.path) };
    const { data: commit } = await request("POST /repos/{owner}/{repo}/git/commits", {
      ...repo,
      message: "Store Firebase App Distribution QR code",
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
      return { commit: commit.sha, paths: tree.map((file) => file.path) };
    } catch (error) {
      // Concurrent runs may have created or advanced the branch. Rebuild on the new tip.
      if (!hasStatus(error, 409, 422) || attempt === 3) throw error;
    }
  }
  throw new Error("Could not save FAD QR codes");
}

export async function publishFadPullRequest(
  request: GitHubRequest,
  appId: string,
  job: Job,
  accountId: string,
  dispatch: Dispatch,
  runNumber: number,
  links: string[],
): Promise<void> {
  if (!job.pullRequestNumber || !links.length) return;
  if (!links.every((link) => testerLink.test(link))) throw new Error("Invalid FAD tester link");
  const repo = { owner: job.owner, repo: job.repo };
  const number = Number(job.pullRequestNumber);
  const target = (await request("GET /repos/{owner}/{repo}", repo)).data;
  if (
    String(target.owner.id) !== accountId ||
    target.full_name.toLowerCase() !== `${repo.owner}/${repo.repo}`.toLowerCase()
  ) {
    throw new Error("FAD repository owner changed");
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
  const marker = `<!-- openci-fad-pr:${dispatch.runId} -->`;
  const issue = { ...repo, issue_number: number };
  const alreadyPosted = async () => {
    for (let page = 1; ; page++) {
      const { data } = await request("GET /repos/{owner}/{repo}/issues/{issue_number}/comments", {
        ...issue,
        since: dispatch.createdAt,
        page,
        per_page: 100,
      });
      if (
        data.some(
          (comment) =>
            String(comment.performed_via_github_app?.id) === appId &&
            comment.body?.endsWith(marker),
        )
      )
        return true;
      if (data.length < 100) return false;
    }
  };
  if (await alreadyPosted()) return;
  const images = await saveImages(request, repo, links);
  const body = [
    `**Firebase App Distribution · iOS · Run #${runNumber}** (\`${job.commitSha!.slice(0, 7)}\`)`,
    ...links.map(
      (link, index) =>
        `[Open this build in Firebase App Distribution](${link})\n\n![Tester QR code](../blob/${images.commit}/${images.paths[index]}?raw=true)`,
    ),
    marker,
  ].join("\n\n");
  if (!(await current())) return;
  try {
    await request("POST /repos/{owner}/{repo}/issues/{issue_number}/comments", { ...issue, body });
  } catch (error) {
    // The comment may exist even when its response was lost.
    if (!(await alreadyPosted())) throw error;
  }
}
