import z from "zod";

export const IncusStatusSchema = z.enum([
	"Running",
	"Stopped",
	"Frozen",
	"Error",
]);
export type IncusStatus = z.infer<typeof IncusStatusSchema>;

export const IncusPropertySchema = z.object({
	name: z.string(),
	status: IncusStatusSchema,
});
export type IncusProperty = z.infer<typeof IncusPropertySchema>;

export const IncusInstancesResponseSchema = z.object({
	metadata: z.array(IncusPropertySchema),
});
export type IncusInstancesResponse = z.infer<
	typeof IncusInstancesResponseSchema
>;

export type IncusEnv = {
	cloudflare_access_client_id: string;
	cloudflare_access_client_secret: string;
	server_url: string;
};

export const IncusOperationStatusSchema = z.enum([
	"Pending",
	"Running",
	"Cancelling",
	"Cancelled",
	"Success",
	"Failure",
]);
export type IncusOperationStatus = z.infer<typeof IncusOperationStatusSchema>;

export const IncusOperationMetadataSchema = z.object({
	class: z.string().optional(),
	err: z.string().optional(),
	id: z.string().optional(),
	status: IncusOperationStatusSchema.optional(),
	status_code: z.number().optional(),
});
export type IncusOperationMetadata = z.infer<
	typeof IncusOperationMetadataSchema
>;

export const IncusAsyncResponseSchema = z.discriminatedUnion("type", [
	z.object({
		metadata: IncusOperationMetadataSchema.optional(),
		operation: z.string(),
		status: z.string(),
		status_code: z.number(),
		type: z.literal("async"),
	}),
	z.object({
		metadata: IncusOperationMetadataSchema.optional(),
		status: z.string(),
		status_code: z.number(),
		type: z.literal("sync"),
	}),
	z.object({
		error: z.string(),
		error_code: z.number(),
		metadata: IncusOperationMetadataSchema.optional(),
		status: z.string(),
		status_code: z.number(),
		type: z.literal("error"),
	}),
]);
export type IncusAsyncResponse = z.infer<typeof IncusAsyncResponseSchema>;

export const IncusInstanceStatusSchema = z.enum([
	"Running",
	"Stopped",
	"Frozen",
	"Error",
]);

export const IncusInstanceStateResponseSchema = z.object({
	metadata: z.object({
		processes: z.number(),
		status: IncusInstanceStatusSchema,
	}),
});

export type IncusInstanceStateResponse = z.infer<
	typeof IncusInstanceStateResponseSchema
>;
