import type { CollectionEntry } from "astro:content";
import { localeFromPath, type Locale } from "./i18n";
export type Page = CollectionEntry<"pages">;
export const pagePath = (page: Page) => `/${page.id}/`;
export const plainTitle = (title: string) => title.replace(/\s+/g, " ").trim();
export const blogPosts = (pages: Page[], locale: Locale) =>
  pages
    .filter(
      (p) =>
        p.data.layout === "blog-article" && localeFromPath(p.id) === locale,
    )
    .sort(
      (a, b) =>
        (b.data.date ?? "").localeCompare(a.data.date ?? "") ||
        a.id.localeCompare(b.id),
    );
