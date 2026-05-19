import type { Metadata } from 'next';
import { StudioAboutPage } from '../../../../components/site';
import { createPageMetadata } from '../../../../lib/seo';

export const metadata: Metadata = createPageMetadata({
  title: '会社概要 - OpenCI Studio',
  description: 'OpenCI株式会社の会社概要。代表挨拶。',
  path: '/studio/about/',
});

export default function StudioAbout() {
  return <StudioAboutPage />;
}
