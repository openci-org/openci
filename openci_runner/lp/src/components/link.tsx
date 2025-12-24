import * as Headless from '@headlessui/react'
import NextLink, { type LinkProps } from 'next/link'
import { forwardRef } from 'react'

export const Link = forwardRef(function Link(
  props: LinkProps & React.ComponentPropsWithoutRef<'a'>,
  ref: React.ForwardedRef<HTMLAnchorElement>,
) {
  const { href, children, ...rest } = props
  return (
    <Headless.DataInteractive>
      <NextLink href={href} legacyBehavior>
        <a ref={ref} {...rest}>
          {children}
        </a>
      </NextLink>
    </Headless.DataInteractive>
  )
})
