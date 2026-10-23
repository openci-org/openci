import { defineConfig } from "astro/config";
import { unified, rehypeHeadingIds } from "@astrojs/markdown-remark";
import { genuineMarkdown } from "./src/lib/markdown.ts";
import { defaultLocale, locales, siteOrigin } from "./src/lib/i18n.ts";
export default defineConfig({
  site: siteOrigin,
  output: "static",
  trailingSlash: "always",
  i18n: {
    locales: [...locales],
    defaultLocale,
    routing: { prefixDefaultLocale: true, redirectToDefaultLocale: false },
  },
  markdown: {
    shikiConfig: { theme: "css-variables" },
    processor: unified({
      smartypants: false,
      rehypePlugins: [rehypeHeadingIds, genuineMarkdown],
    }),
  },
});
