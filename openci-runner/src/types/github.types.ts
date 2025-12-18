import z from "zod";

export const WorkflowJobPayloadSchema = z.object({
	installation: z
		.object({
			id: z.number(),
		})
		.optional(),
	repository: z.object({
		name: z.string(),
		owner: z.object({
			login: z.string(),
		}),
	}),
	workflow_job: z
		.object({
			completed_at: z.string().optional(),
			conclusion: z.string().nullable().optional(),
			name: z.string().optional(),
			run_id: z.number(),
			started_at: z.string().optional(),
		})
		.optional(),
});

export type WorkflowJobPayload = z.infer<typeof WorkflowJobPayloadSchema>;
