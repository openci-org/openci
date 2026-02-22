import type { Metadata } from 'next'
import Image from 'next/image'

import { Border } from '@/components/studio/Border'
import { ContactSection } from '@/components/studio/ContactSection'
import { Container } from '@/components/studio/Container'
import { FadeIn, FadeInStagger } from '@/components/studio/FadeIn'
import { PageIntro } from '@/components/studio/PageIntro'
import imageMasahiroAoki from '@/images/studio/team/masahiro-aoki.jpg'
import { StudioRootLayout } from '@/components/studio/StudioRootLayout'

const team = [
  {
    title: '代表者',
    people: [
      {
        name: 'Masahiro Aoki ( 青木 正浩 )',
        role: 'Founder / CEO',
        image: { src: imageMasahiroAoki },
      },
    ],
  },
]

function Team() {
  return (
    <Container className="mt-24 sm:mt-32 lg:mt-40">
      <div className="space-y-24">
        {team.map((group) => (
          <FadeInStagger key={group.title}>
            <Border as={FadeIn} />
            <div className="grid grid-cols-1 gap-6 pt-12 sm:pt-16 lg:grid-cols-4 xl:gap-8">
              <FadeIn>
                <h2 className="font-display text-2xl font-semibold text-neutral-950">
                  {group.title}
                </h2>
              </FadeIn>
              <div className="lg:col-span-3">
                <ul
                  role="list"
                  className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:gap-8"
                >
                  {group.people.map((person) => (
                    <li key={person.name}>
                      <FadeIn>
                        <div className="group relative overflow-hidden rounded-3xl bg-neutral-100">
                          <Image
                            alt=""
                            {...person.image}
                            className="h-96 w-full object-cover grayscale transition duration-500 motion-safe:group-hover:scale-105"
                          />
                          <div className="absolute inset-0 flex flex-col justify-end bg-linear-to-t from-black to-black/0 to-40% p-6">
                            <p className="font-display text-base/6 font-semibold tracking-wide text-white">
                              {person.name}
                            </p>
                            <p className="mt-2 text-sm text-white">
                              {person.role}
                            </p>
                          </div>
                        </div>
                      </FadeIn>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </FadeInStagger>
        ))}
      </div>
    </Container>
  )
}

export const metadata: Metadata = {
  title: 'About Us',
  description:
    'We believe that our strength lies in our collaborative approach, which puts our clients at the center of everything we do.',
}

export default function About() {
  return (
    <StudioRootLayout>
      <PageIntro eyebrow="会社概要" title="代表挨拶">
        <p>アプリ開発を通じて、よりよい世界を創る。</p>
        <div className="mt-10 max-w-2xl space-y-6 text-base">
          <p>
            初めまして。OpenCI (オープンシーアイ )株式会社の代表取締役社長、青木正浩です。
            <br />
            この度は弊社のサイトをご覧いただき、ありがとうございます。
          </p>

          <p>
            私はアプリ開発のキャリアをCTOから始めました。2019年8月にゲーマー向けマッチングアプリの共同創業者として、
            VCから資金調達を行い、約3年間アプリ開発に携わりました。
            その後、いくつかのプロジェクトを経て日本IBMに入社し、大手銀行アプリや大手海運企業のアプリ開発に従事しました。
          </p>

          <p>
            これらの経験を通じて、現在のCI/CDサービスには大きな課題があることに気づきました。
            使いづらさと高額な料金により、多くのプロジェクトがCI/CDを十分に活用できていないのが現状です。
            誰もが最高に使いやすいCI/CDサービスを作りたいという想いから、IBMを退職し、OpenCI株式会社を立ち上げました。
          </p>

          <p>
            OpenCI株式会社では、CI/CDをよりオープンにすべく、OSSとしてOpenCIを開発しています。
            これまでの課題を解決し、すべての開発者が効率的に開発できる環境を提供することを目指しています。
            <br />
            ご興味ある方は、
            <a
              href="https://github.com/open-ci-io/openci"
              target="_blank"
              rel="noopener noreferrer"
            >
              OpenCIのGitHub
            </a>
            をご覧ください。
          </p>

          <p>
            また、OpenCI
            Studio（以下Studio）では、私がこれまで培ってきたFlutter開発の技術と経験を活かし、
            技術支援サービスを提供しています。小規模なプロジェクトから大規模なエンタープライズアプリまで、
            幅広くサポートいたします。
          </p>

          <p>
            Studioでは単なる技術支援にとどまらず、私のCTOとしての経験、スタートアップでの事業立ち上げ、
            大企業でのプロジェクト推進の知見を活かし、お客様のビジネスを多角的にサポートします。
            技術的な課題解決はもちろん、チーム体制の構築、開発力強化、採用支援まで、
            ビジネスの成功に必要なあらゆる面でお手伝いいたします。
          </p>
        </div>
      </PageIntro>

      <Team />

      <ContactSection />
    </StudioRootLayout>
  )
}
