import { defineConfig } from "vite-plus";

export default defineConfig({
  lint: {
    ignorePatterns: ["lib/**", "src/generated/**", "node_modules/**"],
  },
  fmt: {
    ignorePatterns: ["lib/**", "src/generated/**", "node_modules/**"],
  },
});
