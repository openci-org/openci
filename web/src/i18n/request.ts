import { getRequestConfig } from "next-intl/server";
import { cookies, headers } from "next/headers";
import { routing } from "./routing";

type Locale = (typeof routing.locales)[number];

function isValidLocale(value: string): value is Locale {
  return (routing.locales as readonly string[]).includes(value);
}

export default getRequestConfig(async () => {
  // Read cookie synchronously via next/headers
  const cookieStore = await cookies();
  const headerStore = await headers();

  const cookieLocale = cookieStore.get("NEXT_LOCALE")?.value;
  const acceptLanguage = headerStore.get("accept-language") ?? "";
  const browserLocale = acceptLanguage.split(",")[0]?.split("-")[0]?.trim();

  let locale: Locale = routing.defaultLocale;
  if (cookieLocale && isValidLocale(cookieLocale)) {
    locale = cookieLocale;
  } else if (browserLocale && isValidLocale(browserLocale)) {
    locale = browserLocale;
  }

  return {
    locale,
    messages: (await import(`../messages/${locale}.json`)).default,
  };
});
