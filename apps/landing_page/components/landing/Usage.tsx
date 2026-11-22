"use client";
import { useState } from "react";
import { type Locale, translator } from "../../../website/src/lib/i18n";
import { formatRuntimeEstimate, usdCentsPerMinute } from "../../../website/src/lib/pricing";
import { Icon } from "./Icon";

export function Usage({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const [minutes, setMinutes] = useState(100);
  return (
    <section
      id="pricing"
      className="container usage-preview"
      data-reveal=""
      aria-labelledby="usage-title"
    >
      <header>
        <h2 className="section-title" id="usage-title">
          {t("月のランナー料金を見積もる。", "Estimate your monthly runner cost.")}
        </h2>
      </header>
      <div className="usage-sheet" id="estimate">
        <div className="usage-sheet-bar">
          <Icon name="clock" marketing />
          <span>OpenCI Cloud · Apple Silicon</span>
          <span>{locale === "ja" ? "JPY" : "USD"}</span>
        </div>
        <div className="usage-equation">
          <label>
            <span>{t("月の実行時間", "Monthly runtime")}</span>
            <select
              value={minutes}
              id="minutes"
              onChange={(event) => setMinutes(Number(event.target.value))}
            >
              {[10, 100, 1000].map((n) => (
                <option key={n} value={n}>
                  {n.toLocaleString(locale)}
                  {t("分", " min")}
                </option>
              ))}
            </select>
          </label>
          <span className="math-sign" aria-hidden="true">
            ×
          </span>
          <div>
            <span>{t("1分あたり", "Per minute")}</span>
            <strong>{t("¥1", `${usdCentsPerMinute}¢`)}</strong>
          </div>
          <span className="math-sign" aria-hidden="true">
            =
          </span>
          <div className="usage-total">
            <span>{t("月額（税込）", "Monthly total, tax included")}</span>
            <output htmlFor="minutes" aria-live="polite">
              {formatRuntimeEstimate(minutes, locale)}
            </output>
          </div>
        </div>
        <div className="usage-sheet-foot">
          <span>{t("VMの準備完了後から課金。", "Billing starts when the VM is ready.")}</span>
          <a className="text-link" href={`/${locale}/pricing/`}>
            {t("料金のしくみ", "Pricing details")} <Icon name="external" marketing />
          </a>
        </div>
      </div>
    </section>
  );
}
