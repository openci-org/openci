import { Container } from '@/components/container'
import { Footer } from '@/components/footer'
import { GradientBackground } from '@/components/gradient'
import { Navbar } from '@/components/navbar'
import { Heading } from '@/components/text'

export const metadata = {
  title: '特定商取引法に基づく表記',
  description: 'OpenCIの特定商取引法に基づく表記です。',
}

export default async function Commercial() {
  return (
    <main className="overflow-hidden">
      <GradientBackground />
      <Container>
        <Navbar />
      </Container>
      <div className="m-16" />
      <Body />
      <Footer />
    </main>
  )
}

function Body() {
  return (
    <Container>
      <section id="commercial" className="scroll-mt-8">
        <Heading as="div" className="mt-2 text-center">
          特定商取引法に基づく表記
        </Heading>
        <p className="mx-auto mt-8 max-w-xl text-sm text-gray-600">
          Last updated: {new Date().toLocaleDateString('ja-JP')}
        </p>
        <div className="mx-auto mt-16 mb-32 max-w-xl space-y-12">
          <dl>
            <dt className="text-sm font-semibold">販売事業者名 (Company Name)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">OpenCI株式会社</dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">代表責任者 (Representative)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">代表取締役 青木 正浩 (Masahiro Aoki)</dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">所在地 (Address)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              〒150-0043<br />
              東京都渋谷区道玄坂１丁目１０番８号 渋谷道玄坂東急ビル２Ｆ－Ｃ
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">電話番号 (Phone Number)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              080-6436-0562<br />
              <span className="mt-2 block">
                ※ サービスに関するお問い合わせは、原則として下記のメールアドレスまたはSlackコミュニティよりお願いいたします。
              </span>
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">メールアドレス (Email Address)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">support@openci.org</dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">サービス利用料金 (Pricing)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              利用料金は各プランの購入手続き画面、または<a href="/pricing" className="text-blue-600 underline hover:no-underline">料金プランページ</a>に表示されます。
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">商品代金以外に必要な料金 (Additional Fees)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              当サイトのページの閲覧、ソフトウェアの利用、サポート等に必要となるインターネット接続料金、通信料金等はお客様のご負担となります。
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">お支払方法 (Payment Methods)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              クレジットカード決済 (Stripe経由)、または各種プラットフォーム（Appleなど）が提供する決済方法。
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">代金の支払時期 (Payment Timing)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              各プランのサブスクリプション（定期課金）の契約開始時、および毎月の自動更新時に決済が行われます。
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">サービスの提供時期 (Delivery Time)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              アカウント登録および決済手続き（無料プランの場合は登録のみ）の完了後、すぐにご利用いただけます。
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">キャンセル・返品・解約 (Returns & Cancellations)</dt>
            <dd className="mt-4 text-sm/6 text-gray-600 space-y-4">
              <p>
                <strong>返品・キャンセルについて:</strong><br />
                提供するサービス（SaaSプラットフォーム）の性質上、購入確定後のお客様のご都合によるキャンセル、返品、ならびに途中解約に伴う日割りでの返金はお受けできません。
              </p>
              <p>
                <strong>解約（サブスクリプションの停止）について:</strong><br />
                ダッシュボードの設定ページ（またはご契約元のプラットフォーム設定画面）よりいつでも次回更新以降のサブスクリプションの解約が可能です。解約を行った場合でも、現在の請求期間（次回の自動更新日の前日）までは、引き続き有料プランのサービスをご利用いただけます。
              </p>
            </dd>
          </dl>
        </div>
      </section>
    </Container>
  )
}
