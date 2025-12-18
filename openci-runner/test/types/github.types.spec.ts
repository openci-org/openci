import { describe, expect, it } from "vitest";
import { WorkflowJobPayloadSchema } from "../../src/types/github.types";

describe("WorkflowJobPayloadSchema", () => {
	it("parses valid payload with installation", () => {
		const payload = {
			installation: { id: 123 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
		};

		const result = WorkflowJobPayloadSchema.parse(payload);

		expect(result.installation?.id).toBe(123);
		expect(result.repository.name).toBe("test-repo");
		expect(result.repository.owner.login).toBe("test-owner");
	});

	it("parses valid payload without installation", () => {
		const payload = {
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
		};

		const result = WorkflowJobPayloadSchema.parse(payload);

		expect(result.installation).toBeUndefined();
		expect(result.repository.name).toBe("test-repo");
	});

	it("throws on invalid payload missing repository", () => {
		const payload = {
			installation: { id: 123 },
		};

		expect(() => WorkflowJobPayloadSchema.parse(payload)).toThrow();
	});

	it("throws on invalid payload missing owner", () => {
		const payload = {
			repository: {
				name: "test-repo",
			},
		};

		expect(() => WorkflowJobPayloadSchema.parse(payload)).toThrow();
	});
});
