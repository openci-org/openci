import { SanityLive } from '@/sanity/live'
import { revalidateSyncTags } from '@/sanity/revalidateSyncTags'
import '@/styles/tailwind.css'
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: {
    template: '%s - OpenCI',
    default:
      'OpenCI - The Open Source GitHub Actions Runner, Affordable for Everyone, Written in Rust.',
  },
  openGraph: {
    url: 'https://openci.org',
    siteName: 'OpenCI',
    images: [{ url: 'https://openci.org/screenshots/lp.png' }],
  },
}

export default function MarketingLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <>
      <link
        rel="stylesheet"
        href="https://api.fontshare.com/css?f%5B%5D=switzer@400,500,600,700&display=swap"
      />
      <link
        rel="alternate"
        type="application/rss+xml"
        title="The OpenCI Blog"
        href="/blog/feed.xml"
      />
      <div
        className="text-gray-950 antialiased"
        style={{
          backgroundColor: 'white',
          color: '#0a0a0a',
          fontFamily: 'Switzer, system-ui, sans-serif',
          colorScheme: 'light',
        }}
        data-theme="light"
      >
        {children}
        <Analytics />
        <SanityLive revalidateSyncTags={revalidateSyncTags} />
        <SpeedInsights />
      </div>
    </>
  )
}
