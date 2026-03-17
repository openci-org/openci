import { Button } from '@/components/button'
import { Container } from '@/components/container'
import { Gradient, GradientBackground } from '@/components/gradient'
import { Heading, Lead, Subheading } from '@/components/text'
import type { Dictionary } from '@/lib/dictionaries'
import type { Locale } from '@/lib/i18n'
import { CheckIcon } from '@heroicons/react/16/solid'

const dashboardUrl = 'https://dashboard.openci.org'

function PricingCard({
  tier,
  dict,
}: {
  tier: Dictionary['pricing']['tiers'][number]
  dict: Dictionary
}) {
  return (
    <div className="-m-2 grid grid-cols-1 rounded-4xl shadow-[inset_0_0_2px_1px_#ffffff4d] ring-1 ring-black/5 max-lg:mx-auto max-lg:w-full max-lg:max-w-md">
      <div className="grid grid-cols-1 rounded-4xl p-2 shadow-md shadow-black/5">
        <div className="rounded-3xl bg-white p-10 pb-9 shadow-2xl ring-1 ring-black/5">
          <div className="flex items-center justify-between">
            <Subheading>{tier.name}</Subheading>
            {tier.name === 'Basic' && (
              <span className="rounded-full bg-gray-950 px-3 py-1 text-xs font-semibold text-white">
                {dict.pricing.popular}
              </span>
            )}
          </div>
          <p className="mt-2 text-sm/6 text-gray-950/75">{tier.description}</p>
          <div className="mt-8 flex items-baseline gap-2">
            <div className="text-5xl font-medium text-gray-950">{tier.price}</div>
            <div className="text-sm/5 text-gray-950/75">{tier.period}</div>
          </div>
          <div className="mt-8">
            <Button href={dashboardUrl}>{tier.cta}</Button>
          </div>
          <div className="mt-8">
            <h3 className="text-sm/6 font-medium text-gray-950">
              {dict.pricing.whatsIncluded}
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

function PricingCards({ dict }: { dict: Dictionary }) {
  return (
    <div className="relative py-24">
      <Gradient className="absolute inset-x-2 top-48 bottom-0 rounded-4xl ring-1 ring-black/5 ring-inset" />
      <Container className="relative">
        <div className="mx-auto grid max-w-4xl grid-cols-1 gap-8 lg:grid-cols-2">
          {dict.pricing.tiers.map((tier) => (
            <PricingCard key={tier.name} tier={tier} dict={dict} />
          ))}
        </div>
      </Container>
    </div>
  )
}

function PricingCardsWithTitle({ dict }: { dict: Dictionary }) {
  return (
    <div className="relative py-20">
      <Subheading className="text-center">{dict.pricing.sectionEyebrow}</Subheading>
      <Heading as="div" className="mt-2 mb-32 text-center">
        {dict.pricing.sectionHeading}
      </Heading>
      <Gradient className="absolute inset-x-2 top-60 bottom-0 rounded-4xl ring-1 ring-black/5 ring-inset" />
      <Container className="relative">
        <div className="mx-auto grid max-w-4xl grid-cols-1 gap-8 lg:grid-cols-2">
          {dict.pricing.tiers.map((tier) => (
            <PricingCard key={tier.name} tier={tier} dict={dict} />
          ))}
        </div>
      </Container>
    </div>
  )
}

function AddOns({ dict }: { dict: Dictionary }) {
  return (
    <Container className="py-24">
      <div className="mx-auto max-w-4xl">
        <Subheading className="text-center">{dict.pricing.addOns.eyebrow}</Subheading>
        <Heading as="div" className="mt-2 text-center">
          {dict.pricing.addOns.heading}
        </Heading>
        <div className="mt-16 space-y-6">
          {dict.pricing.addOns.items.map((addOn) => (
            <div
              key={addOn.name}
              className="flex flex-col items-start justify-between gap-4 rounded-2xl border border-gray-200 bg-white p-8 sm:flex-row sm:items-center"
            >
              <div>
                <h3 className="text-lg font-semibold text-gray-950">{addOn.name}</h3>
                <p className="mt-1 text-sm/6 text-gray-600">{addOn.description}</p>
              </div>
              <div className="shrink-0 text-right">
                <div className="text-3xl font-medium text-gray-950">{addOn.price}</div>
                <div className="text-sm text-gray-500">{addOn.period}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Container>
  )
}

function FrequentlyAskedQuestions({ dict }: { dict: Dictionary }) {
  return (
    <Container>
      <section id="faqs" className="scroll-mt-8">
        <Subheading className="text-center">{dict.pricing.faq.eyebrow}</Subheading>
        <Heading as="div" className="mt-2 text-center">
          {dict.pricing.faq.heading}
        </Heading>
        <div className="mx-auto mt-16 mb-32 max-w-xl space-y-12">
          {dict.pricing.faq.items.map((faq) => (
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

export function PricingHeader({ dict }: { dict: Dictionary }) {
  return (
    <Container className="mt-16">
      <Heading as="h1">{dict.pricing.heading}</Heading>
      <Lead className="mt-6 max-w-3xl">{dict.pricing.lead}</Lead>
    </Container>
  )
}

export function PricingPageContent({
  lang,
  dict,
}: {
  lang: Locale
  dict: Dictionary
}) {
  return (
    <>
      <PricingCards dict={dict} />
      <AddOns dict={dict} />
      <FrequentlyAskedQuestions dict={dict} />
    </>
  )
}

export function PricingSectionForTop({
  lang,
  dict,
}: {
  lang: Locale
  dict: Dictionary
}) {
  return (
    <main className="overflow-hidden">
      <GradientBackground />
      <PricingCardsWithTitle dict={dict} />
      <AddOns dict={dict} />
      <div className="m-32" />
    </main>
  )
}
