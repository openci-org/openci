import { SanityLive } from '@/sanity/live'
import { revalidateSyncTags } from '@/sanity/revalidateSyncTags'
import '@/styles/tailwind.css'
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: {
    template: '%s - OpenCI',
    default: 'OpenCI - The best Open Source GitHub Actions Runner',
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <head>
        <meta property="og:image" content="https://www.openci.org/api/og" />
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
