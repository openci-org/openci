import localFont from "next/font/local";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { locales } from "../../../../website/src/lib/i18n";
import "../../../components/landing/home.css";

const geist = localFont({
  src: "../../../../website/public/fonts/geist.ttf",
  variable: "--home-sans",
  weight: "100 900",
  display: "swap",
  preload: false,
});
const mono = localFont({
  src: "../../../../website/public/fonts/geist-mono.ttf",
  variable: "--home-mono",
  weight: "100 900",
  display: "swap",
  preload: false,
});
const lora = localFont({
  src: [
    { path: "../../../../website/public/fonts/lora.ttf", weight: "400 700", style: "normal" },
    {
      path: "../../../../website/public/fonts/lora-italic.ttf",
      weight: "400 700",
      style: "italic",
    },
  ],
  variable: "--home-display",
  display: "swap",
});
const mincho = localFont({
  src: "../../../../website/public/fonts/mincho-hero.ttf",
  variable: "--home-mincho",
  display: "swap",
  preload: false,
});

export const dynamicParams = false;
export const generateStaticParams = () => locales.map((locale) => ({ locale }));

// Apply the saved palette before the first paint, including on a direct visit.
const preferences = `(() => {
  const root = document.documentElement;
  const read = key => { try { return localStorage.getItem("openci-" + key); } catch { return null; } };
  root.dataset.theme = read("theme") || (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  root.dataset.motion = read("paused") === "true" || matchMedia("(prefers-reduced-motion: reduce)").matches ? "paused" : "active";
})();`;

export default async function LandingLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!locales.some((value) => value === locale)) notFound();
  return (
    <html
      lang={locale}
      className={`product landing-home ${geist.variable} ${mono.variable} ${lora.variable} ${mincho.variable}`}
      suppressHydrationWarning
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: preferences }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
