import { Container } from '@/components/container'
import { Footer } from '@/components/footer'
import { GradientBackground } from '@/components/gradient'
import { Navbar } from '@/components/navbar'
import { getDictionary } from '@/lib/dictionaries'
import type { Metadata } from 'next'
import { PricingHeader, PricingPageContent } from '../pricing-content'

export const metadata: Metadata = {
  title: 'Pricing',
  description:
    'Simple, transparent pricing for OpenCI. Start free with 60 minutes per month, or upgrade to unlimited builds for just ¥980/month.',
  alternates: {
    canonical: '/pricing',
    languages: {
      en: '/pricing',
      ja: '/ja/pricing',
    },
  },
}

export default async function Pricing() {
  const dict = await getDictionary('en')

  return (
    <main className="overflow-hidden">
      <GradientBackground />
      <Container>
        <Navbar />
      </Container>
      <PricingHeader dict={dict} />
      <PricingPageContent lang="en" dict={dict} />
      <Footer lang="en" dict={dict} />
    </main>
  )
}
