import { getRelativeLocaleUrl } from "astro:i18n";
import { translator, type Locale } from "./i18n";
export function docsNavigation(locale: Locale) {
  const t = translator(locale);
  return [
    {
      group: t("はじめに", "Getting started"),
      items: [
        {
          title: t("GenuineCIへようこそ", "Welcome to GenuineCI"),
          path: getRelativeLocaleUrl(locale, "docs/"),
          icon: "book",
        },
        {
          title: t("クイックスタート", "Quickstart"),
          path: getRelativeLocaleUrl(locale, "docs/quickstart/"),
          icon: "spark",
        },
      ],
    },
    {
      group: t("ワークフロー", "Workflows"),
      items: [
        {
          title: t("Dartでワークフローを書く", "Write workflows in Dart"),
          path: getRelativeLocaleUrl(locale, "docs/workflows/"),
          icon: "code",
        },
        {
          title: t("トリガー", "Triggers"),
          path: getRelativeLocaleUrl(locale, "docs/triggers/"),
          icon: "branch",
        },
        {
          title: t("Flutterのビルドとテスト", "Build and test Flutter"),
          path: getRelativeLocaleUrl(locale, "docs/flutter/"),
          icon: "box",
        },
        {
          title: t("シークレット", "Secrets"),
          path: getRelativeLocaleUrl(locale, "docs/secrets/"),
          icon: "lock",
        },
      ],
    },
    {
      group: t("環境とツール", "Environment and tools"),
      items: [
        {
          title: t("CLIリファレンス", "CLI reference"),
          path: getRelativeLocaleUrl(locale, "docs/cli/"),
          icon: "terminal",
        },
        {
          title: t("セルフホスト", "Self-hosting"),
          path: getRelativeLocaleUrl(locale, "docs/self-hosting/"),
          icon: "server",
        },
      ],
    },
  ];
}
