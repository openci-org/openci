import Link from 'next/link'
import clsx from 'clsx'

type ButtonProps = {
  invert?: boolean
} & (
  | React.ComponentPropsWithoutRef<typeof Link>
  | (React.ComponentPropsWithoutRef<'button'> & { href?: undefined })
)

export function Button({
  invert = false,
  className,
  children,
  ...props
}: ButtonProps) {
  className = clsx(
    className,
    'inline-flex rounded-full px-4 py-1.5 text-sm font-semibold transition',
    invert
      ? 'bg-white text-neutral-950 hover:bg-neutral-200'
      : 'bg-neutral-950 text-white hover:bg-neutral-800',
  )

  const inner = <span className="relative top-px">{children}</span>

  if (typeof props.href === 'undefined') {
    return (
      <button className={className} {...props}>
        {inner}
      </button>
    )
  }

  // Check if the href is an external link
  const isExternal =
    typeof props.href === 'string' &&
    (props.href.startsWith('http://') || props.href.startsWith('https://'))

  if (isExternal) {
    const { href, ...restProps } = props
    return (
      <a
        className={className}
        href={href as string}
        target="_blank"
        rel="noopener noreferrer"
        {...restProps}
      >
        {inner}
      </a>
    )
  }

  return (
    <Link className={className} {...props}>
      {inner}
    </Link>
  )
}
