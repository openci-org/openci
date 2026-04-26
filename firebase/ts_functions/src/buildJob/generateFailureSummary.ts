import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { createAnthropicMessage } from "../ai/anthropic";
import {
  getBuildJob,
  getTeamById,
  listLatestBuildLogs,
  updateBuildJobFailureSummary,
} from "@openci/dataconnect-admin";

interface GenerateFailureSummaryRequest {
  buildJobId: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

async function generateSummary(buildJobId: string, latestRunId: string): Promise<void> {
  const start = Date.now();
  await updateBuildJobFailureSummary({
    id: buildJobId,
    failureSummaryStatus: "generating",
    failureSummary: null,
    failureSummaryModel: null,
    failureSummaryDurationMs: null,
  });

  try {
    const logsResult = await listLatestBuildLogs({ buildJobId, runId: latestRunId, limit: 50 });

    if (logsResult.data.buildLogs.length === 0) {
      await updateBuildJobFailureSummary({
        id: buildJobId,
        failureSummaryStatus: "error",
        failureSummary: "No logs found",
        failureSummaryModel: null,
        failureSummaryDurationMs: null,
      });
      return;
    }

    const logLines = logsResult.data.buildLogs
      .slice()
      .reverse()
      .map((log) => log.message)
      .join("\n");
    const model = "claude-opus-4-7";
    const text = await createAnthropicMessage({
      model,
      maxTokens: 1024,
      messages: [
        {
          role: "user",
          content: `あなたはCI/CDの専門家です。以下のビルドログを分析し、ビルドが失敗した原因を簡潔に要約してください。根本原因に焦点を当て、修正方法を提案してください。3文以内で日本語で回答してください。\n\n${logLines}`,
        },
      ],
    });

    await updateBuildJobFailureSummary({
      id: buildJobId,
      failureSummaryStatus: "done",
      failureSummary: text || "No summary generated",
      failureSummaryModel: model,
      failureSummaryDurationMs: Date.now() - start,
    });
    logger.info("Generated failure summary", { buildJobId, model });
  } catch (error) {
    logger.error("Failed to generate failure summary", { buildJobId, error });
    await updateBuildJobFailureSummary({
      id: buildJobId,
      failureSummaryStatus: "error",
      failureSummary: String(error),
      failureSummaryModel: null,
      failureSummaryDurationMs: null,
    });
  }
}

export const generateFailureSummary = onCall<
  GenerateFailureSummaryRequest,
  Promise<{ success: boolean; reason?: string }>
>(
  { timeoutSeconds: 120 },
  async (request) => {
    const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
    const buildJobResult = await getBuildJob({ id: buildJobId });
    const jobData = buildJobResult.data.buildJob;
    if (!jobData) {
      throw new HttpsError("not-found", "Build job not found");
    }

    if (jobData.status !== "failure") {
      return { success: false, reason: "Build job is not in failure status" };
    }

    if (typeof jobData.teamId === "string") {
      const teamResult = await getTeamById({ teamId: jobData.teamId });
      if (teamResult.data.team?.aiEnabled === false) {
        return { success: false, reason: "AI features disabled" };
      }
    }

    if (typeof jobData.latestRunId !== "string") {
      return { success: false, reason: "No run ID found" };
    }

    await generateSummary(buildJobId, jobData.latestRunId);
    return { success: true };
  },
);
