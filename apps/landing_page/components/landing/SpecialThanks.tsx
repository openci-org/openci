import { translator, type Locale } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";
import { hardwareSupporters, infraSupporters, monthlySponsors, pickText } from "./thanks-data";

export function SpecialThanks({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const thanksUrl = `/${locale}/thanks/`;
  const groups = [
    {
      icon: "heart",
      marketing: false,
      eyeline: t("スポンサー", "Sponsors"),
      count: t(`${monthlySponsors.length}名`, `${monthlySponsors.length}`),
      summary: t(
        "ランナーの運用と日々の開発を継続的にご支援いただいているスポンサーの皆さま。",
        "Sponsors who have backed OpenCI’s runners and ongoing development.",
      ),
      names: monthlySponsors.map((item) => pickText(item.name, locale)),
      href: thanksUrl + "#sponsors",
      linkLabel: t("スポンサーを見る", "See sponsors"),
    },
    {
      icon: "cpu",
      marketing: true,
      eyeline: t("マシン提供", "Hardware & Machines"),
      count: t(`${hardwareSupporters.length}台`, `${hardwareSupporters.length}`),
      summary: t(
        "Macを譲ってくださった方々。Apple Silicon の実機が日々のビルドと検証を支えています。",
        "Friends who passed on their Apple Silicon Macs to power Flutter builds and testing.",
      ),
      names: hardwareSupporters.map((item) => pickText(item.name, locale)),
      href: thanksUrl + "#machines",
      linkLabel: t("提供マシンを見る", "See donated machines"),
    },
    {
      icon: "server",
      marketing: false,
      eyeline: t("インフラ協力", "Infrastructure"),
      count: t(`${infraSupporters.length}名`, `${infraSupporters.length}`),
      summary: t(
        "インフラの構築や日々の相談で、OpenCI の足元を支えてくれているふたり。",
        "The friends who helped build our infrastructure and still back us with advice.",
      ),
      names: infraSupporters.map((item) => item.name),
      href: thanksUrl + "#infrastructure",
      linkLabel: t("インフラ協力を見る", "See infrastructure friends"),
    },
  ];

  return (
    <section
      id="special-thanks"
      className="container section-pad special-thanks"
      data-reveal=""
      aria-labelledby="special-thanks-heading"
    >
      <header className="section-head">
        <div>
          <span className="eyeline">SPECIAL THANKS</span>
          <h2 id="special-thanks-heading" className="section-title">
            {t("OpenCIを支えてくれる", "Supported by people")}
            <br />
            {t("すべての皆さまへ。", "who believe in OpenCI.")}
          </h2>
        </div>
        <div className="thanks-head-side">
          <p>
            {t(
              "スポンサー、Mac実機を譲ってくれた方々、インフラを支えてくれる仲間のおかげで、1分1円のmacOSランナーを続けられています。",
              "Sponsors, Mac donors, and infrastructure friends make 1-cent-per-minute macOS runners possible.",
            )}
          </p>
          <a className="text-link" href={thanksUrl}>
            {t("Special Thanks ページを見る", "View full Special Thanks")}{" "}
            <Icon name="arrow" marketing />
          </a>
        </div>
      </header>

      <ul className="thanks-preview-grid" role="list">
        {groups.map((group) => (
          <li key={group.eyeline} className="thanks-preview-card">
            <div className="thanks-preview-top">
              <span className="card-label">
                <Icon name={group.icon} marketing={group.marketing} />
                {group.eyeline}
              </span>
              <span className="thanks-count">{group.count}</span>
            </div>
            <p>{group.summary}</p>
            <ul className="thanks-chip-list" role="list">
              {group.names.map((name) => (
                <li key={name}>{name}</li>
              ))}
            </ul>
            <a className="text-link" href={group.href}>
              {group.linkLabel} <Icon name="arrow" marketing />
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}
