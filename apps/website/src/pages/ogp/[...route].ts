import { getCollection } from "astro:content";
import { OGImageRoute } from "astro-og-canvas";
import { pageLocale } from "../../lib/content";

const articles = (await getCollection("pages")).filter(
  (page) => page.data.layout === "blog-article",
);
const images = new Map(articles.map((page) => [`${page.id}.png`, page]));
// These releases were originally shared at unlocalized JPEG URLs.
for (const slug of ["v2-1-0", "v2-2-0", "v2-3-0"]) {
  const page = images.get(`en/blog/${slug}.png`);
  if (page) images.set(`${slug}.jpg`, page);
}

export const { getStaticPaths, GET } = await OGImageRoute({
  pages: Object.fromEntries(images),
  getSlug: (path) => path,
  getImageOptions: (path, page) => ({
    format: path.endsWith(".jpg") ? "JPEG" : "PNG",
    title: page.data.title,
    description: path.endsWith(".jpg")
      ? `${page.data.category} / ${page.data.date?.replaceAll("-", ".")} · openci.org`
      : `${page.data.description}\n\n${page.data.category} / ${page.data.date?.replaceAll("-", ".")} · OpenCI Blog`,
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
