import type { Locale } from "./i18n";

export const usdCentsPerMinute = 1;

export function formatRuntimeEstimate(minutes: number, locale: Locale): string {
  const billedMinutes = Math.ceil(minutes);
  if (minutes < 0 || !Number.isSafeInteger(billedMinutes)) return "—";
  if (locale === "ja") return "¥" + billedMinutes.toLocaleString("ja-JP");

  const cents = billedMinutes * usdCentsPerMinute;
  const dollars = Math.floor(cents / 100).toLocaleString("en-US");
  return `$${dollars}.${String(cents % 100).padStart(2, "0")}`;
}
