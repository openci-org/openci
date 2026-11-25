export const locales = ["en", "ja"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "en";
export const siteOrigin = "https://openci.org";
export const translator = (locale: Locale) => (ja: string, en: string) =>
  locale === "ja" ? ja : en;
export const siteTitle = (locale: Locale) =>
  translator(locale)(
    "OpenCI — Flutter専用のCIを、1分0.1円から。",
    "OpenCI — CI for Flutter from ¥0.1 per minute.",
  );
export const siteDescription = (locale: Locale) =>
  translator(locale)(
    "Flutterアプリのビルドとテストを自動化。OpenCI CloudはLinuxが1分0.1円、Apple SiliconのmacOSが1分1円（税込）。",
    "Automate Flutter builds and tests on OpenCI Cloud. Linux costs ¥0.1 per minute and Apple Silicon macOS costs 1 US cent per minute, tax included.",
  );
export const siteImage = "/ogp/openci.jpg";
export const siteImageAlt = (locale: Locale) =>
  translator(locale)(
    "6色の横縞に白いOpenCIのロゴ",
    "OpenCI in white on six rainbow stripes",
  );
