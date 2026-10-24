import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import { websiteMarkdown } from "./src/lib/markdown.ts";
import {
  defaultLocale,
  locales,
  releaseImage,
  siteOrigin,
} from "./src/lib/i18n.ts";
export default defineConfig({
  site: siteOrigin,
  output: "static",
  trailingSlash: "always",
  integrations: [
    starlight({
      title: "GenuineCI Docs",
      defaultLocale,
      locales: Object.fromEntries(
        locales.map((locale) => [
          locale,
          { lang: locale, label: locale === "ja" ? "日本語" : "English" },
        ]),
      ),
      disable404Route: true,
      favicon: "/favicon.png",
      titleDelimiter: "—",
      customCss: ["./src/styles/starlight.css"],
      routeMiddleware: "./src/lib/docs-route.ts",
      components: {
        Footer: "./src/components/StarlightFooter.astro",
        PageTitle: "./src/components/StarlightPageTitle.astro",
      },
      editLink: {
        baseUrl:
          "https://github.com/openci-org/openci/edit/develop/apps/website/",
      },
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/openci-org/openci",
        },
      ],
      sidebar: [
        {
          label: "Getting started",
          translations: { ja: "はじめに" },
          items: ["docs", "docs/quickstart"],
        },
        {
          label: "Workflows",
          translations: { ja: "ワークフロー" },
          items: [
            "docs/workflows",
            "docs/triggers",
            "docs/flutter",
            "docs/secrets",
          ],
        },
        {
          label: "Environment and tools",
          translations: { ja: "環境とツール" },
          items: ["docs/cli", "docs/self-hosting"],
        },
      ],
      head: [
        {
          tag: "meta",
          attrs: { name: "robots", content: "noindex, nofollow" },
        },
        { tag: "meta", attrs: { name: "theme-color", content: "#fffb00" } },
        { tag: "meta", attrs: { property: "og:type", content: "website" } },
        ...["og:image", "twitter:image"].map((name) => ({
          tag: "meta",
          attrs: {
            [name.startsWith("og:") ? "property" : "name"]: name,
            content: new URL(releaseImage, siteOrigin).href,
          },
        })),
        {
          tag: "meta",
          attrs: { property: "og:image:type", content: "image/jpeg" },
        },
        { tag: "meta", attrs: { property: "og:image:width", content: "1200" } },
        { tag: "meta", attrs: { property: "og:image:height", content: "630" } },
      ],
    }),
  ],
  markdown: {
    shikiConfig: { theme: "css-variables" },
    processor: websiteMarkdown(),
  },
});
