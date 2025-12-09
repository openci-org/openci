import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
	test: {
		coverage: {
			exclude: ["apps/**"],
			provider: "istanbul",
			reporter: ["text", "json-summary", "json"],
			reportOnFailure: true,
		},
		exclude: ["**/node_modules/**", "**/apps/**"],
		include: ["src/**/*.test.ts"],
		poolOptions: {
			workers: {
				wrangler: { configPath: "./wrangler.toml" },
			},
		},
	},
});
