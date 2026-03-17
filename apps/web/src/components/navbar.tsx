'use client'

import { githubRepositoryLink, slackInviteLink } from '@/constants'
import {
  Disclosure,
  DisclosureButton,
  DisclosurePanel,
} from '@headlessui/react'
import { Bars2Icon } from '@heroicons/react/24/solid'
import { motion } from 'framer-motion'
import { usePathname, useRouter } from 'next/navigation'
import { Link } from './link'
import { Logo } from './logo'
import { PlusGrid, PlusGridItem, PlusGridRow } from './plus-grid'

const links = [
  { href: '/', label: 'Home' },
  { href: '/blog', label: 'Blog' },
  { href: githubRepositoryLink, label: 'GitHub' },
  {
    href: slackInviteLink,
    label: 'Join Slack',
  },
]

function LanguageSwitcher() {
  const pathname = usePathname()
  const router = useRouter()

  const isJapanese = pathname.startsWith('/ja')
  const switchPath = isJapanese
    ? pathname.replace(/^\/ja/, '') || '/'
    : `/ja${pathname === '/' ? '' : pathname}`

  const handleSwitch = (e: React.MouseEvent) => {
    e.preventDefault()
    const targetLocale = isJapanese ? 'en' : 'ja'
    document.cookie = `preferred_locale=${targetLocale};path=/;max-age=${60 * 60 * 24 * 365};samesite=lax`
    router.push(switchPath)
  }

  return (
    <button
      type="button"
      onClick={handleSwitch}
      className="flex items-center px-3 py-2 text-sm font-medium text-gray-950 bg-blend-multiply data-hover:bg-black/2.5 cursor-pointer"
      title={isJapanese ? 'Switch to English' : '日本語に切り替え'}
    >
      {isJapanese ? 'EN' : 'JA'}
    </button>
  )
}

function DesktopNav() {
  return (
    <nav className="relative hidden lg:flex">
      {links.map(({ href, label }) => (
        <PlusGridItem key={href} className="relative flex">
          <Link
            href={href}
            className="flex items-center px-4 py-3 text-base font-medium text-gray-950 bg-blend-multiply data-hover:bg-black/2.5"
          >
            {label}
          </Link>
        </PlusGridItem>
      ))}
      <PlusGridItem className="relative flex">
        <LanguageSwitcher />
      </PlusGridItem>
    </nav>
  )
}

function MobileNavButton() {
  return (
    <DisclosureButton
      className="flex size-12 items-center justify-center self-center rounded-lg data-hover:bg-black/5 lg:hidden"
      aria-label="Open main menu"
    >
      <Bars2Icon className="size-6" />
    </DisclosureButton>
  )
}

function MobileNav() {
  return (
    <DisclosurePanel className="lg:hidden">
      <div className="flex flex-col gap-6 py-4">
        {links.map(({ href, label }, linkIndex) => (
          <motion.div
            initial={{ opacity: 0, rotateX: -90 }}
            animate={{ opacity: 1, rotateX: 0 }}
            transition={{
              duration: 0.15,
              ease: 'easeInOut',
              rotateX: { duration: 0.3, delay: linkIndex * 0.1 },
            }}
            key={href}
          >
            <Link href={href} className="text-base font-medium text-gray-950">
              {label}
            </Link>
          </motion.div>
        ))}
        <motion.div
          initial={{ opacity: 0, rotateX: -90 }}
          animate={{ opacity: 1, rotateX: 0 }}
          transition={{
            duration: 0.15,
            ease: 'easeInOut',
            rotateX: { duration: 0.3, delay: links.length * 0.1 },
          }}
        >
          <LanguageSwitcher />
        </motion.div>
      </div>
      <div className="absolute left-1/2 w-screen -translate-x-1/2">
        <div className="absolute inset-x-0 top-0 border-t border-black/5" />
        <div className="absolute inset-x-0 top-2 border-t border-black/5" />
      </div>
    </DisclosurePanel>
  )
}

export function Navbar({ banner }: { banner?: React.ReactNode }) {
  return (
    <Disclosure as="header" className="pt-12 sm:pt-16">
      <PlusGrid>
        <PlusGridRow className="relative flex justify-between">
          <div className="relative flex gap-6">
            <PlusGridItem className="py-3">
              <Link href="/" title="Home">
                <Logo className="h-9" />
              </Link>
            </PlusGridItem>
            {banner && (
              <div className="relative hidden items-center py-3 lg:flex">
                {banner}
              </div>
            )}
          </div>
          <DesktopNav />
          <MobileNavButton />
        </PlusGridRow>
      </PlusGrid>
      <MobileNav />
    </Disclosure>
  )
}
