import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { extractJobs, filterValidWorkflows, type WorkflowWithJobs } from "./extractJobs.js";
import type { ParsedWorkflowFile } from "./parseWorkflowYaml.js";

beforeEach(() => {
  vi.spyOn(console, "warn").mockImplementation(() => undefined);
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("filterValidWorkflows", () => {
  it("returns empty array when jobs key is missing", () => {
    const workflows: ParsedWorkflowFile[] = [{ name: "x.yaml", parsed: { name: "X" } }];
    expect(filterValidWorkflows(workflows)).toEqual([]);
  });

  it("skips workflow when jobs is not an object", () => {
    const workflows: ParsedWorkflowFile[] = [
      { name: "arr.yaml", parsed: { jobs: ["test"] } },
      { name: "null.yaml", parsed: { jobs: null } },
      { name: "ok.yaml", parsed: { jobs: { build: { "runs-on": "ubuntu-latest" } } } },
    ];

    const result = filterValidWorkflows(workflows);
    expect(result).toHaveLength(1);
    expect(result[0].name).toBe("ok.yaml");
  });

  it("keeps workflow when jobs is a plain object", () => {
    const workflows: ParsedWorkflowFile[] = [
      { name: "ok.yaml", parsed: { jobs: { build: { "runs-on": "ubuntu-latest" } } } },
    ];

    expect(filterValidWorkflows(workflows)).toEqual([
      { name: "ok.yaml", jobs: { build: { "runs-on": "ubuntu-latest" } } },
    ]);
  });

  it("logs when workflow jobs are invalid", () => {
    const workflows: ParsedWorkflowFile[] = [{ name: "ci.yaml", parsed: { jobs: [] } }];

    expect(filterValidWorkflows(workflows)).toEqual([]);
    expect(console.warn).toHaveBeenCalledWith(
      "extractJobs: skipping ci.yaml (no valid jobs object)",
    );
  });
});

describe("extractJobs", () => {
  it("extracts a single job from a single workflow", () => {
    const workflows: WorkflowWithJobs[] = [
      {
        name: "ci.yaml",
        jobs: {
          test: { "runs-on": "ubuntu-latest", steps: [{ run: "npm test" }] },
        },
      },
    ];

    expect(extractJobs(workflows)).toEqual([
      {
        workflowName: "ci.yaml",
        jobId: "test",
        spec: { "runs-on": "ubuntu-latest", steps: [{ run: "npm test" }] },
      },
    ]);
  });

  it("flatMaps multiple workflows and multiple jobs", () => {
    const workflows: WorkflowWithJobs[] = [
      {
        name: "a.yaml",
        jobs: {
          build: { "runs-on": "ubuntu-latest" },
          test: { "runs-on": "ubuntu-latest" },
        },
      },
      {
        name: "b.yaml",
        jobs: {
          deploy: { "runs-on": "ubuntu-latest" },
        },
      },
    ];

    const result = extractJobs(workflows);
    expect(result).toHaveLength(3);
    expect(result.map((j) => `${j.workflowName}:${j.jobId}`)).toEqual([
      "a.yaml:build",
      "a.yaml:test",
      "b.yaml:deploy",
    ]);
  });

  it("skips individual job whose value is not an object", () => {
    const workflows: WorkflowWithJobs[] = [
      {
        name: "mixed.yaml",
        jobs: {
          ok: { "runs-on": "ubuntu-latest" },
          broken: "not an object",
        },
      },
    ];

    const result = extractJobs(workflows);
    expect(result).toHaveLength(1);
    expect(result[0].jobId).toBe("ok");
    expect(console.warn).toHaveBeenCalledWith(
      'extractJobs: skipping job "broken" in mixed.yaml (not an object)',
    );
  });

  it("skips individual jobs whose values are null or arrays", () => {
    const workflows: WorkflowWithJobs[] = [
      {
        name: "mixed.yaml",
        jobs: {
          ok: { "runs-on": "ubuntu-latest" },
          nullJob: null,
          arrayJob: [{ run: "npm test" }],
        },
      },
    ];

    expect(extractJobs(workflows)).toEqual([
      {
        workflowName: "mixed.yaml",
        jobId: "ok",
        spec: { "runs-on": "ubuntu-latest" },
      },
    ]);
  });

  it("logs when no jobs are extracted from a workflow", () => {
    expect(extractJobs([{ name: "ci.yaml", jobs: { build: "npm test" } }])).toEqual([]);
    expect(console.warn).toHaveBeenCalledWith(
      'extractJobs: skipping job "build" in ci.yaml (not an object)',
    );
    expect(console.warn).toHaveBeenCalledWith("extractJobs: no jobs extracted from ci.yaml");
  });
});
