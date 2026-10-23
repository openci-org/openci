import { defineConfig } from "astro/config";
import { unified } from "@astrojs/markdown-remark";
import { genuineMarkdown } from "./src/lib/markdown.ts";
export default defineConfig({
  site: "https://genuineci.com",
  output: "static",
  trailingSlash: "always",
  i18n: {
    locales: ["en", "ja"],
    defaultLocale: "en",
    routing: { prefixDefaultLocale: true, redirectToDefaultLocale: false },
  },
  markdown: {
    syntaxHighlight: false,
    processor: unified({
      smartypants: false,
      rehypePlugins: [genuineMarkdown],
    }),
  },
});
