import { getDictionary } from '@/lib/dictionaries'
import type { Locale } from '@/lib/i18n'
import { defaultLocale, locales } from '@/lib/i18n'
import type { Metadata } from 'next'

export async function generateStaticParams() {
  return locales.map((lang) => ({ lang }))
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: Locale }>
}): Promise<Metadata> {
  const { lang } = await params
  const dict = await getDictionary(lang)

  return {
    description: dict.meta.description,
    alternates: {
      canonical: lang === defaultLocale ? '/' : `/${lang}`,
      languages: {
        en: '/',
        ja: '/ja',
      },
    },
  }
}

export default async function Home({
  params,
}: {
  params: Promise<{ lang: Locale }>
}) {
  const { lang } = await params
  const dict = await getDictionary(lang)
  const { default: HomeContent } = await import('./home-content')

  return <HomeContent lang={lang} dict={dict} />
}
