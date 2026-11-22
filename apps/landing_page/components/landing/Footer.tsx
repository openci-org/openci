import { footerGroups } from "../../../website/src/lib/product-links";
import { BrandMark } from "./Icon";
import { translator, type Locale } from "../../../website/src/lib/i18n";

export function Footer({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const home = `/${locale}/`;
  const groups = footerGroups(locale);
  return (
    <>
      <footer className="container product-footer">
        <div className="footer-grid">
          <div>
            <a className="wordmark" href={home}>
              <BrandMark />
              OpenCI
            </a>
            <p>{t("Flutter専用のmacOSランナー。", "macOS runners for Flutter.")}</p>
          </div>
          {groups.map(([name, links]) => (
            <div key={name}>
              <h2>{name}</h2>
              {links.map(([label, href]) => (
                <a key={href} href={href}>
                  {label}
                </a>
              ))}
            </div>
          ))}
        </div>
        <div className="footer-meta">
          <span>© 2026 OpenCI, Inc.</span>
          <details>
            <summary>{t("写真クレジット", "Photo credits")}</summary>
            <ul>
              <li>
                <a href="https://unsplash.com/photos/4qKVQYOluDk">Yoshi Takekawa</a>
              </li>
              <li>
                <a href="https://unsplash.com/photos/uxxGF7g754U">Dhony Koswara</a>
              </li>
              <li>
                <a href="https://unsplash.com/photos/sFw3vSW9kdk">Keith Camilleri</a>
              </li>
              <li>
                <a href="https://unsplash.com/photos/KL63kujm9sU">Jonas Denil</a>
              </li>
            </ul>
          </details>
          <a href="#main">{t("先頭へ戻る ↑", "Back to top ↑")}</a>
        </div>
      </footer>
    </>
  );
}
