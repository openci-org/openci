import { getCollection } from "astro:content";
import type { GetStaticPaths, InferGetStaticPropsType } from "astro";
import { blogCoverPath, pageLocale } from "../../lib/content";
import { renderBlogCard } from "../../lib/blog-card";

export const getStaticPaths = (async () => {
  const articles = await getCollection(
    "pages",
    (page) => page.data.layout === "blog-article",
  );
  const images = new Map(articles.map((page) => [`${page.id}.png`, page]));
  // These releases were originally shared at unlocalized JPEG URLs.
  for (const slug of ["v2-1-0", "v2-2-0", "v2-3-0"]) {
    const page = images.get(`en/blog/${slug}.png`);
    if (page) images.set(`${slug}.jpg`, page);
  }
  return Array.from(images, ([route, page]) => ({
    params: { route },
    props: { page, jpeg: route.endsWith(".jpg") },
  }));
}) satisfies GetStaticPaths;

export async function GET({
  props: { page, jpeg },
}: {
  props: InferGetStaticPropsType<typeof getStaticPaths>;
}) {
  const card = await renderBlogCard(
    page.data,
    blogCoverPath(page),
    pageLocale(page),
    jpeg,
  );
  return new Response(new Uint8Array(card), {
    headers: { "Content-Type": jpeg ? "image/jpeg" : "image/png" },
  });
}
