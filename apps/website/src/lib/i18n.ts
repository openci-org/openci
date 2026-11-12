export const locales = ["en", "ja"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "en";
export const siteOrigin = "https://openci.org";
export const translator = (locale: Locale) => (ja: string, en: string) =>
  locale === "ja" ? ja : en;
export const siteTitle = (locale: Locale) =>
  translator(locale)(
    "OpenCI — Flutter専用のCIを、1分1円で。",
    "OpenCI — CI for Flutter at ¥1 per minute.",
  );
export const siteDescription = (locale: Locale) =>
  translator(locale)(
    "Apple SiliconのMacでFlutterアプリのテスト、ビルド、配布を自動化。OpenCI Cloudは1分1円（税込）。",
    "Test, build and distribute Flutter apps on Apple Silicon Macs. OpenCI Cloud costs ¥1 per minute, tax included.",
  );
export const releaseImage = "/ogp/v2-1-0.jpg?v=2";
export const releaseImageAlt = (locale: Locale) =>
  translator(locale)(
    "GenuineCI v2.1.0 is here. — 黄色い背景に黒い文字のリリースバナー",
    "GenuineCI v2.1.0 is here. — Black lettering on a yellow release banner",
  );
