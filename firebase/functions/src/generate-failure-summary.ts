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
6. Always respond in the same language as the log content. If the logs are in English, respond in English. If mixed, default to English.
7. Do NOT include generic advice. Be specific to the actual error.

Output format:
**Root Cause**: (one-line summary)

**Details**: (2-3 sentences with specific error info)

**Suggested Fix**: (actionable suggestion)`;

// Models to compare (temporary, for evaluation)
const MODELS_TO_COMPARE = [
	"gemini-2.5-flash-lite",
	"gemini-2.5-flash",
	"gemini-2.5-pro",
	"gemini-3-flash-preview",
	"gemini-3.1-flash-lite-preview",
	"gemini-3.1-pro-preview",
];

/**
 * Fetches logs for a build job run.
 */
async function fetchLogs(buildJobId: string, latestRunId: string): Promise<string | null> {
	const logsSnapshot = await db
		.collection(buildJobsCollectionPath)
		.doc(buildJobId)
		.collection(runsSubcollectionPath)
		.doc(latestRunId)
		.collection(logsSubcollectionPath)
		.orderBy("timestamp", "asc")
		.get();

	if (logsSnapshot.empty) {
		logger.warn(`No logs found for build job ${buildJobId}, run ${latestRunId}`);
		return null;
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

	return truncatedLogs.join("\n");
}

/**
 * Calls a single Gemini model to generate a summary.
 */
async function callModel(
	ai: GoogleGenAI,
	model: string,
	logContent: string,
): Promise<{ model: string; summary: string | null; durationMs: number }> {
	const start = Date.now();
	try {
		const response = await ai.models.generateContent({
			model: model,
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

		const summary = response.text?.trim() || null;
		const durationMs = Date.now() - start;
		logger.info(`Model ${model} completed in ${durationMs}ms`);
		return { model, summary, durationMs };
	} catch (error) {
		const durationMs = Date.now() - start;
		logger.error(`Model ${model} failed after ${durationMs}ms:`, String(error));
		return { model, summary: null, durationMs };
	}
}

/**
 * Generates failure summaries using ALL comparison models in parallel.
 * Saves results as a map: failureSummaries: { "model-name": { summary, durationMs } }
 * Also picks the first successful result as the primary failureSummary.
 */
export async function generateFailureSummary(
	buildJobId: string,
	latestRunId: string,
): Promise<void> {
	try {
		const logContent = await fetchLogs(buildJobId, latestRunId);
		if (!logContent) return;

		const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });

		// Run all models in parallel
		const results = await Promise.all(
			MODELS_TO_COMPARE.map((model) => callModel(ai, model, logContent)),
		);

		// Build the comparison map
		const failureSummaries: Record<string, { summary: string | null; durationMs: number }> = {};
		let primarySummary: string | null = null;
		let primaryModel: string | null = null;

		for (const result of results) {
			failureSummaries[result.model] = {
				summary: result.summary,
				durationMs: result.durationMs,
			};
			// Use the first successful result as primary
			if (!primarySummary && result.summary) {
				primarySummary = result.summary;
				primaryModel = result.model;
			}
		}

		// Save all results to Firestore
		await db.collection(buildJobsCollectionPath).doc(buildJobId).update({
			failureSummary: primarySummary,
			failureSummaryModel: primaryModel,
			failureSummaries: failureSummaries,
		});

		logger.info(
			`Generated ${results.filter((r) => r.summary).length}/${MODELS_TO_COMPARE.length} failure summaries for build job ${buildJobId}`,
		);
	} catch (error) {
		logger.error("Failed to generate failure summaries:", {
			error: String(error),
			stack: (error as Error)?.stack,
			buildJobId,
		});
	}
}

/**
 * Returns the list of Gemini secrets needed for Cloud Functions that use this module.
 */
export function getGeminiSecrets() {
	return [GEMINI_API_KEY];
}
