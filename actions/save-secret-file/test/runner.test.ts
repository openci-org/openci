import { describe, it, expect, beforeEach, afterEach } from "vitest";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import { saveSecret } from "../src/runner";

describe("saveSecret", () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "openci-action-test-"));
  });

  afterEach(() => {
    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  it("should save base64-encoded secret by decoding it", () => {
    const filePath = path.join(tempDir, "base64.txt");
    const secret = "aGVsbG8="; // "hello" in base64

    saveSecret({ secret, filePath, encoding: "base64" });

    expect(fs.existsSync(filePath)).toBe(true);
    expect(fs.readFileSync(filePath, "utf-8")).toBe("hello");
  });

  it("should save raw secret as-is", () => {
    const filePath = path.join(tempDir, "raw.json");
    const secret = '{"ok":true}';

    saveSecret({ secret, filePath, encoding: "raw" });

    expect(fs.existsSync(filePath)).toBe(true);
    expect(fs.readFileSync(filePath, "utf-8")).toBe('{"ok":true}');
  });

  it("should throw error for unsupported encoding", () => {
    const filePath = path.join(tempDir, "error.txt");
    const secret = "something";

    expect(() => {
      saveSecret({ secret, filePath, encoding: "invalid" });
    }).toThrow("Unsupported encoding: 'invalid' (must be 'base64' or 'raw')");
  });

  it("should create directory recursively if it doesn't exist", () => {
    const filePath = path.join(tempDir, "nested/dir/file.txt");
    const secret = "aGVsbG8=";

    saveSecret({ secret, filePath, encoding: "base64" });

    expect(fs.existsSync(filePath)).toBe(true);
    expect(fs.readFileSync(filePath, "utf-8")).toBe("hello");
  });
});
