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
    const workflows: ParsedWorkflowFile[] = [
      { workflowFileName: "x.yaml", workflowName: "X", parsed: { name: "X" } },
    ];
    expect(filterValidWorkflows(workflows)).toEqual([]);
  });

  it("skips workflow when jobs is not an object", () => {
    const workflows: ParsedWorkflowFile[] = [
      { workflowFileName: "arr.yaml", workflowName: "Array", parsed: { jobs: ["test"] } },
      { workflowFileName: "null.yaml", workflowName: "Null", parsed: { jobs: null } },
      {
        workflowFileName: "ok.yaml",
        workflowName: "OK",
        parsed: { jobs: { build: { "runs-on": "ubuntu-latest" } } },
      },
    ];

    const result = filterValidWorkflows(workflows);
    expect(result).toHaveLength(1);
    expect(result[0].workflowFileName).toBe("ok.yaml");
  });

  it("keeps workflow when jobs is a plain object", () => {
    const workflows: ParsedWorkflowFile[] = [
      {
        workflowFileName: "ok.yaml",
        workflowName: "OK",
        parsed: { jobs: { build: { "runs-on": "ubuntu-latest" } } },
      },
    ];

    expect(filterValidWorkflows(workflows)).toEqual([
      {
        workflowFileName: "ok.yaml",
        workflowName: "OK",
        jobs: { build: { "runs-on": "ubuntu-latest" } },
      },
    ]);
  });

  it("logs when workflow jobs are invalid", () => {
    const workflows: ParsedWorkflowFile[] = [
      { workflowFileName: "ci.yaml", workflowName: "CI", parsed: { jobs: [] } },
    ];

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
        workflowFileName: "ci.yaml",
        workflowName: "CI",
        jobs: {
          test: { "runs-on": "ubuntu-latest", steps: [{ run: "npm test" }] },
        },
      },
    ];

    expect(extractJobs(workflows)).toEqual([
      {
        workflowFileName: "ci.yaml",
        workflowName: "CI",
        jobId: "test",
        spec: { "runs-on": "ubuntu-latest", steps: [{ run: "npm test" }] },
      },
    ]);
  });

  it("flatMaps multiple workflows and multiple jobs", () => {
    const workflows: WorkflowWithJobs[] = [
      {
        workflowFileName: "a.yaml",
        workflowName: "A",
        jobs: {
          build: { "runs-on": "ubuntu-latest" },
          test: { "runs-on": "ubuntu-latest" },
        },
      },
      {
        workflowFileName: "b.yaml",
        workflowName: "B",
        jobs: {
          deploy: { "runs-on": "ubuntu-latest" },
        },
      },
    ];

    const result = extractJobs(workflows);
    expect(result).toHaveLength(3);
    expect(result.map((j) => `${j.workflowFileName}:${j.workflowName}:${j.jobId}`)).toEqual([
      "a.yaml:A:build",
      "a.yaml:A:test",
      "b.yaml:B:deploy",
    ]);
  });

  it("expands matrix jobs into OpenCI job instances", () => {
    const workflows: WorkflowWithJobs[] = [
      {
        workflowFileName: "ci.yaml",
        workflowName: "CI",
        jobs: {
          build: {
            "runs-on": "${{ matrix.os }}",
            strategy: {
              "fail-fast": false,
              matrix: {
                os: ["ubuntu-latest", "macos-latest"],
                node: [24],
              },
            },
          },
        },
      },
    ];

    expect(extractJobs(workflows)).toEqual([
      {
        workflowFileName: "ci.yaml",
        workflowName: "CI",
        jobId: "build[node=24,os=ubuntu-latest]",
        workflowJobKey: "build",
        spec: {
          "runs-on": "ubuntu-latest",
          strategy: {
            "fail-fast": false,
            matrix: {
              os: ["ubuntu-latest", "macos-latest"],
              node: [24],
            },
          },
        },
        matrix: { os: "ubuntu-latest", node: 24 },
        matrixLabel: "node=24,os=ubuntu-latest",
        matrixIndex: 0,
        matrixGroupKey: "ci.yaml:build",
        matrixFailFast: false,
      },
      {
        workflowFileName: "ci.yaml",
        workflowName: "CI",
        jobId: "build[node=24,os=macos-latest]",
        workflowJobKey: "build",
        spec: {
          "runs-on": "macos-latest",
          strategy: {
            "fail-fast": false,
            matrix: {
              os: ["ubuntu-latest", "macos-latest"],
              node: [24],
            },
          },
        },
        matrix: { os: "macos-latest", node: 24 },
        matrixLabel: "node=24,os=macos-latest",
        matrixIndex: 1,
        matrixGroupKey: "ci.yaml:build",
        matrixFailFast: false,
      },
    ]);
  });

  it("skips individual job whose value is not an object", () => {
    const workflows: WorkflowWithJobs[] = [
      {
        workflowFileName: "mixed.yaml",
        workflowName: "Mixed",
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
        workflowFileName: "mixed.yaml",
        workflowName: "Mixed",
        jobs: {
          ok: { "runs-on": "ubuntu-latest" },
          nullJob: null,
          arrayJob: [{ run: "npm test" }],
        },
      },
    ];

    expect(extractJobs(workflows)).toEqual([
      {
        workflowFileName: "mixed.yaml",
        workflowName: "Mixed",
        jobId: "ok",
        spec: { "runs-on": "ubuntu-latest" },
      },
    ]);
  });

  it("logs when no jobs are extracted from a workflow", () => {
    expect(
      extractJobs([
        { workflowFileName: "ci.yaml", workflowName: "CI", jobs: { build: "npm test" } },
      ]),
    ).toEqual([]);
    expect(console.warn).toHaveBeenCalledWith(
      'extractJobs: skipping job "build" in ci.yaml (not an object)',
    );
    expect(console.warn).toHaveBeenCalledWith("extractJobs: no jobs extracted from ci.yaml");
  });
});
