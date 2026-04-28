import type { Metadata } from 'next';
import { CicdPage } from '../../../components/site';

export const metadata: Metadata = {
  title: 'OpenCI — CI/CDを、もっと安く、もっと速く。',
  description:
    'M4 Mac Miniで高速ビルド。GitHub Actionsより最大90%オフ。GitHub Actionsのワークフローファイルをそのまま使えます。',
};

export default function JapaneseLandingPage() {
  return <CicdPage lang="ja" />;
}
