import { env, introspectWorkflowInstance } from "cloudflare:test";
import { expect, it } from "vitest";

it("should disable all sleeps, mock an event and complete", async () => {
	const instanceId = "123456";
	const instance = await introspectWorkflowInstance(
		env.REGISTER_RUNNER,
		instanceId,
	);

	await instance.modify(async (m) => {
		await m.disableSleeps();
		await m.mockEvent({
			payload: { approved: true, approverId: "user-123" },
			type: "user-approval",
		});
	});

	await env.REGISTER_RUNNER.create({
		id: instanceId,
	});
	await expect(instance.waitForStatus("complete")).resolves.not.toThrow();

	await instance.dispose();
});
