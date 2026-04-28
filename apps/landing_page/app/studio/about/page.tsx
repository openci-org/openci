import type { Metadata } from 'next';
import { StudioAboutPage } from '../../../components/site';

export const metadata: Metadata = {
  title: '会社概要 - OpenCI Studio',
  description: 'OpenCI株式会社の会社概要。代表挨拶。',
};

export default function StudioAbout() {
  return <StudioAboutPage />;
}
