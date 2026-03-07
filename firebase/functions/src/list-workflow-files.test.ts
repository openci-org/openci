import { describe, expect, it } from "vitest";

import {
  parseWorkflowFiles,
  WORKFLOW_FILES_QUERY,
  type WorkflowFilesQueryResult,
} from "./list-workflow-files";

describe("WORKFLOW_FILES_QUERY", () => {
  it("should contain repository and object fields", () => {
    expect(WORKFLOW_FILES_QUERY).toContain("repository");
    expect(WORKFLOW_FILES_QUERY).toContain("object(expression: $expression)");
    expect(WORKFLOW_FILES_QUERY).toContain("... on Tree");
    expect(WORKFLOW_FILES_QUERY).toContain("... on Blob");
    expect(WORKFLOW_FILES_QUERY).toContain("text");
  });
});

describe("parseWorkflowFiles", () => {
  it("should return empty array when object is null", () => {
    const result: WorkflowFilesQueryResult = {
      repository: { object: null },
    };
    expect(parseWorkflowFiles(result)).toEqual([]);
  });

  it("should filter yaml and yml files", () => {
    const result: WorkflowFilesQueryResult = {
      repository: {
        object: {
          entries: [
            { name: "build.yaml", type: "blob", object: { text: "steps:\n  - run: echo" } },
            { name: "deploy.yml", type: "blob", object: { text: "steps:\n  - deploy" } },
            { name: "README.md", type: "blob", object: { text: "# readme" } },
            { name: "config.json", type: "blob", object: { text: "{}" } },
          ],
        },
      },
    };

    const files = parseWorkflowFiles(result);
    expect(files).toHaveLength(2);
    expect(files[0]).toEqual({
      name: "build.yaml",
      path: ".openci/build.yaml",
      content: "steps:\n  - run: echo",
    });
    expect(files[1]).toEqual({
      name: "deploy.yml",
      path: ".openci/deploy.yml",
      content: "steps:\n  - deploy",
    });
  });

  it("should filter out tree entries", () => {
    const result: WorkflowFilesQueryResult = {
      repository: {
        object: {
          entries: [
            { name: "build.yaml", type: "blob", object: { text: "content" } },
            { name: "subdir", type: "tree", object: null },
          ],
        },
      },
    };

    const files = parseWorkflowFiles(result);
    expect(files).toHaveLength(1);
    expect(files[0].name).toBe("build.yaml");
  });

  it("should filter out entries with null object", () => {
    const result: WorkflowFilesQueryResult = {
      repository: {
        object: {
          entries: [
            { name: "build.yaml", type: "blob", object: null },
            { name: "deploy.yml", type: "blob", object: { text: "valid" } },
          ],
        },
      },
    };

    const files = parseWorkflowFiles(result);
    expect(files).toHaveLength(1);
    expect(files[0].name).toBe("deploy.yml");
  });

  it("should return empty array for empty entries", () => {
    const result: WorkflowFilesQueryResult = {
      repository: {
        object: {
          entries: [],
        },
      },
    };

    expect(parseWorkflowFiles(result)).toEqual([]);
  });

  it("should prepend .openci/ to file paths", () => {
    const result: WorkflowFilesQueryResult = {
      repository: {
        object: {
          entries: [{ name: "test.yaml", type: "blob", object: { text: "content" } }],
        },
      },
    };

    const files = parseWorkflowFiles(result);
    expect(files[0].path).toBe(".openci/test.yaml");
  });
});
