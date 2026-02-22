import { BentoCard } from '@/components/bento-card'
import { Button } from '@/components/button'
import { Container } from '@/components/container'
import { Footer } from '@/components/footer'
import { Gradient } from '@/components/gradient'
import { Navbar } from '@/components/navbar'
import { Heading, Lead, Subheading } from '@/components/text'
import { slackInviteLink } from '@/constants'
import type { Metadata } from 'next'
import { PricingSectionForTop } from './pricing/page'

export const metadata: Metadata = {
  description:
    'OpenCI Runner is an open-source GitHub Actions runner that anyone can use. We offer affordable, flat-rate monthly pricing so that anyone can use CI/CD.',
}

function Hero() {
  return (
    <div className="relative">
      <Gradient className="absolute inset-2 bottom-0 rounded-4xl ring-1 ring-black/5 ring-inset" />
      <Container className="relative">
        <Navbar
        // banner={
        //   <Link
        //     href="/blog/radiant-raises-100m-series-a-from-tailwind-ventures"
        //     className="flex items-center gap-1 rounded-full bg-fuchsia-950/35 px-3 py-0.5 text-sm/6 font-medium text-white data-hover:bg-fuchsia-950/30"
        //   >
        //     OpenCI Runner v1.0 released!
        //     <ChevronRightIcon className="size-4" />
        //   </Link>
        // }
        />
        <div className="pt-16 pb-24 sm:pt-24 sm:pb-32 md:pt-32 md:pb-48">
          <h1 className="font-display text-6xl/[0.9] font-medium tracking-tight text-balance text-gray-950 sm:text-8xl/[0.8] md:text-9xl/[0.8]">
            CI/CD Made Easy.
          </h1>
          <p className="mt-8 max-w-lg text-xl/7 font-medium text-gray-950/75 sm:text-2xl/8">
            Simple, fast, and surprisingly affordable.
          </p>
          <div className="mt-12 flex flex-col gap-x-6 gap-y-4 sm:flex-row">
            <Button href={slackInviteLink}>Get started</Button>
            {/* <Button variant="secondary" href="/pricing">
              See pricing
            </Button> */}
          </div>
        </div>
      </Container>
    </div>
  )
}

function Introduction() {
  return (
    // ここにまず、OpenCIのデモを入れる。Workflowの構築がめっちゃ簡単という感じ。もう、ここで作れてもいいくらいよ。
    // そのあと、料金、FAQ、私の思い、会社情報、などを入れる。
    <Container>
      <Subheading>Why We Are Building OpenCI</Subheading>
      <Heading as="h3" className="mt-2">
        Democratize CI/CD with affordable pricing.
      </Heading>
      <Lead className="mt-6 max-w-3xl">
        Today&apos;s CI/CD pricing is too expensive.
      </Lead>
      <div className="mt-12 grid grid-cols-1 gap-12 lg:grid-cols-2">
        <div className="max-w-lg">
          <p className="text-sm/6 text-gray-600">
            CI/CD is an essential tool for software development. However, the
            pricing for GitHub Actions&apos; standard runners is prohibitively
            expensive for many software projects. While there is a free tier,
            and OSS projects get unlimited usage, in most cases normal usage
            exceeds the free tier, and not everyone develops open source
            software.
          </p>
          <p className="mt-8 text-sm/6 text-gray-600">
            Third-party runner services for GitHub Actions are trying to solve
            this problem. Some offer machines at 1/10th the price of
            GitHub&apos;s standard runners, while others provide faster
            machines—each company has its own approach. However, almost all of
            these services use pay-as-you-go pricing. This means you won&apos;t
            know the actual cost until the end of each month. Rather than making
            CI/CD accessible to everyone, these services seem more tailored to
            enterprise companies.
          </p>
          <p className="mt-8 text-sm/6 text-gray-600">
            That&apos;s why we offer affordable, flat-rate monthly pricing so
            that anyone can use CI/CD. Our pricing starts at just $1 per month.
            Of course, we also offer higher-spec machines. If you find a more
            affordable service than ours, please let us know—we&apos;re always
            striving to provide a better service.
          </p>
        </div>
        <div className="max-lg:order-first max-lg:max-w-lg">
          <div className="aspect-3/2 overflow-hidden rounded-xl shadow-xl outline-1 -outline-offset-1 outline-black/10">
            <img
              alt=""
              src="/company/masahiro.JPG"
              className="block size-full object-cover"
            />
          </div>
          <div className="mt-4">
            <p className="text-sm font-medium text-gray-900">Masahiro Aoki</p>
            <p className="text-sm text-gray-600">Founder of OpenCI, ex-IBMer</p>
          </div>
        </div>
      </div>
    </Container>
  )
}

function BentoSection() {
  return (
    <Container className="pb-32">
      <Subheading>How to</Subheading>
      <Heading as="h3" className="mt-2 max-w-3xl">
        Reduce your GitHub Actions costs by up to 90%—3 easy steps, 5 minutes or
        less.
      </Heading>

      <div className="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-6">
        <BentoCard
          eyebrow="Register"
          title="Create your account"
          description="Sign up for an OpenCI account to get started with affordable CI/CD."
          graphic={
            <div className="flex size-full items-center justify-center p-16">
              <img src="sign-up-form.png" alt="Sign up form" />
            </div>
          }
          className="lg:col-span-2 lg:rounded-bl-4xl"
        />
        <BentoCard
          eyebrow="Install"
          title="Install GitHub App"
          description="Install the GitHub App to the repositories where you want to use OpenCI runners."
          graphic={
            <div className="flex size-full items-center justify-center p-18">
              <img src="install-github-app.png" alt="Install GitHub App" />
            </div>
          }
          className="lg:col-span-2"
        />
        <BentoCard
          eyebrow="Modify"
          title="Update your workflow file"
          description="Modify your GitHub Actions workflow file to specify the use of OpenCI Runner."
          graphic={
            <div className="flex size-full items-center justify-center">
              <img
                src="/code-snippets/modify_yaml.png"
                alt="Workflow file example"
              />
            </div>
          }
          className="max-lg:rounded-b-4xl lg:col-span-2 lg:rounded-br-4xl"
        />
      </div>
    </Container>
  )
}

export default function Home() {
  return (
    <div className="overflow-hidden">
      <Hero />
      <main>
        <div className="bg-linear-to-b from-white from-50% to-gray-100 pt-32">
          {/* <FeatureSection /> */}
          <Introduction />
          <div className="my-32" />
          <BentoSection />
        </div>
      </main>
      <PricingSectionForTop />
      <Footer />
    </div>
  )
}
