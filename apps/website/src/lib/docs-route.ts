import { getCollection } from "astro:content";
import { getRelativeLocaleUrl } from "astro:i18n";
import { defineRouteMiddleware } from "@astrojs/starlight/route-data";
import { availableTranslations } from "./content";
import { releaseImageAlt, type Locale } from "./i18n";

export const onRequest = defineRouteMiddleware(async ({ locals }) => {
  const route = locals.starlightRoute;
  const locale = route.lang as Locale;
  route.siteTitleHref = getRelativeLocaleUrl(locale, "docs/");
  const translations = availableTranslations(
    route.entry,
    await getCollection("docs"),
  );
  // Only advertise real translations, including when Starlight renders fallback content.
  route.head = route.head.filter(({ attrs }) => {
    if (typeof attrs?.hreflang !== "string") return true;
    const language = attrs.hreflang === "x-default" ? "en" : attrs.hreflang;
    return language in translations;
  });
  const ogLocale = route.head.find(
    ({ attrs }) => attrs?.property === "og:locale",
  );
  if (ogLocale?.attrs)
    ogLocale.attrs.content = locale === "ja" ? "ja_JP" : "en_US";
  route.head.push(
    {
      tag: "meta",
      attrs: { property: "og:image:alt", content: releaseImageAlt(locale) },
    },
    {
      tag: "meta",
      attrs: { name: "twitter:image:alt", content: releaseImageAlt(locale) },
    },
  );
});
