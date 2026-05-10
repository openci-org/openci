import { describe, expect, it } from "vitest";
import { parseWorkflowYaml } from "./parseWorkflowYaml.js";

describe("parseWorkflowYaml", () => {
  it("parses workflow yaml into an object", () => {
    const result = parseWorkflowYaml({
      name: "ci.yaml",
      content: `
name: CI
on:
  push:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test
`,
    });

    expect(result).toEqual({
      workflowFileName: "ci.yaml",
      workflowName: "CI",
      parsed: {
        name: "CI",
        on: {
          push: null,
        },
        jobs: {
          test: {
            "runs-on": "ubuntu-latest",
            steps: [{ run: "npm test" }],
          },
        },
      },
    });
  });

  it("throws with the file name when yaml is invalid", () => {
    expect(() => parseWorkflowYaml({ name: "broken.yaml", content: "name: [" })).toThrow(
      "Failed to parse broken.yaml",
    );
  });

  it("throws when yaml does not parse to an object", () => {
    expect(() => parseWorkflowYaml({ name: "array.yaml", content: "- npm test" })).toThrow(
      "Workflow YAML must be an object",
    );
  });
});
