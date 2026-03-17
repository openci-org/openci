import { getDictionary } from '@/lib/dictionaries'
import type { Metadata } from 'next'
import HomeContent from './[lang]/home-content'

export const metadata: Metadata = {
  description:
    'OpenCI Runner is an open-source GitHub Actions runner that anyone can use. We offer affordable, flat-rate monthly pricing so that anyone can use CI/CD.',
  alternates: {
    canonical: '/',
    languages: {
      en: '/',
      ja: '/ja',
    },
  },
}

export default async function Home() {
  const dict = await getDictionary('en')
  return <HomeContent lang="en" dict={dict} />
}
