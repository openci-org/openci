import type { Metadata } from 'next';
import { CicdPage } from '../../../components/site';
import { createPageMetadata } from '../../../lib/seo';

export const metadata: Metadata = createPageMetadata({
  title: 'OpenCI — CI/CDを、もっと安く、もっと速く。',
  description:
    'M4 Mac Miniで高速ビルド。GitHub Actionsより最大90%オフ。GitHub Actionsのワークフローファイルをそのまま使えます。',
  path: '/ja/',
});

export default function JapaneseLandingPage() {
  return <CicdPage lang="ja" />;
}
