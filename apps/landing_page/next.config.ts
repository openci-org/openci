import { PHASE_DEVELOPMENT_SERVER } from "next/constants";
import type { NextConfig } from "next";

export default function nextConfig(phase: string): NextConfig {
  const development = phase === PHASE_DEVELOPMENT_SERVER;
  const content = process.env.OPENCI_CONTENT_ORIGIN;
  return {
    output: development ? undefined : "export",
    trailingSlash: true,
    images: { unoptimized: true },
    ...(development &&
      content && {
        async rewrites() {
          return {
            beforeFiles: [
              {
                source: "/:locale(en|ja)/:section(blog|docs|pricing)/:path*",
                destination: `${content}/:locale/:section/:path*/`,
              },
            ],
            afterFiles: [],
            fallback: [{ source: "/:path*", destination: `${content}/:path*` }],
          };
        },
      }),
  };
}
