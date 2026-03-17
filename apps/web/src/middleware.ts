import { type NextRequest, NextResponse } from 'next/server'
import { defaultLocale, locales } from '@/lib/i18n'

function getLocaleFromRequest(request: NextRequest): string {
  const cookieLocale = request.cookies.get('preferred_locale')?.value
  if (cookieLocale && locales.includes(cookieLocale as (typeof locales)[number])) {
    return cookieLocale
  }

  const acceptLanguage = request.headers.get('accept-language')
  if (!acceptLanguage) return defaultLocale

  const preferredLocales = acceptLanguage
    .split(',')
    .map((lang) => {
      const [locale, quality] = lang.trim().split(';q=')
      return { locale: locale.trim(), quality: quality ? parseFloat(quality) : 1 }
    })
    .sort((a, b) => b.quality - a.quality)

  for (const { locale } of preferredLocales) {
    const lang = locale.split('-')[0]
    if (locales.includes(lang as (typeof locales)[number])) {
      return lang
    }
  }

  return defaultLocale
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  const pathnameHasLocale = locales.some(
    (locale) => locale !== defaultLocale && (pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`),
  )

  if (pathnameHasLocale) return

  const locale = getLocaleFromRequest(request)

  if (locale !== defaultLocale) {
    const url = request.nextUrl.clone()
    url.pathname = `/${locale}${pathname}`
    return NextResponse.redirect(url)
  }
}

export const config = {
  matcher: ['/((?!_next|api|studio|sanity-studio|.*\\..*|blog/feed).*)'],
}
