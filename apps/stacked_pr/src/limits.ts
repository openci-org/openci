// A crashed worker's lease outlives both its execution and delivery deadlines.
export const executionBudgetMs = 420_000;
export const workerTimeoutSeconds = 540;
export const taskDeadlineSeconds = 600;
export const stackLeaseMs = 15 * 60_000;
export const workerParallelism = 4;
