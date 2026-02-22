import { ContactSection } from '@/components/studio/ContactSection'
import { Container } from '@/components/studio/Container'
import { FadeIn } from '@/components/studio/FadeIn'
import { List, ListItem } from '@/components/studio/List'
import { SectionIntro } from '@/components/studio/SectionIntro'
import { StudioRootLayout } from '@/components/studio/StudioRootLayout'
import { StylizedImage } from '@/components/studio/StylizedImage'
import { Testimonial } from '@/components/studio/Testimonial'
import imageLaptop from '@/images/studio/laptop.jpg'
import { CheckIcon } from '@heroicons/react/20/solid'
import type { Metadata } from 'next'

export default function Home() {
  return (
    <StudioRootLayout>
      <Container className="mt-24 sm:mt-32 md:mt-56">
        <FadeIn className="max-w-3xl">
          <h1 className="font-display text-5xl font-medium tracking-tight text-balance text-neutral-950 sm:text-7xl">
            ビジネスを
            <br />
            成功に導くアプリを創る。
          </h1>
          <p className="mt-6 text-xl text-neutral-600">
            OpenCI Studioは、弊社代表青木の長年の経験・技術を活かして、
            <br />
            ビジネスを成功に導くアプリを開発します。
            <br />
            アプリ開発において、最も大切なのは技術ではなく、ビジネスが成功するかどうか。ここに重点を置き、開発、技術支援、コンサルティングを行います。
          </p>
        </FadeIn>
      </Container>

      <Services />
      <Testimonial
        className="mt-24 sm:mt-32 lg:mt-40"
        client={{
          name: '非公開プロジェクト(大手外資系企業) - 技術顧問として参画',
        }}
      >
        OpenCI
        Studioのサポートにより、停滞していたプロジェクトが劇的に改善しました。
        技術的な課題の解決だけでなく、チーム全体のスキルアップを実現し、
        メンバーのモチベーション向上にも大きく貢献していただきました。
      </Testimonial>
      <Pricing />

      <ContactSection />
    </StudioRootLayout>
  )
}

function Services() {
  return (
    <>
      <SectionIntro
        eyebrow="提供サービス"
        title="個人開発規模から大規模なものまで、なんでもお任せください。"
        className="mt-24 sm:mt-32 lg:mt-40"
      >
        <p>
          OpenCI Studioは、数人規模の会社から大手外資系企業まで、
          様々な規模のプロジェクトに参画し、結果を残してきました。
        </p>
      </SectionIntro>
      <Container className="mt-16">
        <div className="lg:flex lg:items-center lg:justify-end">
          <div className="flex justify-center lg:w-1/2 lg:justify-end lg:pr-12">
            <FadeIn className="w-135 flex-none lg:w-180">
              <StylizedImage
                src={imageLaptop}
                sizes="(min-width: 1024px) 41rem, 31rem"
                className="justify-center lg:justify-end"
              />
            </FadeIn>
          </div>
          <List className="mt-16 lg:mt-0 lg:w-1/2 lg:min-w-132 lg:pl-4">
            <ListItem title="iOS+Androidアプリ開発(Flutter)">
              Googleが開発した世界で最も使用されているクロスプラットフォームフレームワークの1つである、Flutterを使用し、アプリ開発を行います。
              毎月の稼働時間を決め、その中で稼働時間に応じて時給で請求します。
              弊社代表青木が責任を持って開発をします。外部委託はいたしません。
            </ListItem>
            <ListItem title="Flutter開発の技術支援 ( 技術顧問 )">
              弊社代表青木が、Flutter開発の技術顧問として、
              お客様のプロジェクトに参画し、技術的な課題を解決します。
              チーム規模に応じて毎月一定額の請求を行います。質問はSlackやHuddleでお受けします。回数は無制限です。
              また毎週の定例に参加します。東京近辺であれば、現地参加も可能です。
            </ListItem>
            <ListItem title="CI/CDの導入支援">
              お客様のプロジェクトに、CI/CDを導入し、
              ビルド、テスト、リリースを自動化します。
              また、各種テストコードの追加も必要に応じて行います。
            </ListItem>
            <ListItem title="AI開発の技術支援 ( 技術顧問 )">
              弊社代表青木が、AI開発の技術顧問として、
              お客様のプロジェクトに参画し、技術力・デリバリスピードの改善を行います。
              こちらもFlutter開発の技術支援と同様に、チーム規模に応じて毎月一定額の請求を行います。質問はSlackやHuddleでお受けします。回数は無制限です。
              また毎週の定例に参加します。東京近辺であれば、現地参加も可能です。
            </ListItem>
          </List>
        </div>
      </Container>
    </>
  )
}

export const metadata: Metadata = {
  description:
    'OpenCI Studioは、数人規模の会社から大企業まで、様々な規模のプロジェクトに対応できるFlutterの開発スタジオです。',
}

const tiers = [
  {
    id: 'flutter-app-development',
    name: 'アプリ開発 ( Flutter )',
    price: { monthly: '800,000円~', annually: '9,600,000円~' },
    description: 'Flutterを使用したアプリ開発を行います。',
    features: [
      '定例参加',
      '週1-2回のオフィスでの作業',
      'Flutterの開発',
      'コードレビュー',
    ],
    featured: false,
    cta: '申し込む',
  },
  {
    id: 'flutter-development-consulting',
    name: 'Flutter開発の技術支援 ( 技術顧問 )',
    price: { monthly: '300,000円~', annually: '3,000,000円~' },
    description: 'Flutter開発の技術支援を行います。',
    features: [
      '定例参加 ( 現地参加可 )',
      '無制限の質問 ( チャットおよび通話 )',
      'コードレビュー',
    ],
    featured: false,
    cta: '申し込む',
  },
  {
    id: 'other',
    name: 'オーダーメイド',
    price: 'カスタム',
    description:
      '上記プランに当てはまらないご要望がありましたら、お気軽にお問い合わせください。',
    features: [
      '柔軟にご要望にお応え可能',
      'アプリ以外の開発',
      'AI開発の技術支援',
      'CI/CDの導入支援',
      'テストコードの追加',
    ],
    featured: true,
    cta: '問い合わせ',
  },
]

function Pricing() {
  return (
    <form className="group/tiers bg-white pt-24 sm:pt-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-4xl text-center">
          <h2 className="text-base/7 font-semibold text-neutral-950">料金表</h2>
        </div>
        <p className="mx-auto mt-6 max-w-2xl text-center text-lg font-medium text-pretty text-neutral-600 sm:text-xl/8">
          価格は全て税抜きです。
          <br />
          最低契約期間は3ヶ月、毎月最低稼動時間は100時間です。
        </p>
        <div className="mt-16 flex justify-center">
          <fieldset aria-label="Payment frequency">
            <div className="grid grid-cols-2 gap-x-1 rounded-full p-1 text-center text-xs/5 font-semibold ring-1 ring-gray-200 ring-inset">
              <label className="group relative rounded-full px-2.5 py-1 has-checked:bg-neutral-950">
                <input
                  defaultValue="monthly"
                  defaultChecked
                  name="frequency"
                  type="radio"
                  className="absolute inset-0 appearance-none rounded-full"
                />
                <span className="text-gray-500 group-has-checked:text-white">
                  月額
                </span>
              </label>
              <label className="group relative rounded-full px-2.5 py-1 has-checked:bg-neutral-950">
                <input
                  defaultValue="annually"
                  name="frequency"
                  type="radio"
                  className="absolute inset-0 appearance-none rounded-full"
                />
                <span className="text-gray-500 group-has-checked:text-white">
                  年額
                </span>
              </label>
            </div>
          </fieldset>
        </div>
        <div className="isolate mx-auto mt-10 grid max-w-md grid-cols-1 gap-8 lg:mx-0 lg:max-w-none lg:grid-cols-3">
          {tiers.map((tier) => (
            <div
              key={tier.id}
              data-featured={tier.featured ? 'true' : undefined}
              className="group/tier rounded-3xl p-8 ring-1 ring-gray-200 data-featured:bg-neutral-950 data-featured:ring-neutral-800 xl:p-10"
            >
              <h3
                id={`tier-${tier.id}`}
                className="text-lg/8 font-semibold text-gray-900 group-data-featured/tier:text-white"
              >
                {tier.name}
              </h3>
              <p className="mt-4 text-sm/6 text-gray-600 group-data-featured/tier:text-gray-300">
                {tier.description}
              </p>
              {typeof tier.price === 'string' ? (
                <p className="mt-6 text-4xl font-semibold tracking-tight text-gray-900 group-data-featured/tier:text-white">
                  {tier.price}
                </p>
              ) : (
                <>
                  <p className="mt-6 flex items-baseline gap-x-1 group-not-has-[[name=frequency][value=monthly]:checked]/tiers:hidden">
                    <span className="text-4xl font-semibold tracking-tight text-gray-900 group-data-featured/tier:text-white">
                      {tier.price.monthly}
                    </span>
                    <span className="text-sm/6 font-semibold text-gray-600 group-data-featured/tier:text-gray-300">
                      /月
                    </span>
                  </p>
                  <p className="mt-6 flex items-baseline gap-x-1 group-not-has-[[name=frequency][value=annually]:checked]/tiers:hidden">
                    <span className="text-4xl font-semibold tracking-tight text-gray-900 group-data-featured/tier:text-white">
                      {tier.price.annually}
                    </span>
                    <span className="text-sm/6 font-semibold text-gray-600 group-data-featured/tier:text-gray-300">
                      /年
                    </span>
                  </p>
                </>
              )}

              <a
                href="https://form.typeform.com/to/XIdO4iES"
                target="_blank"
                rel="noopener noreferrer"
                aria-describedby={`tier-${tier.id}`}
                className="mt-6 block w-full rounded-md bg-neutral-950 px-3 py-2 text-center text-sm/6 font-semibold text-white shadow-xs group-data-featured/tier:bg-white/10 group-data-featured/tier:text-white hover:bg-neutral-700 group-data-featured/tier:hover:bg-white/20 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 group-data-featured/tier:focus-visible:outline-white"
              >
                {tier.cta}
              </a>
              <ul
                role="list"
                className="mt-8 space-y-3 text-sm/6 text-gray-600 group-data-featured/tier:text-gray-300 xl:mt-10"
              >
                {tier.features.map((feature) => (
                  <li key={feature} className="flex gap-x-3">
                    <CheckIcon
                      aria-hidden="true"
                      className="h-6 w-5 flex-none text-neutral-950 group-data-featured/tier:text-white"
                    />
                    {feature}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </form>
  )
}
