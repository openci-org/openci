import { describe, expect, it } from "vitest";

import {
  expandMatrix,
  matrixInstanceKey,
  matrixLabel,
  resolveMatrixExpressions,
} from "./matrix.js";

describe("expandMatrix", () => {
  it("expands axis cartesian products", () => {
    expect(
      expandMatrix({
        matrix: {
          os: ["ubuntu-latest", "macos-latest"],
          node: [20, 24],
        },
      }),
    ).toEqual([
      { os: "ubuntu-latest", node: 20 },
      { os: "ubuntu-latest", node: 24 },
      { os: "macos-latest", node: 20 },
      { os: "macos-latest", node: 24 },
    ]);
  });

  it("excludes combinations by partial matches", () => {
    expect(
      expandMatrix({
        matrix: {
          os: ["ubuntu-latest", "macos-latest"],
          node: [20, 24],
          exclude: [{ os: "macos-latest" }],
        },
      }),
    ).toEqual([
      { os: "ubuntu-latest", node: 20 },
      { os: "ubuntu-latest", node: 24 },
    ]);
  });

  it("merges includes into matching combinations and adds nonmatching combinations", () => {
    expect(
      expandMatrix({
        matrix: {
          os: ["ubuntu-latest", "macos-latest"],
          node: [24],
          include: [
            { os: "ubuntu-latest", cache: true },
            { os: "windows-latest", node: 24, cache: false },
          ],
        },
      }),
    ).toEqual([
      { os: "ubuntu-latest", node: 24, cache: true },
      { os: "macos-latest", node: 24 },
      { os: "windows-latest", node: 24, cache: false },
    ]);
  });

  it("supports include-only matrices", () => {
    expect(
      expandMatrix({
        matrix: {
          include: [
            { name: "Flutter CD", working_directory: "actions/flutter-cd" },
            { name: "Flutter Pub Cache", working_directory: "actions/flutter-pub-cache" },
          ],
        },
      }),
    ).toEqual([
      { name: "Flutter CD", working_directory: "actions/flutter-cd" },
      { name: "Flutter Pub Cache", working_directory: "actions/flutter-pub-cache" },
    ]);
  });
});

describe("matrix helpers", () => {
  it("formats labels and instance keys", () => {
    const matrix = { os: "ubuntu-latest", node: 24 };
    expect(matrixLabel(matrix)).toBe("node=24,os=ubuntu-latest");
    expect(matrixInstanceKey("build", matrix)).toBe("build[node=24,os=ubuntu-latest]");
  });

  it("uses matrix.name for display labels", () => {
    expect(matrixLabel({ name: "Flutter CD", node: 24 })).toBe("Flutter CD");
  });

  it("resolves simple matrix expressions recursively", () => {
    expect(
      resolveMatrixExpressions(
        {
          "runs-on": "${{ matrix.os }}",
          with: { node: "${{ matrix.node }}" },
        },
        { os: "ubuntu-latest", node: 24 },
      ),
    ).toEqual({
      "runs-on": "ubuntu-latest",
      with: { node: "24" },
    });
  });
});
