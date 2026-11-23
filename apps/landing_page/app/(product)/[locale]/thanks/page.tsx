import type { Metadata } from "next";
import {
  type Locale,
  locales,
  siteImage,
  siteImageAlt,
  siteOrigin,
  translator,
} from "../../../../../website/src/lib/i18n";
import { DisplayPreferences, Header } from "../../../../components/landing/Chrome";
import { Footer } from "../../../../components/landing/Footer";
import { SpecialThanksPage } from "../../../../components/landing/SpecialThanksPage";

type Params = { params: Promise<{ locale: Locale }> };

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { locale } = await params;
  const t = translator(locale);
  const url = new URL(`/${locale}/thanks/`, siteOrigin);
  const title = "Special Thanks | OpenCI";
  const description = t(
    "OpenCIを支えてくださっている毎月のスポンサー、Mac実機やインフラを支えてくれる仲間、コミュニティの皆さまをご紹介します。",
    "Meet the monthly sponsors, Mac donors, infrastructure friends, and community members who keep OpenCI running.",
  );
  const image = {
    url: new URL(siteImage, siteOrigin),
    alt: siteImageAlt(locale),
    width: 1200,
    height: 630,
    type: "image/jpeg",
  };
  return {
    metadataBase: new URL(siteOrigin),
    title,
    description,
    robots: { index: false, follow: false },
    icons: { icon: "/favicon.png" },
    alternates: {
      canonical: url,
      languages: {
        ...Object.fromEntries(locales.map((lang) => [lang, `/${lang}/thanks/`])),
        "x-default": "/en/thanks/",
      },
    },
    openGraph: {
      type: "website",
      siteName: "OpenCI",
      url,
      title,
      description,
      locale: locale === "ja" ? "ja_JP" : "en_US",
      images: [image],
    },
    twitter: { card: "summary_large_image", title, description, images: [image] },
  };
}

export default async function ThanksRoute({ params }: Params) {
  const { locale } = await params;
  const t = translator(locale);
  return (
    <>
      <a className="skip-link" href="#main">
        {t("本文へスキップ", "Skip to content")}
      </a>
      <Header locale={locale} path="thanks/" />
      <main id="main">
        <SpecialThanksPage locale={locale} />
      </main>
      <Footer locale={locale} />
      <DisplayPreferences locale={locale} />
    </>
  );
}
