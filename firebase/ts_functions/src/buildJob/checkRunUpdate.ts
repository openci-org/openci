import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { getBuildJob } from "@openci/dataconnect-admin";
import { buildDashboardRunUrl, defaultGitHubApiBaseUrl } from "../github/githubUrls";
import { githubPatch } from "../github/githubApp";

interface CheckRunUpdateRequest {
  buildJobId: string;
  runStatus: string;
  conclusion?: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

export const checkRunUpdate = onCall<
  CheckRunUpdateRequest,
  Promise<{ success?: boolean; skipped?: boolean; reason?: string; error?: string }>
>(async (request) => {
  const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
  const runStatus = requireNonEmptyString(request.data?.runStatus, "runStatus");
  const conclusion = request.data?.conclusion;

  const buildJobResult = await getBuildJob({ id: buildJobId });
  const jobData = buildJobResult.data.buildJob;
  if (!jobData) {
    throw new HttpsError("not-found", "Build job not found");
  }

  const checkRunId = jobData.checkRunId;
  if (checkRunId === null || checkRunId === undefined) {
    return { skipped: true, reason: "No checkRunId" };
  }

  let ghStatus: string;
  let ghConclusion: string | undefined;
  if (runStatus === "in_progress") {
    ghStatus = "in_progress";
  } else if (runStatus === "completed") {
    ghStatus = "completed";
    ghConclusion = typeof conclusion === "string" ? conclusion : undefined;
  } else {
    return { skipped: true, reason: `Unknown runStatus: ${runStatus}` };
  }

  try {
    await githubPatch(
      `/repos/${requireNonEmptyString(jobData.owner, "owner")}/${requireNonEmptyString(
        jobData.repo,
        "repo",
      )}/check-runs/${String(checkRunId)}`,
      requireNonEmptyString(jobData.installationToken, "installationToken"),
      {
        status: ghStatus,
        ...(ghConclusion ? { conclusion: ghConclusion } : {}),
        details_url: buildDashboardRunUrl(buildJobId),
      },
      {
        apiBaseUrl:
          typeof jobData.githubApiBaseUrl === "string" ? jobData.githubApiBaseUrl : defaultGitHubApiBaseUrl,
      },
    );
    logger.info("Updated check run", { checkRunId, ghStatus, ghConclusion });
    return { success: true };
  } catch (error) {
    logger.error("Failed to update check run", { checkRunId, error });
    return { success: false, error: String(error) };
  }
});
