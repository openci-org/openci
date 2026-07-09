import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";
import { formatReleaseDate, getLatestReleaseNote, type ReleaseNote } from "../lib/releases";
import { BuildJobCardDemo } from "./build-job-card-demo";

const formUrl = "https://form.typeform.com/to/XIdO4iES";
const dashboardUrl = "https://dashboard.openci.org/";
const githubUrl = "https://github.com/openci-org/openci";
const macosDownloadUrl = "https://api.openci.org/updates/openci-org/openci/macos/latest";

const containerClass = "mx-auto w-full max-w-6xl px-6";
const cicdContainerClass = "mx-auto w-full max-w-5xl px-6";
const primaryButtonClass =
  "inline-flex items-center justify-center rounded-lg bg-neutral-950 px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-neutral-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500";
const secondaryButtonClass =
  "inline-flex items-center justify-center rounded-lg bg-white px-4 py-2.5 text-sm font-medium text-neutral-950 ring-1 ring-neutral-950/10 transition-colors hover:bg-neutral-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500";

type CicdCopy = {
  lang: "en" | "ja";
  homeHref: string;
  navPricing: string;
  navReleases?: string;
  releasesHref?: string;
  navDashboard: string;
  heroPrefix: string;
  heroTagline: string;
  heroDescription: ReactNode;
  heroCta: string;
  heroSubCta?: string;
  navDownloadMac?: string;
  demoLabel: string;
  pricingTitle: string;
  pricingSubtitle: string;
  supportTitle: string;
  supportDescription: string;
  supportCta: string;
  latestReleaseLabel?: string;
  latestReleaseCta?: string;
};

const cicdCopy: Record<"en" | "ja", CicdCopy> = {
  en: {
    lang: "en",
    homeHref: "/en/",
    navPricing: "Pricing",
    navDashboard: "Dashboard",
    heroPrefix: "CI/CD that's",
    heroTagline: "faster and cheaper.",
    heroDescription: (
      <>
        Blazing-fast builds on M4 Mac Mini. Up to 90% cheaper than GitHub Actions.
        <br />
        Your existing workflow files just work.
      </>
    ),
    heroCta: "Start for free",
    heroSubCta: "Download macOS App (.zip)",
    navDownloadMac: "macOS App",
    demoLabel: "OpenCI demo video",
    pricingTitle: "Simple pricing",
    pricingSubtitle: "Pay only for what you use. No hidden costs.",
    supportTitle: "Free setup support",
    supportDescription:
      "We'll help you set up your workflows and get your first build running in a free 15-minute video call.",
    supportCta: "Book a free call",
  },
  ja: {
    lang: "ja",
    homeHref: "/ja/",
    navPricing: "料金",
    navReleases: "更新情報",
    releasesHref: "/ja/releases/",
    navDashboard: "ダッシュボード",
    heroPrefix: "CI/CDを、",
    heroTagline: "もっと安く、もっと速く。",
    heroDescription: <>正しいツールで、正しい仕事を。</>,
    heroCta: "無料で始める",
    heroSubCta: "macOSアプリをダウンロード (.zip)",
    navDownloadMac: "macOSアプリ",
    demoLabel: "OpenCIのデモ動画",
    pricingTitle: "シンプルな料金体系",
    pricingSubtitle: "使った分だけ。隠れたコストなし。",
    supportTitle: "初回セットアップを無料でサポート",
    supportDescription:
      "15分のビデオ通話で、ワークフロー設定から最初のビルド成功まで一緒にお手伝いします。",
    supportCta: "無料通話を予約",
    latestReleaseLabel: "最新更新",
    latestReleaseCta: "詳しく見る",
  },
};

const cicdPricing = {
  en: [
    {
      icon: <GiftIcon />,
      name: "Free",
      price: "$0",
      unit: "",
      description: "100 free build minutes / month",
      features: ["Mac + Linux runners", "GitHub Actions compatible", "Free setup call (15 min)"],
    },
    {
      icon: <ChipIcon />,
      name: "Mac",
      price: "$0.007",
      unit: "/min",
      description: "Apple Silicon (M1/M2/M4) runner",
      features: [
        "4 vCPU / 8GB RAM",
        "Native iOS / macOS builds",
        "Up to 90% cheaper than GitHub Actions",
      ],
    },
    {
      icon: <TerminalIcon />,
      name: "Linux",
      price: "$0.0007",
      unit: "/min",
      description: "High-performance Linux runner (Ubuntu)",
      features: ["2 vCPU / 4GB RAM", "Docker support", "Up to 93% cheaper than GitHub Actions"],
    },
  ],
  ja: [
    {
      icon: <GiftIcon />,
      name: "Free",
      price: "¥0",
      unit: "",
      description: "毎月100分の無料ビルド",
      features: ["Mac + Linux 両対応", "GitHub Actions互換", "無料セットアップ通話 (15分)"],
    },
    {
      icon: <ChipIcon />,
      name: "Mac",
      price: "¥1",
      unit: "/分",
      description: "Apple Silicon (M1/M2/M4) ランナー",
      features: [
        "4 vCPU / 8GB RAM",
        "iOS / macOS ネイティブビルド",
        "GitHub Actionsより最大90%オフ",
      ],
    },
    {
      icon: <TerminalIcon />,
      name: "Linux",
      price: "¥0.1",
      unit: "/分",
      description: "高性能 Linux ランナー(Ubuntu)",
      features: ["2 vCPU / 4GB RAM", "Docker対応", "GitHub Actionsより最大93%オフ"],
    },
  ],
};

export function CicdPage({ lang }: { lang: "en" | "ja" }) {
  const copy = cicdCopy[lang];
  const latestRelease = lang === "ja" ? getLatestReleaseNote() : undefined;

  return (
    <div className="flex min-h-dvh flex-col bg-white text-neutral-950">
      <header className="sticky top-0 z-50 border-b border-neutral-950/6 bg-white/92 py-4 backdrop-blur-md">
        <div className={`${cicdContainerClass} flex items-center justify-between gap-6`}>
          <a
            href={copy.homeHref}
            className="text-[1.0625rem] font-semibold tracking-tight text-neutral-950 transition-opacity hover:opacity-70"
            aria-label={lang === "ja" ? "ホームページ" : "Homepage"}
          >
            OpenCI
          </a>
          <nav className="flex items-center gap-4 sm:gap-7" aria-label="Main navigation">
            <a
              href="#pricing"
              className="text-sm font-normal text-neutral-600 transition-colors hover:text-neutral-950"
            >
              {copy.navPricing}
            </a>
            {copy.navReleases && copy.releasesHref ? (
              <Link
                href={copy.releasesHref}
                className="text-sm font-normal text-neutral-600 transition-colors hover:text-neutral-950"
              >
                {copy.navReleases}
              </Link>
            ) : null}
            {copy.navDownloadMac ? (
              <a
                href={macosDownloadUrl}
                className="text-sm font-normal text-neutral-600 transition-colors hover:text-neutral-950"
              >
                {copy.navDownloadMac}
              </a>
            ) : null}
            <a
              href={githubUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="hidden text-sm font-normal text-neutral-600 transition-colors hover:text-neutral-950 sm:inline"
            >
              GitHub
            </a>
            <a
              href={dashboardUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={secondaryButtonClass}
            >
              {copy.navDashboard}
            </a>
          </nav>
        </div>
      </header>

      <main className="grow">
        <section className="py-16 text-center sm:pt-24">
          <div className={cicdContainerClass}>
            <h1 className="text-balance text-[1.75rem] font-medium tracking-tight text-neutral-950 sm:text-[2rem]">
              {copy.heroPrefix}
              <span className="mt-1 block text-balance text-5xl font-semibold tracking-[-0.04em] text-neutral-950 sm:text-6xl">
                {copy.heroTagline}
              </span>
            </h1>
            <p className="mx-auto mt-4 max-w-[42ch] text-pretty text-[1.0625rem] text-neutral-600">
              {copy.heroDescription}
            </p>
            <div className="mt-8 flex flex-col items-center gap-3">
              <a
                href={dashboardUrl}
                target="_blank"
                rel="noopener noreferrer"
                className={primaryButtonClass}
              >
                {copy.heroCta}
              </a>
              {copy.heroSubCta ? (
                <a
                  href={macosDownloadUrl}
                  className="text-xs text-neutral-500 hover:text-neutral-950 underline decoration-neutral-400 underline-offset-4 transition-colors"
                >
                  {copy.heroSubCta}
                </a>
              ) : null}
            </div>
          </div>
        </section>

        <section className="pt-8 pb-16 sm:pb-24">
          <div className={cicdContainerClass}>
            <BuildJobCardDemo lang={lang} />
          </div>
        </section>

        {latestRelease ? (
          <section className="pb-8 sm:pb-10">
            <div className={cicdContainerClass}>
              <LatestReleaseBar
                release={latestRelease}
                label={copy.latestReleaseLabel ?? "Latest update"}
                cta={copy.latestReleaseCta ?? "Read more"}
              />
            </div>
          </section>
        ) : null}

        <section id="pricing" className="border-t border-neutral-950/6 py-16">
          <div className={cicdContainerClass}>
            <h2 className="mx-auto max-w-[35ch] text-balance text-center text-[1.75rem] font-medium tracking-tight text-neutral-950">
              {copy.pricingTitle}
            </h2>
            <p className="mx-auto mt-2 max-w-[56ch] text-pretty text-center text-base text-neutral-600">
              {copy.pricingSubtitle}
            </p>
            <div className="mt-10 grid overflow-hidden rounded-2xl border border-neutral-950/6 bg-neutral-950/6 sm:grid-cols-3 sm:gap-px">
              {cicdPricing[lang].map((tier) => (
                <CicdPricingCard key={tier.name} {...tier} />
              ))}
            </div>
          </div>
        </section>

        <section className="py-16">
          <div className={cicdContainerClass}>
            <div className="rounded-2xl border border-neutral-950/6 bg-neutral-50 p-8 text-center sm:p-12">
              <div className="mb-4 flex justify-center text-neutral-950">
                <VideoIcon />
              </div>
              <h2 className="mx-auto max-w-[35ch] text-balance text-2xl font-medium tracking-tight text-neutral-950">
                {copy.supportTitle}
              </h2>
              <p className="mx-auto mt-3 max-w-[48ch] text-pretty text-base text-neutral-600">
                {copy.supportDescription}
              </p>
              <div className="mt-6">
                <a
                  href="https://cal.com/masahiro-aoki-r4rxdx/15min"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={secondaryButtonClass}
                >
                  {copy.supportCta}
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-neutral-950/6 py-8">
        <div className={cicdContainerClass}>
          <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
            <a
              href={copy.homeHref}
              className="text-[1.0625rem] font-semibold tracking-tight text-neutral-950"
            >
              OpenCI
            </a>
            <nav className="flex flex-wrap justify-center gap-6" aria-label="Footer navigation">
              <a
                href={githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm font-normal text-neutral-500 transition-colors hover:text-neutral-950"
              >
                GitHub
              </a>
              {copy.navDownloadMac ? (
                <a
                  href={macosDownloadUrl}
                  className="text-sm font-normal text-neutral-500 transition-colors hover:text-neutral-950"
                >
                  {copy.navDownloadMac}
                </a>
              ) : null}
              <a
                href="/studio/"
                className="text-sm font-normal text-neutral-500 transition-colors hover:text-neutral-950"
              >
                OpenCI Studio
              </a>
              <a
                href="https://x.com/ma_freud"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm font-normal text-neutral-500 transition-colors hover:text-neutral-950"
              >
                X / Twitter
              </a>
            </nav>
          </div>
          <p className="mt-6 text-center text-[0.8125rem] text-neutral-400">
            © OpenCI, Inc. {new Date().getFullYear()}
          </p>
        </div>
      </footer>
    </div>
  );
}

function CicdPricingCard({
  icon,
  name,
  price,
  unit,
  description,
  features,
}: {
  icon: ReactNode;
  name: string;
  price: string;
  unit: string;
  description: string;
  features: string[];
}) {
  return (
    <article className="bg-white p-7">
      <div className="flex flex-wrap items-center gap-2">
        <span className="flex shrink-0 items-center text-neutral-600" aria-hidden="true">
          {icon}
        </span>
        <h3 className="text-base font-semibold tracking-tight text-neutral-950">{name}</h3>
      </div>
      <div className="mt-3 tabular-nums">
        <span className="text-3xl font-semibold tracking-tight text-neutral-950">{price}</span>
        {unit ? (
          <span className="text-[0.8125rem] font-normal text-neutral-500">{unit}</span>
        ) : null}
      </div>
      <p className="mt-1.5 text-pretty text-sm/6 text-neutral-600">{description}</p>
      <ul role="list" className="mt-5 space-y-2">
        {features.map((feature) => (
          <li key={feature} className="flex items-baseline gap-2 text-sm/6 text-neutral-700">
            <CheckIcon />
            {feature}
          </li>
        ))}
      </ul>
    </article>
  );
}

function LatestReleaseBar({
  release,
  label,
  cta,
}: {
  release: ReleaseNote;
  label: string;
  cta: string;
}) {
  return (
    <Link
      href={`/ja/releases/${release.slug}/`}
      className="group block border-y border-neutral-950/8 py-5 transition-colors hover:border-neutral-950/16"
    >
      <div className="grid min-w-0 gap-4 sm:grid-cols-[9.5rem_1fr_auto] sm:items-center">
        <div>
          <div className="text-sm font-medium text-neutral-500 sm:text-[0.8125rem]">{label}</div>
          <time
            dateTime={release.date}
            className="mt-1 block text-sm text-neutral-500 sm:text-[0.8125rem]"
          >
            {formatReleaseDate(release.date)}
          </time>
        </div>
        <div className="min-w-0">
          <h2 className="text-xl font-medium text-neutral-950 sm:text-lg">{release.title}</h2>
          <p className="mt-1 max-w-[56ch] break-words text-pretty text-base/7 text-neutral-600 sm:text-sm/6">
            {release.summary}
          </p>
        </div>
        <div className="text-base font-medium text-neutral-950 sm:text-sm">{cta}</div>
      </div>
    </Link>
  );
}

const services = [
  {
    title: "iOS+Androidアプリ開発 (Flutter)",
    description:
      "Googleが開発した世界で最も使用されているクロスプラットフォームフレームワークの1つである、Flutterを使用し、アプリ開発を行います。毎月の稼働時間を決め、その中で稼働時間に応じて時給で請求します。弊社代表青木が責任を持って開発をします。外部委託はいたしません。",
  },
  {
    title: "Flutter開発の技術支援 (技術顧問)",
    description:
      "弊社代表青木が、Flutter開発の技術顧問として、お客様のプロジェクトに参画し、技術的な課題を解決します。チーム規模に応じて毎月一定額の請求を行います。質問はSlackやHuddleでお受けします。回数は無制限です。また毎週の定例に参加します。東京近辺であれば、現地参加も可能です。",
  },
  {
    title: "CI/CDの導入支援",
    description:
      "お客様のプロジェクトに、CI/CDを導入し、ビルド、テスト、リリースを自動化します。また、各種テストコードの追加も必要に応じて行います。",
  },
  {
    title: "AI開発の技術支援 (技術顧問)",
    description:
      "弊社代表青木が、AI開発の技術顧問として、お客様のプロジェクトに参画し、技術力・デリバリスピードの改善を行います。こちらもFlutter開発の技術支援と同様に、チーム規模に応じて毎月一定額の請求を行います。質問はSlackやHuddleでお受けします。回数は無制限です。",
  },
];

const clients = [
  {
    label: "技術顧問 · 継続2年以上",
    title: "大手外資系企業 / 東証プライム上場企業",
    description:
      "モバイルアプリケーションの技術顧問として、アーキテクチャ設計や開発チームの体制構築を支援。新技術のR&D・技術検証も担当し、プロダクトの技術的な意思決定をサポートしています。",
    longTerm: true,
  },
  {
    label: "技術顧問 · 継続2年以上",
    title: "スポーツテック系スタートアップ",
    description:
      "甲子園常連の強豪校や大手企業をクライアントに持つスポーツテック企業の技術顧問。アスリート向けプラットフォームの設計支援および開発を行っています。",
    longTerm: true,
  },
  {
    label: "技術顧問",
    title: "エンターテインメント系スタートアップ",
    description:
      "大手芸能プロダクションと連携し、著名アーティストのファン向けチケットシステムの技術顧問を担当。設計レビューに加え、一部開発にも携わっています。",
  },
  {
    label: "技術顧問",
    title: "ヘルスケア系スタートアップ",
    description:
      "パーソナルコーチング領域のモバイルアプリケーション開発における技術顧問。アーキテクチャ設計やUI/UX改善のアドバイスを提供しています。",
  },
];

const studioPricing = [
  {
    name: "アプリ開発 (Flutter)",
    price: "800,000円〜",
    period: "/月",
    description: "Flutterを使用したアプリ開発を行います。",
    features: ["定例参加", "週1-2回のオフィスでの作業", "Flutterの開発", "コードレビュー"],
    unavailable: true,
    unavailableNote: "現在新規募集を停止しています。今後のご相談はお気軽にお問い合わせください。",
  },
  {
    name: "Flutter開発の技術支援 (技術顧問)",
    price: "300,000円〜",
    period: "/月",
    description: "Flutter開発の技術支援を行います。",
    features: ["定例参加 (現地参加可)", "無制限の質問 (チャットおよび通話)", "コードレビュー"],
  },
  {
    name: "オーダーメイド",
    price: "カスタム",
    description: "上記プランに当てはまらないご要望がありましたら、お気軽にお問い合わせください。",
    features: [
      "柔軟にご要望にお応え可能",
      "アプリ以外の開発",
      "AI開発の技術支援",
      "CI/CDの導入支援",
      "テストコードの追加",
    ],
    featured: true,
  },
];

export function StudioHomePage() {
  return (
    <StudioShell>
      <StudioHero />
      <StudioServices />
      <StudioTestimonial />
      <StudioClients />
      <StudioPricing />
      <StudioContact />
    </StudioShell>
  );
}

export function StudioAboutPage() {
  return (
    <StudioShell>
      <StudioAboutContent />
      <StudioContact />
    </StudioShell>
  );
}

function StudioShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-dvh flex-col bg-white text-neutral-950">
      <StudioHeader />
      <main className="grow">{children}</main>
      <StudioFooter />
    </div>
  );
}

function StudioHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-neutral-950/6 bg-white/92 py-4 backdrop-blur-md">
      <div className={`${containerClass} flex items-center justify-between gap-6`}>
        <a
          href="/studio/"
          className="text-lg font-semibold tracking-tight text-neutral-950 transition-opacity hover:opacity-70"
          aria-label="Homepage"
        >
          OpenCI Studio
        </a>
        <nav className="flex items-center gap-5 sm:gap-8" aria-label="Studio navigation">
          <a
            href="/studio/about/"
            className="text-sm font-normal text-neutral-600 transition-colors hover:text-neutral-950"
          >
            会社概要
          </a>
          <a
            href={formUrl}
            target="_blank"
            rel="noopener noreferrer"
            className={secondaryButtonClass}
          >
            お問い合わせ
          </a>
        </nav>
      </div>
    </header>
  );
}

function StudioHero() {
  return (
    <section className="py-16 sm:py-28">
      <div className={containerClass}>
        <h1 className="max-w-[20ch] text-balance text-5xl font-medium tracking-[-0.03em] text-neutral-950 sm:text-6xl">
          ビジネスを
          <br />
          成功に導くアプリを創る。
        </h1>
        <p className="mt-5 max-w-[48ch] text-pretty text-[1.0625rem] text-neutral-600">
          OpenCI
          Studioは、弊社代表青木の長年の経験・技術を活かして、ビジネスを成功に導くアプリを開発します。
          <br />
          アプリ開発において、最も大切なのは技術ではなく、ビジネスが成功するかどうか。ここに重点を置き、開発、技術支援、コンサルティングを行います。
        </p>
        <div className="mt-7">
          <a
            href={formUrl}
            target="_blank"
            rel="noopener noreferrer"
            className={primaryButtonClass}
          >
            お問い合わせ
          </a>
        </div>
      </div>
    </section>
  );
}

function StudioServices() {
  return (
    <section className="border-t border-neutral-950/6 py-20">
      <div className={containerClass}>
        <SectionIntro
          eyebrow="提供サービス"
          title="個人開発規模から大規模まで、なんでもお任せください。"
        >
          OpenCI
          Studioは、数人規模の会社から大手外資系企業まで、様々な規模のプロジェクトに参画し、結果を残してきました。
        </SectionIntro>
        <dl className="mt-10 grid overflow-hidden rounded-2xl border border-neutral-950/6 bg-neutral-950/6 sm:grid-cols-2 sm:gap-px">
          {services.map((service) => (
            <div key={service.title} className="bg-white p-7">
              <dt className="text-base font-semibold tracking-tight text-neutral-950">
                {service.title}
              </dt>
              <dd className="mt-2.5 text-pretty text-sm/7 text-neutral-600">
                {service.description}
              </dd>
            </div>
          ))}
        </dl>
      </div>
    </section>
  );
}

function StudioTestimonial() {
  return (
    <section className="border-t border-neutral-950/6 py-20">
      <div className={containerClass}>
        <figure>
          <blockquote className="relative max-w-[40ch] text-pretty text-2xl font-normal italic tracking-tight text-neutral-950 before:absolute before:inline before:-translate-x-full before:content-['“'] after:inline after:content-['”'] sm:text-[1.625rem]">
            <p>
              OpenCI
              Studioのサポートにより、停滞していたプロジェクトが劇的に改善しました。技術的な課題の解決だけでなく、チーム全体のスキルアップを実現し、メンバーのモチベーション向上にも大きく貢献していただきました。
            </p>
          </blockquote>
          <figcaption className="mt-5 text-sm text-neutral-500">
            — 非公開プロジェクト(大手外資系企業) · 技術顧問として参画
          </figcaption>
        </figure>
      </div>
    </section>
  );
}

function StudioClients() {
  return (
    <section className="border-t border-neutral-950/6 py-20">
      <div className={containerClass}>
        <SectionIntro eyebrow="実績" title="長期的なパートナーシップを大切にしています。">
          お客様との信頼関係を第一に考え、多くのプロジェクトで継続的にご支援しています。以下は現在進行中の案件の一部です。
        </SectionIntro>
        <div className="mt-10 grid overflow-hidden rounded-2xl border border-neutral-950/6 bg-neutral-950/6 sm:grid-cols-2 sm:gap-px">
          {clients.map((client) => (
            <article
              key={client.title}
              className={`bg-white p-7 transition-colors hover:bg-neutral-50 ${client.longTerm ? "border-l-3 border-neutral-950" : ""}`}
            >
              <div className="mb-3 inline-flex rounded-full bg-neutral-100 px-2.5 py-1 text-[0.6875rem] font-medium text-neutral-600">
                {client.label}
              </div>
              <h3 className="text-base font-semibold tracking-tight text-neutral-950">
                {client.title}
              </h3>
              <p className="mt-2 text-pretty text-sm/7 text-neutral-600">{client.description}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

function StudioPricing() {
  return (
    <section className="border-t border-neutral-950/6 py-20">
      <div className={containerClass}>
        <div>
          <h2 className="max-w-[35ch] text-balance text-3xl font-medium tracking-tight text-neutral-950">
            料金表
          </h2>
          <p className="mt-2 max-w-[56ch] text-pretty text-[0.9375rem] text-neutral-600">
            価格は全て税抜きです。最低契約期間は3ヶ月、毎月最低稼動時間は100時間です。
          </p>
        </div>
        <div className="mt-10 grid overflow-hidden rounded-2xl border border-neutral-950/6 bg-neutral-950/6 lg:grid-cols-3 lg:gap-px">
          {studioPricing.map((tier) => (
            <article
              key={tier.name}
              className={`flex flex-col bg-white p-7 ${tier.featured ? "lg:bg-neutral-50" : ""} ${tier.unavailable ? "opacity-55" : ""}`}
            >
              {tier.unavailable ? (
                <div className="mb-3 inline-flex w-fit rounded-full bg-neutral-100 px-2.5 py-1 text-[0.6875rem] font-medium text-neutral-600">
                  現在募集停止中
                </div>
              ) : null}
              <h3 className="text-base font-semibold tracking-tight text-neutral-950">
                {tier.name}
              </h3>
              <p className="mt-2 text-pretty text-sm/6 text-neutral-600">{tier.description}</p>
              <div className="mt-3 tabular-nums text-3xl font-semibold tracking-tight text-neutral-950">
                {tier.price}
                {tier.period ? (
                  <span className="text-[0.8125rem] font-normal text-neutral-500">
                    {tier.period}
                  </span>
                ) : null}
              </div>
              <ul role="list" className="mt-5 grow space-y-2">
                {tier.features.map((feature) => (
                  <li
                    key={feature}
                    className="flex items-baseline gap-2 text-sm/6 text-neutral-700"
                  >
                    <CheckIcon />
                    {feature}
                  </li>
                ))}
              </ul>
              {tier.unavailableNote ? (
                <p className="mt-3 text-pretty text-[0.8125rem] italic text-neutral-500">
                  {tier.unavailableNote}
                </p>
              ) : null}
              <a
                href={formUrl}
                target="_blank"
                rel="noopener noreferrer"
                className={`${secondaryButtonClass} mt-5 w-full`}
              >
                {tier.unavailable
                  ? "ご相談はこちら"
                  : tier.name === "オーダーメイド"
                    ? "お問い合わせ"
                    : "申し込む"}
              </a>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

function StudioContact() {
  return (
    <section className="border-t border-neutral-950/6 py-20">
      <div className={containerClass}>
        <div className="rounded-2xl border border-neutral-950/6 bg-neutral-50 p-6 sm:p-10">
          <h2 className="max-w-[30ch] text-balance text-2xl font-medium tracking-tight text-neutral-950 sm:text-[1.75rem]">
            お気軽にご相談ください。
            <br />
            何度相談していただいても、
            <br />
            相談料は無料です。
          </h2>
          <div className="mt-5">
            <a
              href={formUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={secondaryButtonClass}
            >
              お問い合わせ
            </a>
          </div>
          <div className="mt-7 border-t border-neutral-950/6 pt-7">
            <h3 className="mb-2.5 text-[0.8125rem] font-semibold text-neutral-950">会社情報</h3>
            <div className="space-y-1 text-[0.8125rem] text-neutral-600">
              <p>
                <strong className="font-semibold text-neutral-700">OpenCI株式会社</strong>
              </p>
              <p>東京都渋谷区道玄坂1丁目10番8号渋谷道玄坂東急ビル2F-C</p>
              <p>法人番号: 8011001159197</p>
              <p>資本金: 100万円</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function StudioAboutContent() {
  return (
    <>
      <section className="py-16 sm:pt-28">
        <div className={containerClass}>
          <div className="mb-3 text-[0.8125rem] font-medium text-neutral-500">会社概要</div>
          <h1 className="text-balance text-4xl font-medium tracking-tight text-neutral-950">
            代表挨拶
          </h1>
          <p className="mt-3 max-w-[48ch] text-pretty text-[1.0625rem] text-neutral-600">
            アプリ開発を通じて、よりよい世界を創る。
          </p>
          <div className="mt-8 max-w-2xl space-y-5 text-pretty text-base/8 text-neutral-700">
            <p>
              初めまして。OpenCI（オープンシーアイ）株式会社の代表取締役社長、青木正浩です。
              <br />
              この度は弊社のサイトをご覧いただき、ありがとうございます。
            </p>
            <p>
              国際基督教大学（ICU）を卒業後、2019年8月にゲーマー向けマッチングアプリの共同創業者兼CTOとしてアプリ開発のキャリアをスタートしました。VCからの資金調達を経て約3年間プロダクト開発に携わった後、いくつかのプロジェクトを経験し、日本IBMに入社。大手銀行や大手海運企業のアプリ開発に従事しました。
            </p>
            <p>
              これらの経験と並行して、Flutterコミュニティでも積極的に活動してきました。FlutterCon（ドイツ・ベルリン）、Flutter
              Connection（フランス・パリ）、FlutterFormosa（台湾・台北）、State of Open
              Con（イギリス・ロンドン）での登壇のほか、Google公認のFlutterミートアップ「Flutter
              Tokyo」のオーガナイザー、日本最大級のFlutterカンファレンス「FlutterKaigi」の運営メンバーとしても活動しています。
            </p>
            <p>
              こうした開発の現場での経験を通じて、既存のCI/CDサービスに大きな課題があることを実感しました。使いづらさと高額な料金により、多くのプロジェクトがCI/CDを十分に活用できていません。誰もが使いやすいCI/CDを届けたい。その想いからIBMを退職し、OpenCI株式会社を設立しました。
            </p>
            <p>
              OpenCIでは、OSSとしてCI/CDプラットフォームを開発しています。すべての開発者が効率的に開発できる環境を提供することが私たちの目標です。
              <br />
              ご興味のある方は、
              <a
                href={githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="border-b border-neutral-950/25 text-neutral-950 transition-colors hover:border-neutral-950"
              >
                OpenCIのGitHub
              </a>
              をご覧ください。
            </p>
            <p>
              また、OpenCI
              Studio（以下Studio）では、これまで培ってきたFlutter開発の技術と経験を活かし、技術支援サービスを提供しています。小規模なプロジェクトから大規模なエンタープライズアプリまで幅広くサポートいたします。
            </p>
            <p>
              Studioでは単なる技術支援にとどまらず、CTOとしての経験、スタートアップでの事業立ち上げ、大企業でのプロジェクト推進の知見を総合的に活かし、お客様のビジネスをサポートします。技術的な課題解決はもちろん、チーム体制の構築や開発プロセスの改善まで、ビジネスの成功に必要なあらゆる面でお手伝いいたします。
            </p>
          </div>
        </div>
      </section>

      <section className="border-t border-neutral-950/6 py-14">
        <div className={containerClass}>
          <h2 className="mb-6 text-lg font-semibold text-neutral-950">代表者</h2>
          <article className="max-w-[300px] overflow-hidden rounded-2xl border border-neutral-950/6">
            <Image
              src="/images/team/masahiro-aoki.jpg"
              alt="Masahiro Aoki - OpenCI Studio 代表取締役"
              width={600}
              height={600}
              className="aspect-square w-full object-cover"
            />
            <div className="p-5">
              <h3 className="text-base font-semibold text-neutral-950">
                Masahiro Aoki (青木 正浩)
              </h3>
              <p className="mt-0.5 text-[0.8125rem] text-neutral-500">Founder / CEO</p>
            </div>
          </article>
        </div>
      </section>
    </>
  );
}

function StudioFooter() {
  return (
    <footer className="border-t border-neutral-950/6 py-10">
      <div className={containerClass}>
        <div className="grid gap-8 sm:grid-cols-2">
          <FooterColumn title="会社情報" links={[{ label: "会社概要", href: "/studio/about/" }]} />
          <FooterColumn
            title="SNS"
            links={[
              { label: "X / Twitter", href: "https://x.com/ma_freud" },
              { label: "LinkedIn", href: "https://www.linkedin.com/in/masahiro-aoki-b68905163/" },
              { label: "GitHub", href: "https://github.com/openci-org" },
            ]}
          />
        </div>
        <div className="mt-10 flex flex-wrap items-center justify-between gap-4 border-t border-neutral-950/6 pt-7">
          <a
            href="/studio/"
            className="text-lg font-semibold tracking-tight text-neutral-950"
            aria-label="Homepage"
          >
            OpenCI Studio
          </a>
          <p className="text-[0.8125rem] text-neutral-400">
            © OpenCI株式会社 {new Date().getFullYear()}
          </p>
        </div>
      </div>
    </footer>
  );
}

function FooterColumn({
  title,
  links,
}: {
  title: string;
  links: { label: string; href: string }[];
}) {
  return (
    <div>
      <h4 className="mb-3.5 text-[0.8125rem] font-medium text-neutral-950">{title}</h4>
      <ul role="list" className="space-y-1.5">
        {links.map((link) => {
          const external = link.href.startsWith("http");
          return (
            <li key={link.href}>
              <a
                href={link.href}
                target={external ? "_blank" : undefined}
                rel={external ? "noopener noreferrer" : undefined}
                className="text-sm font-normal text-neutral-500 transition-colors hover:text-neutral-950"
              >
                {link.label}
              </a>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function SectionIntro({
  eyebrow,
  title,
  children,
}: {
  eyebrow: string;
  title: string;
  children: ReactNode;
}) {
  return (
    <div>
      <div className="mb-3 text-[0.8125rem] font-medium text-neutral-500">{eyebrow}</div>
      <h2 className="max-w-[35ch] text-balance text-3xl font-medium tracking-tight text-neutral-950">
        {title}
      </h2>
      <p className="mt-3 max-w-[56ch] text-pretty text-base text-neutral-600">{children}</p>
    </div>
  );
}

function CheckIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 16 16"
      fill="currentColor"
      aria-hidden="true"
      className="relative top-0.5 shrink-0 text-green-600"
    >
      <path
        fillRule="evenodd"
        d="M12.416 3.376a.75.75 0 0 1 .208 1.04l-5 7.5a.75.75 0 0 1-1.154.114l-3-3a.75.75 0 0 1 1.06-1.06l2.353 2.353 4.493-6.74a.75.75 0 0 1 1.04-.207Z"
        clipRule="evenodd"
      />
    </svg>
  );
}

function VideoIcon() {
  return (
    <svg
      width="28"
      height="28"
      viewBox="0 0 24 24"
      fill="none"
      strokeWidth="1.5"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25Z"
      />
    </svg>
  );
}

function GiftIcon() {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      strokeWidth="1.5"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M20.625 11.505v8.25a1.5 1.5 0 0 1-1.5 1.5H4.875a1.5 1.5 0 0 1-1.5-1.5v-8.25m8.25-6.375A2.625 2.625 0 1 0 9 7.755h2.625m0-2.625v2.625m0-2.625a2.625 2.625 0 1 1 2.625 2.625h-2.625m0 0v13.5M3 11.505h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.622-.504-1.125-1.125-1.125H3c-.621 0-1.125.503-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z"
      />
    </svg>
  );
}

function ChipIcon() {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      strokeWidth="1.5"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 0 0 2.25-2.25V6.75a2.25 2.25 0 0 0-2.25-2.25H6.75A2.25 2.25 0 0 0 4.5 6.75v10.5a2.25 2.25 0 0 0 2.25 2.25Zm.75-12h9v9h-9v-9Z"
      />
    </svg>
  );
}

function TerminalIcon() {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      strokeWidth="1.5"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="m6.75 7.5 3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0 0 21 18V6a2.25 2.25 0 0 0-2.25-2.25H5.25A2.25 2.25 0 0 0 3 6v12a2.25 2.25 0 0 0 2.25 2.25Z"
      />
    </svg>
  );
}
