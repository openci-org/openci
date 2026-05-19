import type { Metadata } from 'next';
import { ReleaseIndexPage } from '../../../../components/releases';
import { createPageMetadata } from '../../../../lib/seo';

export const metadata: Metadata = createPageMetadata({
  title: '更新情報 — OpenCI',
  description: 'OpenCIのプロダクト改善、ランナー更新、ダッシュボード変更を毎週金曜日にまとめてお届けします。',
  path: '/ja/releases/',
});

export default function JapaneseReleaseIndexRoute() {
  return <ReleaseIndexPage />;
}
