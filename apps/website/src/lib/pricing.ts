import type { Locale } from "./i18n";

export const cloudRunners = ["Linux", "macOS"] as const;
type CloudRunner = (typeof cloudRunners)[number];
export const macosUsdCentsPerMinute = 1;

export function formatRuntimeEstimate(
  minutes: number,
  locale: Locale,
  runner: CloudRunner = "macOS",
): string {
  const billedMinutes = Math.ceil(minutes);
  if (minutes < 0 || !Number.isSafeInteger(billedMinutes)) return "—";
  if (runner === "Linux") {
    // Each minute is a tenth of a yen, including on the English site.
    const yen = Math.floor(billedMinutes / 10).toLocaleString(locale);
    const tenths = billedMinutes % 10;
    return tenths ? `¥${yen}.${tenths}` : `¥${yen}`;
  }
  if (locale === "ja") return "¥" + billedMinutes.toLocaleString("ja-JP");

  const cents = billedMinutes * macosUsdCentsPerMinute;
  const dollars = Math.floor(cents / 100).toLocaleString("en-US");
  return `$${dollars}.${String(cents % 100).padStart(2, "0")}`;
}

export function formatMinuteRate(locale: Locale, runner: CloudRunner): string {
  if (runner === "macOS" && locale === "en")
    return `${macosUsdCentsPerMinute}¢`;
  return formatRuntimeEstimate(1, locale, runner);
}
