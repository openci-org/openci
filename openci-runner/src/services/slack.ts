import z from "zod";
import type { WorkflowJobPayload } from "../types/github.types";

interface SlackMessage {
	text: string;
}

const StatusInfoSchema = z.object({
	emoji: z.string(),
	status: z.string(),
});

const ConclusionStatusMap = {
	cancelled: { emoji: "🚫", status: "キャンセル" },
	failure: { emoji: "❌", status: "失敗" },
	skipped: { emoji: "⏭️", status: "スキップ" },
	success: { emoji: "✅", status: "成功" },
} as const satisfies Record<string, z.infer<typeof StatusInfoSchema>>;

type Conclusion = keyof typeof ConclusionStatusMap;

const DEFAULT_STATUS_INFO: z.infer<typeof StatusInfoSchema> = {
	emoji: "❓",
	status: "不明",
};

export async function notifyJobStarted(
	webhookUrl: string,
	payload: WorkflowJobPayload,
): Promise<void> {
	await sendSlackMessage(webhookUrl, {
		text: `🚀 ジョブ開始: ${JSON.stringify(payload)}`,
	});
}

export async function notifyJobCompleted(
	webhookUrl: string,
	payload: WorkflowJobPayload,
): Promise<void> {
	const job = payload.workflow_job;
	const jobName = job?.name ?? "Unknown";
	const conclusion = job?.conclusion ?? "unknown";
	const { status, emoji } = getStatusInfo(conclusion);
	const duration = calculateDuration(job?.started_at, job?.completed_at);

	await sendSlackMessage(webhookUrl, {
		text: `${emoji} ジョブ完了: ${jobName} | ${status} | ${duration}`,
	});
}

export async function notifyJobCancelled(
	webhookUrl: string,
	payload: WorkflowJobPayload,
): Promise<void> {
	const jobName = payload.workflow_job?.name ?? "Unknown";

	await sendSlackMessage(webhookUrl, {
		text: `🚫 ジョブキャンセル: ${jobName}`,
	});
}

function isConclusion(value: string): value is Conclusion {
	return value in ConclusionStatusMap;
}

function getStatusInfo(conclusion: string): z.infer<typeof StatusInfoSchema> {
	if (isConclusion(conclusion)) {
		return ConclusionStatusMap[conclusion];
	}
	return DEFAULT_STATUS_INFO;
}

function calculateDuration(startedAt?: string, completedAt?: string): string {
	if (!startedAt || !completedAt) {
		return "N/A";
	}

	const start = new Date(startedAt).getTime();
	const end = new Date(completedAt).getTime();
	const durationMs = end - start;

	const seconds = Math.floor(durationMs / 1000);
	const minutes = Math.floor(seconds / 60);
	const remainingSeconds = seconds % 60;

	if (minutes > 0) {
		return `${minutes}m ${remainingSeconds}s`;
	}
	return `${seconds}s`;
}

async function sendSlackMessage(
	webhookUrl: string,
	message: SlackMessage,
): Promise<void> {
	const response = await fetch(webhookUrl, {
		body: JSON.stringify(message),
		headers: {
			"Content-Type": "application/json",
		},
		method: "POST",
	});

	if (!response.ok) {
		throw new Error(`Failed to send Slack message: ${response.status}`);
	}
}
