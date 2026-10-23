import type { CollectionEntry } from "astro:content";
import { getLocaleByPath, getRelativeLocaleUrl } from "astro:i18n";
import { locales, type Locale } from "./i18n";
export type Page = CollectionEntry<"pages">;
// Content IDs follow <locale>/<section>/<slug>, shared by each translation.
const pageSlug = (page: Page) => page.id.split("/").slice(1).join("/");
export const pageLocale = (page: Page) =>
  getLocaleByPath(page.id.split("/")[0]) as Locale;
export const pagePath = (page: Page) =>
  getRelativeLocaleUrl(pageLocale(page), pageSlug(page));
export function availableTranslations(
  page: Page,
  pages: Page[],
): Partial<Record<Locale, string>> {
  const available = new Set(pages.map(pagePath));
  return Object.fromEntries(
    locales
      .map((locale) => [locale, getRelativeLocaleUrl(locale, pageSlug(page))])
      .filter(([, path]) => available.has(path)),
  );
}
export const plainTitle = (title: string) => title.replace(/\s+/g, " ").trim();
export const blogPosts = (pages: Page[], locale: Locale) =>
  pages
    .filter((p) => p.data.layout === "blog-article" && pageLocale(p) === locale)
    .sort(
      (a, b) =>
        (b.data.date ?? "").localeCompare(a.data.date ?? "") ||
        a.id.localeCompare(b.id),
    );
