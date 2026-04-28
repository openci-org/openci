import type { Metadata } from 'next';
import { CicdPage } from '../../components/site';

export const metadata: Metadata = {
  title: "OpenCI — CI/CD that's faster and cheaper.",
  description:
    'Blazing-fast builds on M4 Mac Mini. Up to 90% cheaper than GitHub Actions. Your existing workflow files just work.',
};

export default function EnglishLandingPage() {
  return <CicdPage lang="en" />;
}
