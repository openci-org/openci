import type { Metadata } from 'next'

import '@/studio-styles/tailwind.css'

export const metadata: Metadata = {
  title: {
    template: '%s - OpenCI Studio',
    default: 'OpenCI Studio',
  },
  description:
    'OpenCI Studioは、数人規模の会社から大企業まで、様々な規模のプロジェクトに対応できるFlutterの開発スタジオです。',
}

export default function StudioLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex min-h-full flex-col bg-neutral-950 text-base antialiased">
      {children}
    </div>
  )
}
