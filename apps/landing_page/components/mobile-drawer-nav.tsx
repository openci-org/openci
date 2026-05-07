'use client';

import { useEffect, useRef, useState } from 'react';

export type MobileDrawerLink = {
  href: string;
  label: string;
  external?: boolean;
  variant?: 'link' | 'button';
};

type MobileDrawerNavProps = {
  title: string;
  homeHref: string;
  links: MobileDrawerLink[];
  ariaLabel: string;
  menuLabel: string;
  closeLabel: string;
};

const drawerLinkClass =
  'block rounded-lg px-3 py-2 text-sm font-normal text-neutral-700 transition-colors hover:bg-neutral-100 hover:text-neutral-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500';
const drawerButtonLinkClass =
  'mt-2 inline-flex w-full items-center justify-center rounded-lg bg-neutral-950 px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-neutral-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500';

export function MobileDrawerNav({ title, homeHref, links, ariaLabel, menuLabel, closeLabel }: MobileDrawerNavProps) {
  const [open, setOpen] = useState(false);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const closeButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) {
      return;
    }

    const previousBodyOverflow = document.body.style.overflow;
    const triggerElement = triggerRef.current;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setOpen(false);
      }
    };

    document.body.style.overflow = 'hidden';
    document.addEventListener('keydown', onKeyDown);
    closeButtonRef.current?.focus();

    return () => {
      document.body.style.overflow = previousBodyOverflow;
      document.removeEventListener('keydown', onKeyDown);
      triggerElement?.focus();
    };
  }, [open]);

  return (
    <div className="sm:hidden">
      <button
        ref={triggerRef}
        type="button"
        className="inline-flex h-10 w-10 items-center justify-center rounded-lg text-neutral-700 transition-colors hover:bg-neutral-100 hover:text-neutral-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
        aria-label={menuLabel}
        aria-expanded={open}
        onClick={() => setOpen(true)}
      >
        <MenuIcon />
      </button>

      {open ? (
        <div className="fixed inset-0 z-[60]" role="presentation">
          <button type="button" className="absolute inset-0 h-full w-full cursor-default bg-neutral-950/35" aria-label={closeLabel} onClick={() => setOpen(false)} />
          <aside className="relative flex h-dvh w-72 max-w-[calc(100vw-3rem)] flex-col border-r border-neutral-950/10 bg-white p-6 shadow-2xl" role="dialog" aria-modal="true" aria-label={ariaLabel}>
            <div className="flex items-center justify-between gap-4">
              <a href={homeHref} className="text-[1.0625rem] font-semibold tracking-tight text-neutral-950 transition-opacity hover:opacity-70" onClick={() => setOpen(false)}>
                {title}
              </a>
              <button
                ref={closeButtonRef}
                type="button"
                className="inline-flex h-9 w-9 items-center justify-center rounded-lg text-neutral-600 transition-colors hover:bg-neutral-100 hover:text-neutral-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label={closeLabel}
                onClick={() => setOpen(false)}
              >
                <CloseIcon />
              </button>
            </div>

            <nav className="mt-8 space-y-1" aria-label={ariaLabel}>
              {links.map((link) => (
                <a
                  key={`${link.href}-${link.label}`}
                  href={link.href}
                  target={link.external ? '_blank' : undefined}
                  rel={link.external ? 'noopener noreferrer' : undefined}
                  className={link.variant === 'button' ? drawerButtonLinkClass : drawerLinkClass}
                  onClick={() => setOpen(false)}
                >
                  {link.label}
                </a>
              ))}
            </nav>
          </aside>
        </div>
      ) : null}
    </div>
  );
}

function MenuIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" strokeWidth="1.8" stroke="currentColor" aria-hidden="true">
      <path strokeLinecap="round" d="M4 7h16M4 12h16M4 17h16" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" strokeWidth="1.8" stroke="currentColor" aria-hidden="true">
      <path strokeLinecap="round" strokeLinejoin="round" d="M6 6l12 12M18 6 6 18" />
    </svg>
  );
}
