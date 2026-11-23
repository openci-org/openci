import type { Metadata } from "next";
import { createCssVariablesTheme, createHighlighterCore } from "shiki/core";
import { createJavaScriptRegexEngine } from "shiki/engine/javascript";
import dart from "shiki/langs/dart.mjs";
import {
  type Locale,
  locales,
  siteDescription,
  siteImage,
  siteImageAlt,
  siteOrigin,
  siteTitle,
  translator,
} from "../../../../website/src/lib/i18n";
import { Header, DisplayPreferences } from "../../../components/landing/Chrome";
import { Hero } from "../../../components/landing/Hero";
import { WorkflowExamples } from "../../../components/landing/WorkflowExamples";
import { RunJourney } from "../../../components/landing/RunJourney";
import { Usage } from "../../../components/landing/Usage";
import { ClosingBanner, Guides } from "../../../components/landing/Guides";
import { SpecialThanks } from "../../../components/landing/SpecialThanks";
import { Footer } from "../../../components/landing/Footer";
import { workflowCode } from "../../../components/landing/workflow-code";

type Params = { params: Promise<{ locale: Locale }> };

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { locale } = await params;
  const url = new URL(`/${locale}/`, siteOrigin);
  const title = siteTitle(locale);
  const description = siteDescription(locale);
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
        ...Object.fromEntries(locales.map((lang) => [lang, `/${lang}/`])),
        "x-default": "/en/",
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

const highlighter = createHighlighterCore({
  langs: [dart],
  themes: [createCssVariablesTheme()],
  engine: createJavaScriptRegexEngine(),
});

export default async function ProductHome({ params }: Params) {
  const { locale } = await params;
  const t = translator(locale);
  const shiki = await highlighter;
  const highlighted = workflowCode.map((code) =>
    shiki.codeToHtml(code, {
      lang: "dart",
      theme: "css-variables",
      transformers: [
        {
          pre(node) {
            node.properties["data-language"] = "dart";
          },
        },
      ],
    }),
  );
  return (
    <>
      <a className="skip-link" href="#main">
        {t("本文へスキップ", "Skip to content")}
      </a>
      <Header locale={locale} />
      <main id="main">
        <Hero locale={locale} />
        <WorkflowExamples locale={locale} highlighted={highlighted} />
        <RunJourney locale={locale} />
        <Usage locale={locale} />
        <Guides locale={locale} />
        <SpecialThanks locale={locale} />
        <ClosingBanner locale={locale} />
      </main>
      <Footer locale={locale} />
      <DisplayPreferences locale={locale} />
    </>
  );
}
