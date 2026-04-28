import type { Metadata } from 'next';
import { StudioHomePage } from '../../components/site';

export const metadata: Metadata = {
  title: 'OpenCI Studio',
  description:
    'OpenCI Studioは、数人規模の会社から大企業まで、様々な規模のプロジェクトに対応できるFlutterの開発スタジオです。',
};

export default function StudioPage() {
  return <StudioHomePage />;
}
