import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

import { db } from "./firebase";
import {
	buildJobsCollectionPath,
	logsSubcollectionPath,
	runsSubcollectionPath,
} from "./firestore-collection-paths";

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

const SYSTEM_PROMPT = `You are a CI/CD build log analyzer. Your job is to analyze build failure logs and produce a concise, actionable summary.

Rules:
1. Identify the ROOT CAUSE of the failure (e.g., compilation error, test failure, dependency issue, timeout).
2. Extract the SPECIFIC error messages and file locations.
3. Suggest a likely FIX if the cause is clear.
4. Keep the summary under 200 words.
5. Use markdown formatting for readability (bold for key terms, code blocks for file paths/commands).
6. Always respond in Japanese (日本語).
7. Do NOT include generic advice. Be specific to the actual error.

Output format:
**原因**: (一行の要約)

**詳細**: (具体的なエラー情報を2〜3文で)

**修正案**: (具体的な修正方法)`;

const MODEL = "gemini-2.5-flash-lite";

/**
 * Generates a failure summary for a build job using Gemini API.
 * Writes a "generating" status immediately so the UI can show a loading state,
 * then updates with the actual summary when complete.
 */
export async function generateFailureSummary(
	buildJobId: string,
	latestRunId: string,
): Promise<void> {
	const jobRef = db.collection(buildJobsCollectionPath).doc(buildJobId);

	try {
		// Immediately mark as generating so the UI can show a loading state
		await jobRef.update({
			failureSummaryStatus: "generating",
		});

		// Fetch all logs for the latest run
		const logsSnapshot = await jobRef
			.collection(runsSubcollectionPath)
			.doc(latestRunId)
			.collection(logsSubcollectionPath)
			.orderBy("timestamp", "asc")
			.get();

		if (logsSnapshot.empty) {
			logger.warn(`No logs found for build job ${buildJobId}, run ${latestRunId}`);
			await jobRef.update({ failureSummaryStatus: "no_logs" });
			return;
		}

		const logLines = logsSnapshot.docs.map((doc) => {
			const data = doc.data();
			const level = data.level as string;
			const message = data.message as string;
			return `[${level}] ${message}`;
		});

		// Truncate if logs are too long (keep last 500 lines for context)
		const maxLines = 500;
		const truncatedLogs =
			logLines.length > maxLines
				? [
						`... (${logLines.length - maxLines} earlier lines omitted)`,
						...logLines.slice(-maxLines),
					]
				: logLines;

		const logContent = truncatedLogs.join("\n");

		const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });

		const start = Date.now();
		const response = await ai.models.generateContent({
			model: MODEL,
			contents: [
				{
					role: "user",
					parts: [
						{
							text: `Analyze the following CI/CD build failure logs and provide a concise summary:\n\n${logContent}`,
						},
					],
				},
			],
			config: {
				systemInstruction: SYSTEM_PROMPT,
				maxOutputTokens: 512,
				temperature: 0.2,
			},
		});
		const durationMs = Date.now() - start;

		const summary = response.text?.trim();
		if (!summary) {
			logger.warn("Gemini returned empty response for failure summary");
			await jobRef.update({ failureSummaryStatus: "error" });
			return;
		}

		// Save result to Firestore
		await jobRef.update({
			failureSummary: summary,
			failureSummaryModel: MODEL,
			failureSummaryStatus: "done",
			failureSummaryDurationMs: durationMs,
		});

		logger.info(
			`Generated failure summary for build job ${buildJobId} using ${MODEL} in ${durationMs}ms`,
		);
	} catch (error) {
		logger.error("Failed to generate failure summary:", {
			error: String(error),
			stack: (error as Error)?.stack,
			buildJobId,
		});
		await jobRef.update({ failureSummaryStatus: "error" }).catch(() => {});
	}
}

/**
 * Returns the list of Gemini secrets needed for Cloud Functions that use this module.
 */
export function getGeminiSecrets() {
	return [GEMINI_API_KEY];
}
