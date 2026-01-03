import { clsx } from 'clsx'

export function Gradient({
  className,
  ...props
}: React.ComponentPropsWithoutRef<'div'>) {
  return (
    <div
      {...props}
      className={clsx(
        className,
        'bg-linear-to-br from-[#e0f2fe] via-[#a7f3d0] via-50% to-[#67e8f9]',
      )}
    />
  )
}

export function GradientBackground() {
  return (
    <div className="relative mx-auto max-w-7xl">
      <div
        className={clsx(
          'absolute -top-44 -right-60 h-60 w-xl transform-gpu md:right-0',
          'bg-linear-to-br from-[#e0f2fe] via-[#a7f3d0] via-50% to-[#67e8f9]',
          'rotate-[-10deg] rounded-full opacity-60 blur-3xl',
        )}
      />
    </div>
  )
}
