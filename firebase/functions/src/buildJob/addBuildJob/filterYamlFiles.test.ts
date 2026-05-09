import { describe, expect, it } from "vitest";
import { filterYamlFiles } from "./filterYamlFiles";

describe("filterYamlFiles", () => {
  it("returns only .yaml and .yml files", () => {
    const entries = [
      { type: "file", name: "ci.yaml", path: ".openci/ci.yaml" },
      { type: "file", name: "deploy.yml", path: ".openci/deploy.yml" },
      { type: "file", name: "README.md", path: ".openci/README.md" },
      { type: "dir", name: "scripts", path: ".openci/scripts" },
    ];

    expect(filterYamlFiles(entries)).toEqual([
      { type: "file", name: "ci.yaml", path: ".openci/ci.yaml" },
      { type: "file", name: "deploy.yml", path: ".openci/deploy.yml" },
    ]);
  });

  it("excludes directories even if named .yaml", () => {
    const entries = [{ type: "dir", name: "weird.yaml", path: ".openci/weird.yaml" }];

    expect(filterYamlFiles(entries)).toEqual([]);
  });

  it("returns empty array when no yaml files", () => {
    const entries = [{ type: "file", name: "config.json", path: ".openci/config.json" }];

    expect(filterYamlFiles(entries)).toEqual([]);
  });
});
