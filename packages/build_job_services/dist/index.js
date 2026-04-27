"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultGitHubApiBaseUrl = void 0;
exports.configureDataConnect = configureDataConnect;
exports.normalizeGitHubApiBaseUrl = normalizeGitHubApiBaseUrl;
exports.buildDashboardRunUrl = buildDashboardRunUrl;
exports.getBuildJobOrThrow = getBuildJobOrThrow;
exports.updateCheckRun = updateCheckRun;
exports.updateCheckRunById = updateCheckRunById;
exports.handleBuildJobStatusChange = handleBuildJobStatusChange;
exports.handleBuildJobStatusChangeById = handleBuildJobStatusChangeById;
exports.generateFailureSummary = generateFailureSummary;
exports.generateFailureSummaryById = generateFailureSummaryById;
const secret_manager_1 = require("@google-cloud/secret-manager");
const dataconnect_admin_1 = require("@openci/dataconnect-admin");
const messaging_1 = require("firebase-admin/messaging");
exports.defaultGitHubApiBaseUrl = "https://api.github.com";
const dashboardBaseUrl = "https://dashboard.openci.org";
const failureSummaryModel = "claude-opus-4-7";
function configureDataConnect(options) {
    if (options.serviceId)
        dataconnect_admin_1.connectorConfig.serviceId = options.serviceId;
    if (options.location)
        dataconnect_admin_1.connectorConfig.location = options.location;
}
function asBuildJob(value) {
    if (!value || typeof value !== "object")
        return undefined;
    return value;
}
function nonEmptyString(value) {
    return typeof value === "string" && value.length > 0 ? value : undefined;
}
function resolveProjectId(override) {
    const projectId = override ?? process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
    if (!projectId || projectId.trim().length === 0) {
        throw new Error("GCLOUD_PROJECT environment variable is not set.");
    }
    return projectId;
}
function normalizeGitHubApiBaseUrl(apiBaseUrl) {
    if (!apiBaseUrl)
        return exports.defaultGitHubApiBaseUrl;
    const normalized = apiBaseUrl.replace(/\/+$/u, "");
    if (normalized === `${exports.defaultGitHubApiBaseUrl}/graphql`)
        return exports.defaultGitHubApiBaseUrl;
    if (normalized.endsWith("/api/graphql"))
        return `${new URL(normalized).origin}/api/v3`;
    if (normalized.endsWith("/graphql"))
        return normalized.slice(0, -"/graphql".length);
    return normalized;
}
function buildDashboardRunUrl(buildJobId) {
    return `${dashboardBaseUrl}/runs/${encodeURIComponent(buildJobId)}`;
}
function formatDuration(createdAt, completedAt) {
    if (!createdAt || !completedAt)
        return "";
    const durationMs = new Date(completedAt).getTime() - new Date(createdAt).getTime();
    if (!Number.isFinite(durationMs) || durationMs <= 0)
        return "";
    const totalSeconds = Math.floor(durationMs / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return minutes > 0 ? `${minutes}m ${seconds}s` : `${seconds}s`;
}
async function getBuildJobOrThrow(buildJobId) {
    const result = await (0, dataconnect_admin_1.getBuildJob)({ id: buildJobId });
    const buildJob = asBuildJob(result.data.buildJob);
    if (!buildJob)
        throw new Error("Build job not found");
    return buildJob;
}
async function updateCheckRun(buildJob, runStatus, conclusion) {
    if (buildJob.checkRunId === null || buildJob.checkRunId === undefined)
        return;
    if (!buildJob.installationToken)
        return;
    const response = await fetch(`${normalizeGitHubApiBaseUrl(buildJob.githubApiBaseUrl)}/repos/${buildJob.owner}/${buildJob.repo}/check-runs/${String(buildJob.checkRunId)}`, {
        method: "PATCH",
        headers: {
            Authorization: `Bearer ${buildJob.installationToken}`,
            Accept: "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            status: runStatus,
            ...(runStatus === "completed" && conclusion ? { conclusion } : {}),
            details_url: buildDashboardRunUrl(buildJob.id),
        }),
    });
    if (!response.ok) {
        throw new Error(`Failed to update GitHub check run: ${response.status} ${await response.text()}`);
    }
}
async function updateCheckRunById(buildJobId, runStatus, conclusion) {
    await updateCheckRun(await getBuildJobOrThrow(buildJobId), runStatus, conclusion);
}
async function resolveDependencies(completedJob, completedStatus) {
    if (!completedJob.workflowRunId || !completedJob.jobKey)
        return;
    const waitingJobs = await (0, dataconnect_admin_1.listWaitingBuildJobs)({ workflowRunId: completedJob.workflowRunId });
    const isSuccess = completedStatus === "success";
    for (const job of waitingJobs.data.buildJobs) {
        const needs = Array.isArray(job.needs) ? job.needs.filter((need) => typeof need === "string") : [];
        if (!needs.includes(completedJob.jobKey))
            continue;
        if (!isSuccess) {
            await (0, dataconnect_admin_1.updateBuildJobStatus)({ id: job.id, status: "skipped" });
            await resolveDependencies(job, "skipped");
            continue;
        }
        const resolvedNeeds = typeof job.resolvedNeeds === "object" && job.resolvedNeeds !== null
            ? job.resolvedNeeds
            : undefined;
        if (!resolvedNeeds)
            continue;
        let allSatisfied = true;
        for (const needBuildJobId of Object.values(resolvedNeeds)) {
            const need = await (0, dataconnect_admin_1.getBuildJob)({ id: needBuildJobId });
            if (!need.data.buildJob || need.data.buildJob.status !== "success") {
                allSatisfied = false;
                break;
            }
        }
        if (allSatisfied) {
            await (0, dataconnect_admin_1.updateBuildJobStatus)({ id: job.id, status: "queued" });
        }
    }
}
async function failureLogLine(buildJobId, latestRunId) {
    if (!latestRunId)
        return "Unknown error";
    const logs = await (0, dataconnect_admin_1.listLatestBuildLogs)({ buildJobId, runId: latestRunId, limit: 2 });
    return logs.data.buildLogs[1]?.message ?? "Unknown error";
}
async function sendBuildNotifications(buildJob, status) {
    if (!buildJob.teamId)
        return;
    const users = await (0, dataconnect_admin_1.listTeamNotificationUsers)({ teamId: buildJob.teamId });
    if (users.data.teamMembers.length === 0)
        return;
    const isSuccess = status === "success";
    const title = isSuccess ? "✅ Build Succeeded" : "❌ Build Failed";
    const duration = formatDuration(buildJob.createdAt, buildJob.completedAt);
    const bodyLines = [
        ...(buildJob.workflowName ? [buildJob.workflowName] : []),
        `${buildJob.repo}${buildJob.branch ? ` (${buildJob.branch})` : ""}`,
        ...(duration ? [`⏱ ${duration}`] : []),
        ...(!isSuccess ? [await failureLogLine(buildJob.id, buildJob.latestRunId)] : []),
    ];
    const invalidTokens = new Set();
    for (const member of users.data.teamMembers) {
        const preference = member.user.notificationPreference ?? "all";
        if (preference === "none" || (preference === "successOnly" && !isSuccess) || (preference === "failureOnly" && isSuccess)) {
            continue;
        }
        for (const token of member.user.fcmTokens ?? []) {
            try {
                await (0, messaging_1.getMessaging)().send({
                    token,
                    notification: { title, body: bodyLines.join("\n") },
                    data: {
                        buildJobId: buildJob.id,
                        status,
                        owner: buildJob.owner,
                        repo: buildJob.repo,
                        ...(buildJob.branch ? { branch: buildJob.branch } : {}),
                        ...(buildJob.workflowName ? { workflowName: buildJob.workflowName } : {}),
                        ...(duration ? { duration } : {}),
                    },
                    apns: { payload: { aps: { sound: "default", badge: 1 } } },
                });
            }
            catch (error) {
                const message = String(error);
                if (message.includes("registration-token-not-registered") || message.includes("invalid-argument")) {
                    invalidTokens.add(token);
                }
            }
        }
    }
    if (invalidTokens.size > 0) {
        for (const member of users.data.teamMembers) {
            const validTokens = (member.user.fcmTokens ?? []).filter((token) => !invalidTokens.has(token));
            if (validTokens.length !== (member.user.fcmTokens ?? []).length) {
                await (0, dataconnect_admin_1.updateUserFcmTokens)({ id: member.user.id, fcmTokens: validTokens });
            }
        }
    }
}
async function handleBuildJobStatusChange(buildJob, status) {
    if (["success", "failure", "cancelled", "timed_out", "skipped"].includes(status)) {
        await resolveDependencies(buildJob, status);
    }
    if (status === "success" || status === "failure") {
        await sendBuildNotifications(buildJob, status);
    }
}
async function handleBuildJobStatusChangeById(buildJobId, status) {
    await handleBuildJobStatusChange(await getBuildJobOrThrow(buildJobId), status);
}
async function accessProjectSecret(projectIdOverride, name) {
    const projectId = resolveProjectId(projectIdOverride);
    const client = new secret_manager_1.SecretManagerServiceClient();
    const [version] = await client.accessSecretVersion({
        name: `projects/${projectId}/secrets/${name}/versions/latest`,
    });
    const data = version.payload?.data;
    if (!data)
        throw new Error(`Secret ${name} has no payload`);
    return Buffer.from(data).toString("utf8");
}
async function createAnthropicMessage(projectId, logLines) {
    const apiKey = await accessProjectSecret(projectId, "ANTHROPIC_API_KEY");
    const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            model: failureSummaryModel,
            max_tokens: 1024,
            messages: [
                {
                    role: "user",
                    content: `あなたはCI/CDの専門家です。以下のビルドログを分析し、ビルドが失敗した原因を簡潔に要約してください。根本原因に焦点を当て、修正方法を提案してください。3文以内で日本語で回答してください。\n\n${logLines}`,
                },
            ],
        }),
    });
    const data = (await response.json());
    if (!response.ok) {
        throw new Error(data.error?.message ?? `Anthropic API error: ${response.status}`);
    }
    return (data.content ?? [])
        .filter((block) => block.type === "text" && typeof block.text === "string")
        .map((block) => block.text)
        .join("");
}
async function generateFailureSummary(buildJob, projectId) {
    if (buildJob.status !== "failure")
        return;
    if (buildJob.teamId) {
        const team = await (0, dataconnect_admin_1.getTeamById)({ teamId: buildJob.teamId });
        if (team.data.team?.aiEnabled === false)
            return;
    }
    const latestRunId = nonEmptyString(buildJob.latestRunId);
    if (!latestRunId)
        return;
    const start = Date.now();
    await (0, dataconnect_admin_1.updateBuildJobFailureSummary)({
        id: buildJob.id,
        failureSummaryStatus: "generating",
        failureSummary: null,
        failureSummaryModel: null,
        failureSummaryDurationMs: null,
    });
    try {
        const logs = await (0, dataconnect_admin_1.listLatestBuildLogs)({ buildJobId: buildJob.id, runId: latestRunId, limit: 50 });
        if (logs.data.buildLogs.length === 0) {
            await (0, dataconnect_admin_1.updateBuildJobFailureSummary)({
                id: buildJob.id,
                failureSummaryStatus: "error",
                failureSummary: "No logs found",
                failureSummaryModel: null,
                failureSummaryDurationMs: null,
            });
            return;
        }
        const logLines = logs.data.buildLogs
            .slice()
            .reverse()
            .map((log) => log.message)
            .join("\n");
        const summary = await createAnthropicMessage(projectId, logLines);
        await (0, dataconnect_admin_1.updateBuildJobFailureSummary)({
            id: buildJob.id,
            failureSummaryStatus: "done",
            failureSummary: summary || "No summary generated",
            failureSummaryModel,
            failureSummaryDurationMs: Date.now() - start,
        });
    }
    catch (error) {
        await (0, dataconnect_admin_1.updateBuildJobFailureSummary)({
            id: buildJob.id,
            failureSummaryStatus: "error",
            failureSummary: String(error),
            failureSummaryModel: null,
            failureSummaryDurationMs: null,
        });
    }
}
async function generateFailureSummaryById(buildJobId, projectId) {
    await generateFailureSummary(await getBuildJobOrThrow(buildJobId), projectId);
}
//# sourceMappingURL=index.js.map