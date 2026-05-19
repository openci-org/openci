import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { ReleaseDetailPage } from '../../../../../components/releases';
import { findReleaseNote, releaseNotes } from '../../../../../lib/releases';
import { createPageMetadata } from '../../../../../lib/seo';

type Props = {
  params: Promise<{
    slug: string;
  }>;
};

export function generateStaticParams() {
  return releaseNotes.map((release) => ({
    slug: release.slug,
  }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const release = findReleaseNote(slug);

  if (!release) {
    return createPageMetadata({
      title: '更新情報 — OpenCI',
      description: 'OpenCIのプロダクト改善、ランナー更新、ダッシュボード変更を毎週金曜日にまとめてお届けします。',
      path: '/ja/releases/',
    });
  }

  return createPageMetadata({
    title: `${release.title} — OpenCI`,
    description: release.summary,
    path: `/ja/releases/${release.slug}/`,
    image: release.image,
    type: 'article',
    publishedTime: `${release.date}T00:00:00+09:00`,
  });
}

export default async function JapaneseReleaseDetailRoute({ params }: Props) {
  const { slug } = await params;
  const release = findReleaseNote(slug);

  if (!release) {
    notFound();
  }

  return <ReleaseDetailPage slug={slug} />;
}
