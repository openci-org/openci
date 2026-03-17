import { SanityLive } from '@/sanity/live'
import { revalidateSyncTags } from '@/sanity/revalidateSyncTags'
import '@/styles/tailwind.css'
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'
import type { Metadata } from 'next'

import { Noto_Sans_JP } from 'next/font/google'

const notoSansJP = Noto_Sans_JP({
  subsets: ['latin'],
  variable: '--font-noto-sans-jp',
  display: 'swap',
})

export const metadata: Metadata = {
  title: {
    template: '%s - OpenCI',
    default:
      'OpenCI - The Open Source CI/CD Service, Affordable for Everyone.',
  },
  description:
    'OpenCI is an open-source CI/CD service that anyone can use. Simple, fast, and surprisingly affordable. Start free with 60 minutes per month on Apple Silicon Mac.',
  openGraph: {
    url: 'https://openci.org',
    siteName: 'OpenCI',
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={notoSansJP.variable}>
      <head>
        <link
          rel="stylesheet"
          href="https://api.fontshare.com/css?f%5B%5D=switzer@400,500,600,700&amp;display=swap"
        />
        <link
          rel="alternate"
          type="application/rss+xml"
          title="The OpenCI Blog"
          href="/blog/feed.xml"
        />
      </head>
      <body className="text-gray-950 antialiased">
        {children}
        <Analytics />
        <SanityLive revalidateSyncTags={revalidateSyncTags} />
        <SpeedInsights />
      </body>
    </html>
  )
}
