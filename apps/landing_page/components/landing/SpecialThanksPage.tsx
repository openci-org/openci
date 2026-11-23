import { translator, type Locale } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";
import { hardwareSupporters, infraSupporters, monthlySponsors, pickText } from "./thanks-data";

export function SpecialThanksPage({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const jumpLinks = [
    ["#sponsors", t("スポンサー", "Sponsors")],
    ["#machines", t("マシン提供", "Machines")],
    ["#infrastructure", t("インフラ協力", "Infrastructure")],
  ] as const;

  return (
    <>
      <header className="container thanks-intro">
        <span className="eyeline">OPENCI / SPECIAL THANKS</span>
        <h1>
          {locale === "ja" ? (
            <>
              OpenCIを支えてくれる、
              <br />
              <strong>すべての人へ。</strong>
            </>
          ) : (
            <>
              To everyone
              <br />
              <strong>keeping OpenCI running.</strong>
            </>
          )}
        </h1>
        <p>
          {t(
            "OpenCIは、継続的にスポンサーしてくださる方々、実機のMacを譲ってくれた方々、",
            "OpenCI runs on the generosity of sponsors, friends who passed on their Macs,",
          )}
          <br />
          {t(
            "そしてインフラを一緒に支えてくれる仲間の協力によって動いています。",
            "and the friends who helped build and maintain our infrastructure.",
          )}
        </p>
        <nav className="thanks-jump" aria-label={t("セクション移動", "Jump to section")}>
          {jumpLinks.map(([href, label]) => (
            <a key={href} href={href}>
              {label}
            </a>
          ))}
        </nav>
      </header>

      <section id="sponsors" className="tinted section-pad" data-reveal="">
        <div className="container">
          <div className="section-head">
            <div>
              <span className="eyeline">01 / {t("スポンサー", "SPONSORS")}</span>
              <h2 className="section-title">
                {t("継続的に支えてくれる", "Backing OpenCI")}
                <br />
                {t("スポンサーの皆さま。", "over the long run.")}
              </h2>
            </div>
            <p>
              {t(
                "継続的なご支援が、ランナーの維持費や日々の開発・改善を続ける大きな力になっています。",
                "Steady sponsorships fund runner maintenance and ongoing improvements to OpenCI.",
              )}
            </p>
          </div>

          <ul className="thanks-infra-grid" role="list">
            {monthlySponsors.map((sponsor) => {
              const name = pickText(sponsor.name, locale);
              return (
                <li key={name} className="thanks-card thanks-infra-card">
                  <span className="card-label">
                    <Icon name="heart" /> {pickText(sponsor.role, locale)}
                  </span>
                  <div className="thanks-card-top">
                    <span className="thanks-monogram" aria-hidden="true">
                      {sponsor.monogram}
                    </span>
                    <h3 lang={sponsor.lang}>{name}</h3>
                  </div>
                  <p className="thanks-note">{pickText(sponsor.note, locale)}</p>
                </li>
              );
            })}
          </ul>
        </div>
      </section>

      <section id="machines" className="container section-pad" data-reveal="">
        <div className="section-head">
          <div>
            <span className="eyeline">02 / {t("マシン提供", "HARDWARE & MACHINES")}</span>
            <h2 className="section-title">
              {locale === "ja" ? (
                <>
                  Macを譲ってくれて、
                  <br />
                  <em>ありがとう！</em>
                </>
              ) : (
                <>
                  Thanks for passing your
                  <br />
                  <em>Apple Silicon</em> Macs on.
                </>
              )}
            </h2>
          </div>
          <p>
            {t(
              "ビルドや検証に使う Mac を譲っていただきました。Flutter の高速な CI は、この実機たちの上で動いています。",
              "Every shared Mac powers real builds, benchmarks, and stability testing across Flutter apps.",
            )}
          </p>
        </div>

        <ul className="thanks-machine-list" role="list">
          {hardwareSupporters.map((item) => {
            const name = pickText(item.name, locale);
            return (
              <li key={name} className="thanks-machine-row">
                <div className="thanks-machine-who">
                  <span className="card-label">
                    <Icon name="cpu" marketing /> {t("マシン提供", "MACHINE DONOR")}
                  </span>
                  <div className="thanks-machine-name">
                    <span className="thanks-monogram small" aria-hidden="true">
                      {item.monogram}
                    </span>
                    <h3>{item.href ? <a href={item.href}>{name}</a> : name}</h3>
                  </div>
                </div>
                <div className="thanks-machine-spec">
                  <code>{pickText(item.machine, locale)}</code>
                </div>
                <p className="thanks-note">{pickText(item.note, locale)}</p>
              </li>
            );
          })}
        </ul>
      </section>

      <section id="infrastructure" className="tinted section-pad" data-reveal="">
        <div className="container">
          <div className="section-head">
            <div>
              <span className="eyeline">03 / {t("インフラ提供・協力", "INFRASTRUCTURE")}</span>
              <h2 className="section-title">
                {t("インフラを支えてくれた", "To the friends who helped")}
                <br />
                {t("ふたりへ。", "with our infrastructure.")}
              </h2>
            </div>
            <p>
              {t(
                "構築から日々の相談まで、OpenCI の目に見えない土台を支えていただいています。",
                "From infrastructure setup to ongoing advice, they form the quiet foundation behind every run.",
              )}
            </p>
          </div>

          <ul className="thanks-infra-grid" role="list">
            {infraSupporters.map((item) => (
              <li key={item.name} className="thanks-card thanks-infra-card">
                <span className="card-label">
                  <Icon name="server" /> {pickText(item.category, locale)}
                </span>
                <div className="thanks-card-top">
                  <span className="thanks-monogram" aria-hidden="true">
                    {item.monogram}
                  </span>
                  <h3 lang={item.lang}>{item.name}</h3>
                </div>
                <p className="thanks-note">{pickText(item.note, locale)}</p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="container closing-banner" data-reveal="">
        <h2 className="section-title">
          {t("OpenCIの開発を", "Want to support")}
          <br />
          {t("応援していただけますか。", "OpenCI’s future?")}
        </h2>
        <p>
          {t(
            "継続スポンサーやマシン・インフラのご協力について、いつでもお気軽にご連絡ください。",
            "Reach out anytime about sponsorships, hardware, or infrastructure collaboration.",
          )}
        </p>
        <div className="actions">
          <a className="action primary" href="https://github.com/openci-org/openci">
            {t("GitHubで応援する", "Support on GitHub")} <Icon name="external" marketing />
          </a>
          <a className="action light-outline" href="https://github.com/openci-org/openci/issues">
            {t("マシン・インフラ協力の相談", "Offer hardware or infra")}
          </a>
        </div>
      </section>
    </>
  );
}
