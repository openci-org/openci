import { translator, localePath, type Locale } from "./i18n";
export function docsNavigation(locale: Locale) {
  const t = translator(locale),
    path = (p: string) => localePath(locale, p);
  return [
    {
      group: t("はじめに", "Getting started"),
      items: [
        {
          title: t("GenuineCIへようこそ", "Welcome to GenuineCI"),
          path: path("/docs/"),
          icon: "book",
        },
        {
          title: t("クイックスタート", "Quickstart"),
          path: path("/docs/quickstart/"),
          icon: "spark",
        },
      ],
    },
    {
      group: t("ワークフロー", "Workflows"),
      items: [
        {
          title: t("Dartでワークフローを書く", "Write workflows in Dart"),
          path: path("/docs/workflows/"),
          icon: "code",
        },
        {
          title: t("トリガー", "Triggers"),
          path: path("/docs/triggers/"),
          icon: "branch",
        },
        {
          title: t("Flutterのビルドとテスト", "Build and test Flutter"),
          path: path("/docs/flutter/"),
          icon: "box",
        },
        {
          title: t("シークレット", "Secrets"),
          path: path("/docs/secrets/"),
          icon: "lock",
        },
      ],
    },
    {
      group: t("環境とツール", "Environment and tools"),
      items: [
        {
          title: t("CLIリファレンス", "CLI reference"),
          path: path("/docs/cli/"),
          icon: "terminal",
        },
        {
          title: t("セルフホスト", "Self-hosting"),
          path: path("/docs/self-hosting/"),
          icon: "server",
        },
      ],
    },
  ];
}
