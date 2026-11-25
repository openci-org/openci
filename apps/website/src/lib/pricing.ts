import type { Locale } from "./i18n";

export const cloudRunners = ["Linux", "macOS"] as const;
type CloudRunner = (typeof cloudRunners)[number];
const linuxMinutesPerYen = 10;
export const macosUsdCentsPerMinute = 1;

export function formatRuntimeEstimate(
  minutes: number,
  locale: Locale,
  runner: CloudRunner = "macOS",
): string {
  const billedMinutes = Math.ceil(minutes);
  if (minutes < 0 || !Number.isSafeInteger(billedMinutes)) return "—";
  if (runner === "Linux") {
    const yen = Math.floor(billedMinutes / linuxMinutesPerYen);
    return `¥${yen.toLocaleString(locale)}`;
  }
  if (locale === "ja") return "¥" + billedMinutes.toLocaleString("ja-JP");

  const cents = billedMinutes * macosUsdCentsPerMinute;
  const dollars = Math.floor(cents / 100).toLocaleString("en-US");
  return `$${dollars}.${String(cents % 100).padStart(2, "0")}`;
}

export function formatMinuteRate(locale: Locale, runner: CloudRunner): string {
  if (runner === "Linux") return `¥${1 / linuxMinutesPerYen}`;
  if (locale === "en") return `${macosUsdCentsPerMinute}¢`;
  return formatRuntimeEstimate(1, locale, runner);
}
