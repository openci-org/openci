import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

import { BuildJobStatus, getTeamById, updateBuildJobFailureSummary } from "../firestoreData.js";
import { getInstallationToken, githubGet } from "../github/githubApp.js";
import {
  isInstallationTokenValid,
  numberFromInt64Value,
  stringFromUnknown,
} from "./retryBuildJob/retryBuildJobHelpers.js";
import {
  type BuildJob,
  createGeminiMessage,
  failureSummaryModel,
  normalizeGitHubApiBaseUrl,
} from "./services.js";

interface ExtendedBuildJob extends BuildJob {
  installationId?: string | number | null;
  tokenExpiresAt?: string | null;
  ipaUrl?: string | null;
  failureSummaryStatus?: string | null;
}

export const generateChangelogOnBuildJobSuccess = onDocumentUpdated(
  {
    document: "build_jobs_v0/{buildJobId}",
    timeoutSeconds: 120,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data() as ExtendedBuildJob | undefined;
    if (!after) return;

    // We only trigger when status is SUCCESS and we have an ipaUrl.
    if (after.status !== BuildJobStatus.SUCCESS || !after.ipaUrl) {
      return;
    }

    // Only run if we transitioned to SUCCESS or just got the ipaUrl
    const wasSuccess = before?.status === BuildJobStatus.SUCCESS;
    const hadIpaUrl = !!before?.ipaUrl;
    if (wasSuccess && hadIpaUrl) {
      return;
    }

    // Avoid duplicate execution if already generating or done
    if (after.failureSummaryStatus === "generating" || after.failureSummaryStatus === "done") {
      return;
    }

    // Check if AI is enabled for the team
    if (after.teamId) {
      try {
        const team = await getTeamById({ teamId: after.teamId });
        if (team.data.team?.aiEnabled === false) {
          logger.info(`AI is disabled for team ${after.teamId}. Skipping changelog generation.`);
          return;
        }
      } catch (error) {
        logger.error(`Failed to verify AI status for team ${after.teamId}:`, error);
      }
    }

    const buildJobId = event.params.buildJobId;
    const start = Date.now();

    // Mark as generating
    await updateBuildJobFailureSummary({
      id: buildJobId,
      failureSummaryStatus: "generating",
      failureSummary: null,
      failureSummaryModel: null,
      failureSummaryDurationMs: null,
    });

    try {
      const owner = after.owner;
      const repo = after.repo;
      const commitSha = after.commitSha;
      if (!owner || !repo || !commitSha) {
        throw new Error("Missing owner, repo, or commitSha in build job");
      }

      // 1. Get GitHub token
      const apiBaseUrl = normalizeGitHubApiBaseUrl(after.githubApiBaseUrl);
      const installationId = numberFromInt64Value(after.installationId);
      let token = stringFromUnknown(after.installationToken);
      const tokenExpiresAt = stringFromUnknown(after.tokenExpiresAt);

      if (installationId !== undefined && (!token || !isInstallationTokenValid(tokenExpiresAt))) {
        logger.info(`Refreshing installation token for job ${buildJobId}`);
        const tokenData = await getInstallationToken(installationId, { apiBaseUrl });
        token = tokenData.token;
      }

      if (!token) {
        throw new Error("Failed to get installation token");
      }

      // 2. Fetch commits
      let commitMessages: string[] = [];

      // Case A: Pull Request
      if (after.pullRequestNumber) {
        logger.info(`Fetching commits for PR #${after.pullRequestNumber}`);
        try {
          const prCommits = await githubGet<Array<{ commit: { message: string } }>>(
            `/repos/${owner}/${repo}/pulls/${after.pullRequestNumber}/commits`,
            token,
            { apiBaseUrl },
          );
          commitMessages = prCommits.map((c) => c.commit.message);
        } catch (e) {
          logger.warn(`Failed to fetch PR commits, falling back: ${e}`);
        }
      }

      // Case B: Branch / Compare (if no PR or PR fetch failed)
      if (commitMessages.length === 0) {
        const db = getFirestore();
        const prevJobsSnap = await db
          .collection("build_jobs_v0")
          .where("teamId", "==", after.teamId)
          .where("owner", "==", owner)
          .where("repo", "==", repo)
          .where("branch", "==", after.branch)
          .where("status", "==", BuildJobStatus.SUCCESS)
          .orderBy("createdAt", "desc")
          .limit(10)
          .get();

        let previousSha: string | undefined;
        for (const doc of prevJobsSnap.docs) {
          if (doc.id === buildJobId) continue;
          const data = doc.data();
          if (data.commitSha && data.commitSha !== commitSha) {
            previousSha = data.commitSha;
            break;
          }
        }

        if (previousSha) {
          logger.info(`Comparing commits: ${previousSha}...${commitSha}`);
          try {
            const comparison = await githubGet<{ commits: Array<{ commit: { message: string } }> }>(
              `/repos/${owner}/${repo}/compare/${previousSha}...${commitSha}`,
              token,
              { apiBaseUrl },
            );
            commitMessages = comparison.commits.map((c) => c.commit.message);
          } catch (e) {
            logger.warn(`Failed to compare commits, falling back: ${e}`);
          }
        }
      }

      // Case C: Single Commit (if no previous builds or comparison failed)
      if (commitMessages.length === 0) {
        logger.info(`Fetching single commit: ${commitSha}`);
        const commitData = await githubGet<{ commit: { message: string } }>(
          `/repos/${owner}/${repo}/commits/${commitSha}`,
          token,
          { apiBaseUrl },
        );
        commitMessages = [commitData.commit.message];
      }

      if (commitMessages.length === 0) {
        throw new Error("No commit messages found");
      }

      // 3. Generate AI summary
      const commitListText = commitMessages
        .map((msg) => msg.trim())
        .filter(Boolean)
        .join("\n\n");

      const prompt = `あなたはCI/CDおよびソフトウェアリリースの専門家です。以下のコミットメッセージ一覧を分析し、今回のビルド（アプリ配信）に含まれる変更内容をユーザー向けに分かりやすく日本語で要約してください。

制約事項:
- 変更内容を分かりやすく、箇条書き（先頭に「・」を使用）で3項目程度にまとめてください。
- 開発者向けの細かいリファクタリングやCI設定のみの場合は、一般ユーザー向けに「内部構造の改善」や「ビルド設定の調整」のようにわかりやすくまとめてください。
- 余計な挨拶や説明は一切含めず、箇条書きのテキストのみを出力してください。
- 出力は必ず日本語にしてください。

コミットメッセージ一覧:
${commitListText}`;

      const projectId = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
      const summary = await createGeminiMessage(projectId, prompt);

      // 4. Save to Firestore
      await updateBuildJobFailureSummary({
        id: buildJobId,
        failureSummaryStatus: "done",
        failureSummary: summary || "・変更内容はありません",
        failureSummaryModel,
        failureSummaryDurationMs: Date.now() - start,
      });

      logger.info(`Successfully generated changelog for build job ${buildJobId}`);
    } catch (error) {
      logger.error(`Failed to generate changelog for build job ${buildJobId}`, error);
      await updateBuildJobFailureSummary({
        id: buildJobId,
        failureSummaryStatus: "error",
        failureSummary: "・変更内容の取得に失敗しました",
        failureSummaryModel: null,
        failureSummaryDurationMs: null,
      });
    }
  },
);
