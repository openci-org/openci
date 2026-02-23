"use client";

import { useState } from "react";
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
import { LogoutButton } from "@/components/logout-button";
import { useTranslations } from "next-intl";

export function MobileMenuProtected({
  currentLocale,
  email,
}: {
  currentLocale: string;
  email: string;
}) {
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
          <p className="text-sm text-muted-foreground px-1">
            {t("greeting", { email })}
          </p>
          <LogoutButton className="w-full" />
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
