import { Button } from '@/components/button'
import { Container } from '@/components/container'
import { Footer } from '@/components/footer'
import { Gradient, GradientBackground } from '@/components/gradient'
import { Navbar } from '@/components/navbar'
import { Heading, Lead, Subheading } from '@/components/text'
import { CheckIcon } from '@heroicons/react/16/solid'
import type { Metadata } from 'next'

const dashboardUrl = 'https://dashboard.openci.org'

export const metadata: Metadata = {
  title: 'Pricing',
  description:
    'Simple, transparent pricing for OpenCI. Start free with 60 minutes per month, or upgrade to unlimited builds for just ¥980/month.',
}

const tiers = [
  {
    name: 'Free',
    description: 'Get started with CI/CD at no cost.',
    price: '¥0',
    period: 'forever',
    href: dashboardUrl,
    cta: 'Get started',
    featured: false,
    features: [
      '60 build minutes per month',
      '1 concurrent build',
      'Unlimited repositories',
      'Unlimited team members',
      'macOS builds (Apple Silicon)',
      'GitHub Actions compatible',
      'Community support (Slack)',
    ],
  },
  {
    name: 'Basic',
    description: 'For developers who ship fast.',
    price: '¥980',
    period: '/month',
    href: dashboardUrl,
    cta: 'Subscribe',
    featured: true,
    features: [
      'Unlimited build minutes',
      '1 concurrent build',
      'Unlimited repositories',
      'Unlimited team members',
      'macOS builds (Apple Silicon)',
      'GitHub Actions compatible',
      'Priority support',
    ],
  },
]

const addOns = [
  {
    name: 'Additional Concurrent Build',
    price: '¥2,000',
    period: '/month',
    description:
      'Run multiple builds simultaneously. Add as many as you need to your Basic plan.',
  },
]

function Header() {
  return (
    <Container className="mt-16">
      <Heading as="h1">Simple, transparent pricing.</Heading>
      <Lead className="mt-6 max-w-3xl">
        Start building for free. Upgrade when you need more.
        No hidden fees, no surprises.
      </Lead>
    </Container>
  )
}

function PricingCards() {
  return (
    <div className="relative py-24">
      <Gradient className="absolute inset-x-2 top-48 bottom-0 rounded-4xl ring-1 ring-black/5 ring-inset" />
      <Container className="relative">
        <div className="mx-auto grid max-w-4xl grid-cols-1 gap-8 lg:grid-cols-2">
          {tiers.map((tier) => (
            <PricingCard key={tier.name} tier={tier} />
          ))}
        </div>
      </Container>
    </div>
  )
}

function PricingCardsWithTitle() {
  return (
    <div className="relative py-20">
      <Subheading className="text-center">Pricing</Subheading>
      <Heading as="div" className="mt-2 mb-32 text-center">
        Start free. Scale as you grow.
      </Heading>
      <Gradient className="absolute inset-x-2 top-60 bottom-0 rounded-4xl ring-1 ring-black/5 ring-inset" />
      <Container className="relative">
        <div className="mx-auto grid max-w-4xl grid-cols-1 gap-8 lg:grid-cols-2">
          {tiers.map((tier) => (
            <PricingCard key={tier.name} tier={tier} />
          ))}
        </div>
      </Container>
    </div>
  )
}

function PricingCard({ tier }: { tier: (typeof tiers)[number] }) {
  return (
    <div className="-m-2 grid grid-cols-1 rounded-4xl shadow-[inset_0_0_2px_1px_#ffffff4d] ring-1 ring-black/5 max-lg:mx-auto max-lg:w-full max-lg:max-w-md">
      <div className="grid grid-cols-1 rounded-4xl p-2 shadow-md shadow-black/5">
        <div className="rounded-3xl bg-white p-10 pb-9 shadow-2xl ring-1 ring-black/5">
          <div className="flex items-center justify-between">
            <Subheading>{tier.name}</Subheading>
            {tier.featured && (
              <span className="rounded-full bg-gray-950 px-3 py-1 text-xs font-semibold text-white">
                Popular
              </span>
            )}
          </div>
          <p className="mt-2 text-sm/6 text-gray-950/75">
            {tier.description}
          </p>
          <div className="mt-8 flex items-baseline gap-2">
            <div className="text-5xl font-medium text-gray-950">
              {tier.price}
            </div>
            <div className="text-sm/5 text-gray-950/75">{tier.period}</div>
          </div>
          <div className="mt-8">
            <Button href={tier.href}>{tier.cta}</Button>
          </div>
          <div className="mt-8">
            <h3 className="text-sm/6 font-medium text-gray-950">
              What&apos;s included:
            </h3>
            <ul className="mt-3 space-y-3">
              {tier.features.map((feature) => (
                <li
                  key={feature}
                  className="flex items-start gap-3 text-sm/6 text-gray-950/75"
                >
                  <span className="inline-flex h-6 items-center">
                    <CheckIcon className="size-4 shrink-0 fill-gray-950/50" />
                  </span>
                  {feature}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}

function AddOns() {
  return (
    <Container className="py-24">
      <div className="mx-auto max-w-4xl">
        <Subheading className="text-center">Add-ons</Subheading>
        <Heading as="div" className="mt-2 text-center">
          Need more power?
        </Heading>
        <div className="mt-16 space-y-6">
          {addOns.map((addOn) => (
            <div
              key={addOn.name}
              className="flex flex-col items-start justify-between gap-4 rounded-2xl border border-gray-200 bg-white p-8 sm:flex-row sm:items-center"
            >
              <div>
                <h3 className="text-lg font-semibold text-gray-950">
                  {addOn.name}
                </h3>
                <p className="mt-1 text-sm/6 text-gray-600">
                  {addOn.description}
                </p>
              </div>
              <div className="shrink-0 text-right">
                <div className="text-3xl font-medium text-gray-950">
                  {addOn.price}
                </div>
                <div className="text-sm text-gray-500">{addOn.period}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Container>
  )
}

function FrequentlyAskedQuestions() {
  const faqs = [
    {
      question: 'What counts as build minutes?',
      answer:
        'Build minutes are measured from the moment your workflow starts executing until it completes. Queue wait time is not counted. Each build job is tracked independently.',
    },
    {
      question: 'What happens when I reach the free plan limit?',
      answer:
        'When you reach 60 minutes in a billing cycle, new builds will be queued until your minutes reset at the start of the next month. You can upgrade to the Basic plan at any time for unlimited builds.',
    },
    {
      question: 'What does "concurrent builds" mean?',
      answer:
        'Concurrent builds determine how many builds can run at the same time. With 1 concurrent build, jobs run one at a time. Adding more concurrent builds lets multiple workflows execute in parallel, reducing wait times.',
    },
    {
      question: 'What platforms are supported?',
      answer:
        'OpenCI runs on Apple Silicon Mac hardware. Your workflows use GitHub Actions syntax, so you can build iOS, Android, Flutter, React Native, and any other macOS-compatible project.',
    },
    {
      question: 'Can I cancel my subscription anytime?',
      answer:
        'Yes. You can cancel your subscription at any time from your dashboard. Your plan will remain active until the end of the current billing period.',
    },
    {
      question: 'Is there a team or enterprise plan?',
      answer:
        'We are working on dedicated support and development assistance plans. Join our Slack community or reach out to us for custom requirements.',
    },
  ]

  return (
    <Container>
      <section id="faqs" className="scroll-mt-8">
        <Subheading className="text-center">
          Frequently asked questions
        </Subheading>
        <Heading as="div" className="mt-2 text-center">
          Your questions answered.
        </Heading>
        <div className="mx-auto mt-16 mb-32 max-w-xl space-y-12">
          {faqs.map((faq) => (
            <dl key={faq.question}>
              <dt className="text-sm font-semibold">{faq.question}</dt>
              <dd className="mt-4 text-sm/6 text-gray-600">{faq.answer}</dd>
            </dl>
          ))}
        </div>
      </section>
    </Container>
  )
}

export default function Pricing() {
  return (
    <main className="overflow-hidden">
      <GradientBackground />
      <Container>
        <Navbar />
      </Container>
      <Header />
      <PricingCards />
      <AddOns />
      <FrequentlyAskedQuestions />
      <Footer />
    </main>
  )
}

export function PricingSectionForTop() {
  return (
    <main className="overflow-hidden">
      <GradientBackground />
      <PricingCardsWithTitle />
      <AddOns />
      <div className="m-32" />
    </main>
  )
}
