import Link from "next/link";
import Image from "next/image";
import type { ReactNode } from "react";
import {
  findReleaseNote,
  formatReleaseDate,
  releaseNotes,
  type ReleaseContentBlock,
  type ReleaseNote,
} from "../lib/releases";

const dashboardUrl = "https://dashboard.openci.org/";
const githubUrl = "https://github.com/openci-org/openci";
const containerClass = "mx-auto w-full max-w-5xl px-6";

export function ReleaseIndexPage() {
  const [featuredRelease, ...archiveReleases] = releaseNotes;

  return (
    <ReleaseShell>
      <section className="py-14 sm:py-20">
        <div className={containerClass}>
          <div className="grid gap-8 border-b border-neutral-950/8 pb-10 sm:grid-cols-[1fr_16rem] sm:items-end">
            <div>
              <div className="mb-3 text-[0.8125rem] font-medium text-neutral-500">
                Release Notes
              </div>
              <h1 className="max-w-[30ch] text-balance text-4xl font-medium text-neutral-950 sm:text-5xl">
                毎週金曜日のOpenCI更新情報。
              </h1>
              <p className="mt-4 max-w-[56ch] text-pretty text-base/8 text-neutral-600 sm:text-[1.0625rem]">
                プロダクト改善、ランナー更新、ダッシュボードの変更を短くまとめています。Markdownで書いた更新情報を静的ページとして公開します。
              </p>
            </div>
            <div className="border-t border-neutral-950/8 pt-5 sm:border-t-0 sm:pt-0">
              <div className="text-sm font-medium text-neutral-950">毎週金曜日に公開</div>
              <p className="mt-2 text-base/7 text-neutral-600 sm:text-sm/6">
                小さな改善も、導入検討中のチームが追いやすい粒度で残します。
              </p>
            </div>
          </div>

          {featuredRelease ? <FeaturedRelease release={featuredRelease} /> : null}

          <div className="mt-12">
            <h2 className="text-sm font-medium text-neutral-950">過去の更新</h2>
            <div className="mt-5 divide-y divide-neutral-950/8 border-y border-neutral-950/8">
              {archiveReleases.map((release) => (
                <ReleaseListItem key={release.slug} release={release} />
              ))}
            </div>
          </div>
        </div>
      </section>
    </ReleaseShell>
  );
}

export function ReleaseDetailPage({ slug }: { slug: string }) {
  const release = findReleaseNote(slug);

  if (!release) {
    return null;
  }

  return (
    <ReleaseShell>
      <article className="py-16 sm:py-20">
        <div className={containerClass}>
          <Link
            href="/ja/releases/"
            className="text-sm font-medium text-neutral-500 transition-colors hover:text-neutral-950"
          >
            更新情報一覧へ戻る
          </Link>

          <header className="mt-8 max-w-3xl">
            <div className="flex flex-wrap items-center gap-2 text-[0.8125rem] text-neutral-500">
              <time dateTime={release.date}>{formatReleaseDate(release.date)}</time>
              <span aria-hidden="true">/</span>
              <span>{release.label}</span>
            </div>
            <h1 className="mt-4 max-w-[30ch] text-pretty text-4xl font-medium text-neutral-950 sm:text-5xl">
              {release.title}
            </h1>
            <p className="mt-5 max-w-[56ch] text-pretty text-base/8 text-neutral-600 sm:text-[1.0625rem]">
              {release.summary}
            </p>
            <TagList tags={release.tags} className="mt-6" />
          </header>

          <section className="mt-12 border-y border-neutral-950/8 py-7">
            <div className="grid gap-6 lg:grid-cols-[12rem_1fr]">
              <div>
                <h2 className="text-base font-medium text-neutral-950 sm:text-sm">
                  今週のハイライト
                </h2>
                <p className="mt-2 text-base/7 text-neutral-600 sm:text-sm/6">
                  主な変更を、導入判断に関係する粒度でまとめています。
                </p>
              </div>
              <dl className="grid divide-y divide-neutral-950/8 sm:grid-cols-3 sm:divide-x sm:divide-y-0">
                {release.highlights.map((highlight, index) => (
                  <div
                    key={highlight.label}
                    className="py-5 first:pt-0 last:pb-0 sm:px-5 sm:py-0 sm:first:pl-0 sm:last:pr-0"
                  >
                    <dt className="flex items-baseline gap-3 text-base font-medium text-neutral-950 sm:text-sm">
                      <span className="text-sm tabular-nums text-neutral-400 sm:text-[0.8125rem]">
                        {String(index + 1).padStart(2, "0")}
                      </span>
                      {highlight.label}
                    </dt>
                    <dd className="mt-2 text-base/7 text-neutral-600 sm:text-sm/6">
                      {highlight.description}
                    </dd>
                  </div>
                ))}
              </dl>
            </div>
          </section>

          <div className="mt-12 max-w-[65ch] space-y-10">
            {release.sections.map((section) => (
              <section key={section.title}>
                <h2 className="text-2xl font-medium text-neutral-950">{section.title}</h2>
                <div className="mt-3 space-y-4">
                  {section.body.map((block, index) => (
                    <ReleaseContent key={`${section.title}-${index}`} block={block} />
                  ))}
                </div>
              </section>
            ))}
          </div>
        </div>
      </article>
    </ReleaseShell>
  );
}

function ReleaseContent({ block }: { block: ReleaseContentBlock }) {
  if (block.type === "image") {
    return (
      <figure className="space-y-2">
        <div className="relative aspect-[16/10] overflow-hidden rounded-lg border border-neutral-950/8 bg-neutral-50">
          <Image
            src={block.src}
            alt={block.alt}
            fill
            sizes="(min-width: 1024px) 65ch, calc(100vw - 3rem)"
            className="object-contain"
          />
        </div>
        {block.caption ? (
          <figcaption className="text-sm/6 text-neutral-500">{block.caption}</figcaption>
        ) : null}
      </figure>
    );
  }

  if (block.type === "video") {
    return (
      <figure className="space-y-2">
        <video
          controls
          playsInline
          preload="metadata"
          className="w-full overflow-hidden rounded-lg border border-neutral-950/8 bg-neutral-950"
        >
          <source src={block.src} />
        </video>
        {block.caption ? (
          <figcaption className="text-sm/6 text-neutral-500">{block.caption}</figcaption>
        ) : null}
      </figure>
    );
  }

  return <p className="text-pretty text-base/8 text-neutral-700">{block.text}</p>;
}

function ReleaseShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-dvh flex-col bg-white text-neutral-950">
      <header className="sticky top-0 z-50 border-b border-neutral-950/6 bg-white/92 py-4 backdrop-blur-md">
        <div className={`${containerClass} flex items-center justify-between gap-5`}>
          <Link
            href="/ja/"
            className="text-[1.0625rem] font-semibold text-neutral-950 transition-opacity hover:opacity-70"
            aria-label="ホームページ"
          >
            OpenCI
          </Link>
          <nav className="hidden items-center gap-7 sm:flex" aria-label="Release navigation">
            <Link
              href="/ja/#pricing"
              className="text-sm font-normal text-neutral-600 transition-colors hover:text-neutral-950"
            >
              料金
            </Link>
            <Link
              href="/ja/releases/"
              className="text-sm font-normal text-neutral-600 transition-colors hover:text-neutral-950"
            >
              更新情報
            </Link>
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
              className="hidden items-center justify-center rounded-lg bg-white px-4 py-2.5 text-sm font-medium text-neutral-950 ring-1 ring-neutral-950/10 transition-colors hover:bg-neutral-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 sm:inline-flex"
            >
              ダッシュボード
            </a>
          </nav>
        </div>
      </header>
      <main className="grow">{children}</main>
      <footer className="border-t border-neutral-950/6 py-8">
        <div className={containerClass}>
          <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
            <Link href="/ja/" className="text-[1.0625rem] font-semibold text-neutral-950">
              OpenCI
            </Link>
            <nav className="flex flex-wrap justify-center gap-6" aria-label="Footer navigation">
              <Link
                href="/ja/releases/"
                className="text-sm font-normal text-neutral-500 transition-colors hover:text-neutral-950"
              >
                更新情報
              </Link>
              <a
                href={githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm font-normal text-neutral-500 transition-colors hover:text-neutral-950"
              >
                GitHub
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

function FeaturedRelease({ release }: { release: ReleaseNote }) {
  return (
    <Link
      href={`/ja/releases/${release.slug}/`}
      className="group block border-b border-neutral-950/8 py-10"
    >
      <article className="grid gap-6 sm:grid-cols-[11rem_1fr_auto] sm:items-start">
        <div className="text-base/7 text-neutral-500 sm:text-sm/6">
          <div className="font-medium text-neutral-950">最新</div>
          <time dateTime={release.date} className="mt-1 block">
            {formatReleaseDate(release.date)}
          </time>
        </div>
        <div>
          <h2 className="max-w-[36ch] text-2xl font-medium text-neutral-950 group-hover:underline group-hover:decoration-neutral-950/30 group-hover:underline-offset-4">
            {release.title}
          </h2>
          <p className="mt-3 max-w-[60ch] text-pretty text-base/8 text-neutral-600">
            {release.summary}
          </p>
          <TagList tags={release.tags} className="mt-5" />
        </div>
        <div className="text-base font-medium text-neutral-950 sm:text-sm">読む</div>
      </article>
    </Link>
  );
}

function ReleaseListItem({ release }: { release: ReleaseNote }) {
  return (
    <article className="grid gap-4 py-7 sm:grid-cols-[11rem_1fr]">
      <div className="text-base/7 text-neutral-500 sm:text-sm/6">
        <time dateTime={release.date}>{formatReleaseDate(release.date)}</time>
      </div>
      <div>
        <Link href={`/ja/releases/${release.slug}/`} className="group block">
          <h2 className="text-xl font-medium text-neutral-950 group-hover:underline group-hover:decoration-neutral-950/30 group-hover:underline-offset-4">
            {release.title}
          </h2>
          <p className="mt-2 max-w-[60ch] text-pretty text-base/7 text-neutral-600 sm:text-sm/7">
            {release.summary}
          </p>
        </Link>
        <TagList tags={release.tags} className="mt-4" />
      </div>
    </article>
  );
}

function TagList({ tags, className }: { tags: string[]; className?: string }) {
  return (
    <div className={`flex flex-wrap gap-2 ${className ?? ""}`}>
      {tags.map((tag) => (
        <span
          key={tag}
          className="rounded-full bg-neutral-100 px-2.5 py-1 text-sm font-medium text-neutral-600 sm:text-[0.75rem]"
        >
          {tag}
        </span>
      ))}
    </div>
  );
}
