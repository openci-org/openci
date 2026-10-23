export const locales = ["en", "ja"] as const;
export type Locale = (typeof locales)[number];
export const siteOrigin = "https://genuineci.com";
export const translator = (locale: Locale) => (ja: string, en: string) =>
  locale === "ja" ? ja : en;
export const localeFromPath = (path: string): Locale =>
  path.split("/").filter(Boolean)[0] === "ja" ? "ja" : "en";
export function logicalPath(path: string): string {
  const segments = new URL(path, siteOrigin).pathname
    .split("/")
    .filter(Boolean);
  if (locales.includes(segments[0] as Locale)) segments.shift();
  return segments.length ? `/${segments.join("/")}/` : "/";
}
export function localePath(locale: Locale, path: string): string {
  if (/^(?:[a-z][a-z\d+.-]*:|\/\/)/i.test(path)) return path;
  const url = new URL(path, siteOrigin);
  return `/${locale}${logicalPath(url.pathname)}${url.search}${url.hash}`;
}
export function availableTranslations(
  path: string,
  pages: string[],
): Partial<Record<Locale, string>> {
  const available = new Set(pages.map((p) => localePath(localeFromPath(p), p)));
  return Object.fromEntries(
    locales
      .map((locale) => [locale, localePath(locale, path)])
      .filter(([, p]) => available.has(p)),
  );
}
export const siteTitle = (locale: Locale) =>
  translator(locale)(
    "GenuineCI — Flutter & Dartに、本物のCIを。",
    "GenuineCI — Real CI for Flutter & Dart.",
  );
export const siteDescription = (locale: Locale) =>
  translator(locale)(
    "Dartで書かれたFlutter & Dart専用のオープンソースCI。ワークフローもDartで定義。Apple Silicon M1〜M4に対応し、セルフホストも可能です。",
    "Open-source CI for Flutter & Dart, built in Dart. Write workflows in Dart, run on Apple Silicon M1–M4, and self-host on your own machines.",
  );
export const releaseImage = "/ogp/v2-1-0.jpg?v=2";
export const releaseImageAlt = (locale: Locale) =>
  translator(locale)(
    "GenuineCI v2.1.0 is here. — 黄色い背景に黒い文字のリリースバナー",
    "GenuineCI v2.1.0 is here. — Black lettering on a yellow release banner",
  );
export const safeJson = (value: unknown) =>
  JSON.stringify(value).replaceAll("<", "\\u003c");
