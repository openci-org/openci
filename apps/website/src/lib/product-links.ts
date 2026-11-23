import { translator, type Locale } from "./i18n";

export function navigationLinks(locale: Locale) {
  const t = translator(locale);
  const home = `/${locale}/`;
  return [
    [home + "#playground", t("デモ", "Demo")],
    [home + "#apis", "Flutter API"],
    [home + "pricing/", t("料金", "Pricing")],
    [home + "docs/", t("ドキュメント", "Docs")],
    [home + "blog/", t("ブログ", "Blog")],
    [home + "thanks/", "Special Thanks"],
  ] as const;
}

export function footerGroups(locale: Locale) {
  const t = translator(locale);
  const docs = `/${locale}/docs/`;
  const home = `/${locale}/`;
  const pricing = home + "pricing/";
  return [
    [
      "OpenCI",
      [
        [t("Flutter向けAPI", "Flutter API"), home + "#apis"],
        [t("料金", "Pricing"), pricing],
        [t("ダッシュボード", "Dashboard"), "https://dashboard.openci.org/"],
        ["OpenCI Studio", "/studio/"],
        ["Special Thanks", home + "thanks/"],
      ],
    ],
    [
      t("開発者向け", "Developers"),
      [
        [t("始め方", "Quickstart"), home + "#quickstart"],
        [t("ドキュメント", "Documentation"), docs],
        ["Dart SDK", "https://pub.dev/packages/openci_workflow"],
      ],
    ],
    [
      t("リソース", "Resources"),
      [
        [t("ブログ", "Blog"), home + "blog/"],
        [t("過去のリリース", "Release archive (Japanese)"), "/ja/releases/"],
        [t("よくある質問", "FAQ"), pricing + "#faq"],
        ["GitHub", "https://github.com/openci-org/openci"],
      ],
    ],
  ] as const;
}
