import { isAbsolute, join } from "path";

export function expandPath(path: string): string {
  if (path === "~") {
    return process.env.HOME || path;
  }
  if (path.startsWith("~/")) {
    return join(process.env.HOME || "", path.slice(2));
  }
  return path;
}

export function absolutePath(path: string, base: string): string {
  const expanded = expandPath(path);
  return isAbsolute(expanded) ? expanded : join(base, expanded);
}

export function sanitizeComponent(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-+/g, "-");
}
