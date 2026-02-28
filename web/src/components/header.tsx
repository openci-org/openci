import Link from "next/link";
import { Suspense } from "react";
import { ThemeSwitcher } from "@/components/theme-switcher";
import { LocaleSwitcher } from "@/components/locale-switcher";
import { AuthButton } from "@/components/auth-button";
import { MobileMenuProtected } from "@/components/mobile-menu-protected";
import { MobileMenuPublic } from "@/components/mobile-menu-public";
import { createClient } from "@/lib/supabase/server";
import { getLocale } from "next-intl/server";

export async function Header() {
  const locale = await getLocale();
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const user = data?.claims;
  const email = user?.user_metadata?.full_name ?? user?.email ?? "";

  return (
    <nav className="w-full border-b border-b-foreground/10 h-16 flex items-center">
      <div className="w-full flex justify-between items-center px-5 text-sm">
        <div className="flex items-center font-semibold">
          <Link href="/">OpenCI</Link>
        </div>
        <div className="hidden md:flex items-center gap-2">
          <Suspense>
            <AuthButton />
          </Suspense>
          <LocaleSwitcher currentLocale={locale} />
          <ThemeSwitcher />
        </div>
        {user ? (
          <MobileMenuProtected currentLocale={locale} email={email} />
        ) : (
          <MobileMenuPublic currentLocale={locale} />
        )}
      </div>
    </nav>
  );
}
