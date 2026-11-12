export const locales = ["en", "ja"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "en";
export const siteOrigin = "https://openci.org";
export const translator = (locale: Locale) => (ja: string, en: string) =>
  locale === "ja" ? ja : en;
export const siteTitle = (locale: Locale) =>
  translator(locale)(
    "OpenCI — Flutter専用のCIを、1分1円で。",
    "OpenCI — CI for Flutter at 1 cent per minute.",
  );
export const siteDescription = (locale: Locale) =>
  translator(locale)(
    "Apple SiliconのMacでFlutterアプリのテスト、ビルド、配布を自動化。OpenCI Cloudは1分1円（税込）。",
    "Test, build and distribute Flutter apps on Apple Silicon Macs for 1 US cent per minute, tax included.",
  );
export const siteImage = "/ogp/openci.jpg";
export const siteImageAlt = (locale: Locale) =>
  translator(locale)(
    "6色の横縞に白いOpenCIのロゴ",
    "OpenCI in white on six rainbow stripes",
  );
