"use client";

import { useState } from "react";
import Link from "next/link";
import { Menu } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { LocaleSwitcher } from "@/components/locale-switcher";
import { ThemeSwitcher } from "@/components/theme-switcher";
import { useTranslations } from "next-intl";

export function MobileMenuPublic({ currentLocale }: { currentLocale: string }) {
  const [open, setOpen] = useState(false);
  const t = useTranslations("auth");

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button variant="ghost" size="sm" className="md:hidden">
          <Menu size={20} />
        </Button>
      </SheetTrigger>
      <SheetContent side="right">
        <SheetHeader>
          <SheetTitle>OpenCI</SheetTitle>
        </SheetHeader>
        <div className="flex flex-col gap-3 mt-6 px-4">
          <Button asChild variant="outline" onClick={() => setOpen(false)}>
            <Link href="/auth/login">{t("signIn")}</Link>
          </Button>
          <Button asChild variant="default" onClick={() => setOpen(false)}>
            <Link href="/auth/sign-up">{t("signUp")}</Link>
          </Button>
          <hr className="my-2" />
          <div className="flex items-center justify-between">
            <LocaleSwitcher currentLocale={currentLocale} />
            <ThemeSwitcher />
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
