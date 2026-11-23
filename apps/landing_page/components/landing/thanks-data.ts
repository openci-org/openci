import type { Locale } from "../../../website/src/lib/i18n";

export interface LocalizedText {
  ja: string;
  en: string;
}

export interface MonthlySponsor {
  name: LocalizedText;
  monogram: string;
  role: LocalizedText;
  href?: string;
  lang?: "ja";
  note: LocalizedText;
}

export interface HardwareSupporter {
  name: LocalizedText;
  monogram: string;
  machine: LocalizedText;
  href?: string;
  note: LocalizedText;
}

export interface InfraSupporter {
  name: string;
  monogram: string;
  category: LocalizedText;
  href?: string;
  lang?: "ja";
  note: LocalizedText;
}

export const pickText = (text: LocalizedText, locale: Locale): string =>
  locale === "ja" ? text.ja : text.en;

export const monthlySponsors: MonthlySponsor[] = [
  {
    name: { ja: "bullさん", en: "bull" },
    monogram: "BU",
    role: {
      ja: "1年以上の継続スポンサー",
      en: "Sponsor for over a year",
    },
    note: {
      ja: "1年以上にわたってスポンサーとして支えていただきました。継続的なご支援が、OpenCI の開発を続ける大きな力になっています。本当にありがとう！",
      en: "Supported OpenCI as a sponsor for over a year. Your steady backing has been a huge help in keeping development moving—thank you!",
    },
  },
  {
    name: { ja: "かえるくん", en: "かえるくん" },
    monogram: "か",
    lang: "ja",
    role: {
      ja: "継続スポンサー・インフラ協力",
      en: "Monthly Sponsor & Infrastructure",
    },
    note: {
      ja: "インフラをめちゃくちゃ手伝ってもらいました。今もスポンサーとして支えてくれて、ほんとにありがとう！",
      en: "You’ve helped us so much with our infrastructure. Thanks for sticking with us as a sponsor, too!",
    },
  },
];

export const hardwareSupporters: HardwareSupporter[] = [
  {
    name: { ja: "hobbydevelopさん", en: "hobbydevelop" },
    monogram: "HD",
    machine: { ja: "M4 Mac mini", en: "M4 Mac mini" },
    note: {
      ja: "M4 Mac mini を譲っていただきました。Apple Silicon での高速な Flutter ビルドと検証を支えてくれています。",
      en: "Passed on an M4 Mac mini that helps power fast Apple Silicon Flutter builds and verification.",
    },
  },
  {
    name: { ja: "jboyさん", en: "jboy" },
    monogram: "JB",
    machine: { ja: "M2搭載のMac", en: "M2 Mac" },
    note: {
      ja: "M2 搭載の Mac を譲っていただきました。日々の macOS ランナー稼働とテストの検証に活躍しています。",
      en: "Passed on an M2 Mac that actively supports day-to-day macOS runner testing and builds.",
    },
  },
  {
    name: { ja: "heavenさん", en: "heaven" },
    monogram: "HV",
    machine: { ja: "M1 MacBook Air", en: "M1 MacBook Air" },
    note: {
      ja: "M1 MacBook Air を譲っていただきました。Apple Silicon 環境での動作確認や開発を支えてくれています。",
      en: "Passed on an M1 MacBook Air supporting Apple Silicon compatibility checks and development.",
    },
  },
];

export const infraSupporters: InfraSupporter[] = [
  {
    name: "かえるくん",
    monogram: "か",
    lang: "ja",
    category: {
      ja: "インフラ構築・継続スポンサー",
      en: "Infrastructure & Monthly Sponsor",
    },
    note: {
      ja: "インフラをめちゃくちゃ手伝ってもらいました。今もスポンサーとして支えてくれて、ほんとにありがとう！",
      en: "You’ve helped us so much with our infrastructure. Thanks for sticking with us as a sponsor, too!",
    },
  },
  {
    name: "もぐもぐさん",
    monogram: "も",
    lang: "ja",
    category: {
      ja: "インフラ構築・技術相談",
      en: "Infrastructure & Ongoing Advice",
    },
    note: {
      ja: "インフラ周りをあれこれ手伝ってくれてありがとう。今も相談に乗ってもらえて、心強いです！",
      en: "Thanks for all the hands-on help with our infrastructure. It means a lot that we can still turn to you for advice!",
    },
  },
];
