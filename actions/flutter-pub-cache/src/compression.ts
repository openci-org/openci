import { run } from "./process_runner";

export async function compressionExtension(): Promise<"tar.zst" | "tar.gz"> {
  const result = await run("zstd", ["--version"], { ignoreFailure: true });
  return result.code === 0 ? "tar.zst" : "tar.gz";
}

export async function compressionContentType(): Promise<"application/zstd" | "application/gzip"> {
  return (await compressionExtension()) === "tar.zst" ? "application/zstd" : "application/gzip";
}
