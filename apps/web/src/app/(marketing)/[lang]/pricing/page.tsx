import { Container } from '@/components/container'
import { Footer } from '@/components/footer'
import { GradientBackground } from '@/components/gradient'
import { Navbar } from '@/components/navbar'
import { getDictionary } from '@/lib/dictionaries'
import type { Locale } from '@/lib/i18n'
import { defaultLocale, locales } from '@/lib/i18n'
import type { Metadata } from 'next'
import { PricingHeader, PricingPageContent } from '../../pricing-content'

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
    title: dict.pricing.pageTitle,
    description: dict.pricing.pageDescription,
    alternates: {
      canonical: lang === defaultLocale ? '/pricing' : `/${lang}/pricing`,
      languages: {
        en: '/pricing',
        ja: '/ja/pricing',
      },
    },
  }
}

export default async function Pricing({
  params,
}: {
  params: Promise<{ lang: Locale }>
}) {
  const { lang } = await params
  const dict = await getDictionary(lang)

  return (
    <main className="overflow-hidden">
      <GradientBackground />
      <Container>
        <Navbar />
      </Container>
      <PricingHeader dict={dict} />
      <PricingPageContent lang={lang} dict={dict} />
      <Footer lang={lang} dict={dict} />
    </main>
  )
}
