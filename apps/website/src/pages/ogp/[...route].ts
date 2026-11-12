import { getCollection } from "astro:content";
import { OGImageRoute } from "astro-og-canvas";
import { pageLocale } from "../../lib/content";

const articles = (await getCollection("pages")).filter(
  (page) => page.data.layout === "blog-article",
);

export const { getStaticPaths, GET } = await OGImageRoute({
  pages: Object.fromEntries(articles.map((page) => [page.id, page])),
  getSlug: (id) => `${id}.png`,
  getImageOptions: (_path, page) => ({
    title: page.data.title,
    description: `${page.data.description}\n\n${page.data.category} / ${page.data.date?.replaceAll("-", ".")} · OpenCI Blog`,
    bgGradient: [[247, 248, 252]],
    logo: { path: "./public/favicon.png", size: [42, 42] },
    border: { side: "inline-start", width: 12, color: [49, 91, 255] },
    padding: 72,
    fonts: ["./src/assets/fonts/NotoSansJP.ttf"],
    font: {
      title: {
        families: ["Noto Sans JP"],
        color: [37, 43, 59],
        size: pageLocale(page) === "ja" ? 64 : 72,
        weight: "Bold",
        lineHeight: 1.16,
      },
      description: {
        families: ["Noto Sans JP"],
        color: [64, 74, 105],
        size: 28,
        lineHeight: 1.4,
      },
    },
  }),
});
