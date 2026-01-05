import Link from 'next/link'

import { Container } from '@/studio-components/Container'
import { FadeIn } from '@/studio-components/FadeIn'
import { Logo } from '@/studio-components/Logo'
import { socialMediaProfiles } from '@/studio-components/SocialMedia'

const navigation = [
  // {
  //   title: 'Work',
  //   links: [
  //     { title: 'FamilyFund', href: '/work/family-fund' },
  //     { title: 'Unseal', href: '/work/unseal' },
  //     { title: 'Phobia', href: '/work/phobia' },
  //     {
  //       title: (
  //         <>
  //           See all <span aria-hidden="true">&rarr;</span>
  //         </>
  //       ),
  //       href: '/work',
  //     },
  //   ],
  // },
  {
    title: '会社情報',
    links: [
      { title: '会社概要', href: '/studio/about' },
      // { title: 'Process', href: '/studio/process' },
      // { title: 'Blog', href: '/studio/blog' },
      // { title: 'Contact us', href: '/studio/contact' },
    ],
  },
  {
    title: 'SNS',
    links: socialMediaProfiles,
  },
]

function Navigation() {
  return (
    <nav>
      <ul role="list" className="grid grid-cols-2 gap-8 sm:grid-cols-3">
        {navigation.map((section, sectionIndex) => (
          <li key={sectionIndex}>
            <div className="font-display text-sm font-semibold tracking-wider text-neutral-950">
              {section.title}
            </div>
            <ul role="list" className="mt-4 text-sm text-neutral-700">
              {section.links.map((link, linkIndex) => (
                <li key={linkIndex} className="mt-4">
                  <Link
                    href={link.href}
                    className="transition hover:text-neutral-950"
                  >
                    {link.title}
                  </Link>
                </li>
              ))}
            </ul>
          </li>
        ))}
      </ul>
    </nav>
  )
}

export function Footer() {
  return (
    <Container as="footer" className="mt-24 w-full sm:mt-32 lg:mt-40">
      <FadeIn>
        <div className="grid grid-cols-1 gap-x-8 gap-y-16 lg:grid-cols-2">
          <Navigation />
          {/* <div className="flex lg:justify-end">
            <NewsletterForm />
          </div> */}
        </div>
        <div className="mt-24 mb-20 flex flex-wrap items-end justify-between gap-x-6 gap-y-4 border-t border-neutral-950/10 pt-12">
          <Link href="/studio" aria-label="Home">
            <Logo className="h-8" fillOnHover />
          </Link>
          <p className="text-sm text-neutral-700">
            © OpenCI株式会社 {new Date().getFullYear()}
          </p>
        </div>
      </FadeIn>
    </Container>
  )
}
