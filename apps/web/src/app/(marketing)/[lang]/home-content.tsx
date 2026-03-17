import { BentoCard } from '@/components/bento-card'
import { Button } from '@/components/button'
import { Container } from '@/components/container'
import { Footer } from '@/components/footer'
import { Gradient } from '@/components/gradient'
import { Navbar } from '@/components/navbar'
import { Heading, Lead, Subheading } from '@/components/text'
import { slackInviteLink } from '@/constants'
import type { Dictionary } from '@/lib/dictionaries'
import type { Locale } from '@/lib/i18n'
import { PricingSectionForTop } from '../pricing-content'

function Hero({ dict }: { dict: Dictionary }) {
  return (
    <div className="relative">
      <Gradient className="absolute inset-2 bottom-0 rounded-4xl ring-1 ring-black/5 ring-inset" />
      <Container className="relative">
        <Navbar />
        <div className="pt-16 pb-24 sm:pt-24 sm:pb-32 md:pt-32 md:pb-48">
          <h1 className="font-display text-6xl/[1.1] font-medium tracking-tight text-balance text-gray-950 sm:text-8xl/[1.0] md:text-9xl/[1.0] whitespace-pre-line">
            {dict.hero.title}
          </h1>
          <p className="mt-8 max-w-lg text-xl/7 font-medium text-gray-950/75 sm:text-2xl/8">
            {dict.hero.subtitle}
          </p>
          <div className="mt-12 flex flex-col gap-x-6 gap-y-4 sm:flex-row">
            <Button href="https://dashboard.openci.org">{dict.hero.cta}</Button>
          </div>
        </div>
      </Container>
    </div>
  )
}

function Introduction({ dict }: { dict: Dictionary }) {
  return (
    <Container>
      <Subheading>{dict.introduction.eyebrow}</Subheading>
      <Heading as="h3" className="mt-2">
        {dict.introduction.heading}
      </Heading>
      <Lead className="mt-6 max-w-3xl">{dict.introduction.lead}</Lead>
      <div className="mt-12 grid grid-cols-1 gap-12 lg:grid-cols-2">
        <div className="max-w-lg">
          <p className="text-sm/6 text-gray-600">{dict.introduction.paragraph1}</p>
          <p className="mt-8 text-sm/6 text-gray-600">{dict.introduction.paragraph2}</p>
          <p className="mt-8 text-sm/6 text-gray-600">{dict.introduction.paragraph3}</p>
        </div>
        <div className="max-lg:order-first max-lg:max-w-lg">
          <div className="aspect-3/2 overflow-hidden rounded-xl shadow-xl outline-1 -outline-offset-1 outline-black/10">
            <img alt="" src="/company/masahiro.JPG" className="block size-full object-cover" />
          </div>
          <div className="mt-4">
            <p className="text-sm font-medium text-gray-900">{dict.introduction.founderName}</p>
            <p className="text-sm text-gray-600">{dict.introduction.founderTitle}</p>
          </div>
        </div>
      </div>
    </Container>
  )
}

function BentoSection({ dict }: { dict: Dictionary }) {
  return (
    <Container className="pb-32">
      <Subheading>{dict.bento.eyebrow}</Subheading>
      <Heading as="h3" className="mt-2 max-w-3xl">
        {dict.bento.heading}
      </Heading>

      <div className="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-6">
        <BentoCard
          eyebrow={dict.bento.step1.eyebrow}
          title={dict.bento.step1.title}
          description={dict.bento.step1.description}
          graphic={
            <div className="flex size-full items-center justify-center p-16">
              <img src="sign-up-form.png" alt="Sign up form" />
            </div>
          }
          className="lg:col-span-2 lg:rounded-bl-4xl"
        />
        <BentoCard
          eyebrow={dict.bento.step2.eyebrow}
          title={dict.bento.step2.title}
          description={dict.bento.step2.description}
          graphic={
            <div className="flex size-full items-center justify-center">
              <img
                src="/create_workflow_gui.png"
                alt="Create workflow with GUI editor"
                className="block size-full object-contain"
              />
            </div>
          }
          className="lg:col-span-2"
        />
        <BentoCard
          eyebrow={dict.bento.step3.eyebrow}
          title={dict.bento.step3.title}
          description={dict.bento.step3.description}
          graphic={
            <div className="flex size-full items-center justify-center">
              <img
                src="/create_workflow_yaml.png"
                alt="Create workflow with YAML editor"
                className="block size-full object-contain"
              />
            </div>
          }
          className="max-lg:rounded-b-4xl lg:col-span-2 lg:rounded-br-4xl"
        />
      </div>
    </Container>
  )
}

export default function HomeContent({ lang, dict }: { lang: Locale; dict: Dictionary }) {
  return (
    <div className="overflow-hidden">
      <Hero dict={dict} />
      <main>
        <div className="bg-linear-to-b from-white from-50% to-gray-100 pt-32">
          <Introduction dict={dict} />
          <div className="my-32" />
          <BentoSection dict={dict} />
        </div>
      </main>
      <PricingSectionForTop lang={lang} dict={dict} />
      <Footer lang={lang} dict={dict} />
    </div>
  )
}
