import NextLink, { type LinkProps } from 'next/link'
import { forwardRef } from 'react'

export const Link = forwardRef(function Link(
  props: LinkProps & React.ComponentPropsWithoutRef<'a'>,
  ref: React.ForwardedRef<HTMLAnchorElement>,
) {
  return <NextLink ref={ref} {...props} />
})
