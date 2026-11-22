"use client";
import { useEffect, useRef, useState } from "react";
import { moveTab } from "./controls";
import { translator, type Locale } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";

export function RunJourney({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const journeySteps = [
    {
      label: t("ワークフローを書く", "Write in Dart"),
      summary: t(
        "リポジトリ直下の openci ディレクトリに Dart ファイルを配置。YAML の構文エラーに悩まず、エディタの補完と型チェックで安全に書けます。",
        "Place a Dart file in the openci directory. Skip fragile YAML and write workflows with full IDE autocomplete and type checks.",
      ),
      detail: "INPUT / openci/flutter_ci.dart",
    },
    {
      label: t("Apple Silicon で実行", "Run on Apple Silicon"),
      summary: t(
        "プルリクエストやタグをトリガーに、OpenCI が管理するクリーンな macOS 環境で解析・テスト・署名を並列実行します。",
        "On pull requests or tags, OpenCI runs analysis, tests, and signing on clean, managed Apple Silicon macOS runners.",
      ),
      detail: "RUNNER / macOS Apple Silicon",
    },
    {
      label: t("結果と配布まで完結", "Ship the artifact"),
      summary: t(
        "テスト結果のレポートから TestFlight や Google Play への提出まで同じ流れで完結。課金は VM 準備完了後の実行時間だけです。",
        "Carry the same run from test verification to TestFlight or Google Play upload. You only pay for runtime after VM setup.",
      ),
      detail: "OUTPUT / TestFlight & Play",
    },
  ];

  const [selected, setSelected] = useState(0);
  const [manual, setManual] = useState(false);
  const section = useRef<HTMLElement>(null);
  const [inView, setInView] = useState(false);
  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => setInView(entry.isIntersecting));
    observer.observe(section.current!);
    return () => observer.disconnect();
  }, []);

  return (
    <>
      <section
        id="pipeline"
        className="container journey-section"
        data-journey
        ref={section}
        data-running={inView}
        data-manual={manual}
        data-reveal=""
        aria-labelledby="pipeline-heading"
      >
        <header className="section-head">
          <div>
            <span className="eyeline">{t("ワークフローの流れ", "WORKFLOW RUN")}</span>
            <h2 id="pipeline-heading" className="section-title">
              {t("ひとつのプッシュから、", "One push.")}
              <br />
              {t("テストも配布も途切れずに。", "A connected CI run.")}
            </h2>
          </div>
          <p>
            {t(
              "ローカルで確かめたDartのワークフローが、そのままApple Siliconのクラウドで動きます。",
              "The same Dart workflow you test locally runs end-to-end on managed Apple Silicon Macs.",
            )}
          </p>
        </header>

        <div className="journey-frame">
          <div className="journey-stage" aria-hidden="true">
            <svg
              className="journey-wires desktop"
              viewBox="0 0 1000 300"
              preserveAspectRatio="none"
              fill="none"
            >
              <path className="wire-base" d="M235 150H356L390 122H464" />
              <path className="wire-base" d="M536 122H610L644 150H765" />
              <path className="wire-pulse" pathLength="100" d="M235 150H356L390 122H464" />
              <path className="wire-pulse delayed" pathLength="100" d="M536 122H610L644 150H765" />
            </svg>
            <svg
              className="journey-wires mobile"
              viewBox="0 0 100 620"
              preserveAspectRatio="none"
              fill="none"
            >
              <path className="wire-base" d="M50 174V198L54 214V244" />
              <path className="wire-base" d="M54 378V402L50 422V452" />
              <path className="wire-pulse" pathLength="100" d="M50 174V198L54 214V244" />
              <path className="wire-pulse delayed" pathLength="100" d="M54 378V402L50 422V452" />
            </svg>

            <div
              className="journey-node"
              data-focused={manual && selected === 0}
              data-muted={manual && selected !== 0}
            >
              <div className="journey-card surface-brief">
                <div className="surface-head">
                  <Icon name="file" />
                  <span>openci/flutter_ci.dart</span>
                  <span className="pulse-dot" />
                </div>
                <p className="surface-lead">
                  {t("PR #418 を検証して", "Verify PR #418 and")}
                  <br />
                  <strong>{t("TestFlightへ配布。", "ship to TestFlight.")}</strong>
                </p>
                <div className="surface-foot">
                  <span>GITHUB APP TRIGGER</span>
                  <Icon name="arrow" marketing />
                </div>
              </div>
            </div>

            <div
              className="journey-node"
              data-focused={manual && selected === 1}
              data-muted={manual && selected !== 1}
            >
              <div className="runner-graph">
                <svg viewBox="0 0 240 210" fill="none">
                  <path d="M54 53H90L120 94M186 53H150L120 94M120 128V162" />
                </svg>
                <div className="runner-pill top-left">
                  <Icon name="code" />
                  <span>Analyze</span>
                </div>
                <div className="runner-pill top-right">
                  <Icon name="shield" />
                  <span>Tests</span>
                </div>
                <div className="journey-card runner-core">
                  <Icon name="cpu" marketing />
                  <span className="core-dot" />
                </div>
                <div className="runner-pill bottom-center">
                  <Icon name="box" marketing />
                  <span>Build IPA</span>
                  <Icon name="check" marketing />
                </div>
                <span className="runner-caption">APPLE SILICON MACOS</span>
              </div>
            </div>

            <div
              className="journey-node"
              data-focused={manual && selected === 2}
              data-muted={manual && selected !== 2}
            >
              <div className="journey-card surface-output">
                <div className="surface-head">
                  <Icon name="rocket" />
                  <span>v2.6.0 (42)</span>
                  <Icon name="check" marketing />
                </div>
                <strong className="surface-title">
                  {t("リリース準備完了。", "Ready for testers.")}
                </strong>
                <ul className="surface-list">
                  <li>
                    <span>01</span>
                    {t("静的解析・テスト通過", "Analysis & tests passed")}
                  </li>
                  <li>
                    <span>02</span>
                    {t("署名済み IPA を生成", "Signed IPA archived")}
                  </li>
                  <li>
                    <span>03</span>
                    {t("TestFlight へ送信完了", "Uploaded to TestFlight")}
                  </li>
                </ul>
                <div className="surface-foot accent-foot">
                  <Icon name="check" marketing />
                  <span>{t("実行時間のみ ¥1/分", "BILLED AT 1¢ PER MINUTE")}</span>
                </div>
              </div>
            </div>
          </div>

          <div
            className="journey-tabs"
            role="tablist"
            aria-label={t("CI実行の流れ", "Stages of an OpenCI run")}
            aria-orientation="horizontal"
          >
            {journeySteps.map((step, index) => (
              <button
                key={step.label}
                onClick={() => {
                  setSelected(index);
                  setManual(true);
                }}
                onKeyDown={(event) => moveTab(event, index, journeySteps.length)}
                type="button"
                role="tab"
                id={`pipeline-step-${index}`}
                aria-controls="pipeline-summary"
                aria-selected={index === selected}
                tabIndex={index === selected ? 0 : -1}
              >
                <span className="step-num">0{index + 1}</span>
                <strong>{step.label}</strong>
                <Icon name="arrow" marketing />
              </button>
            ))}
          </div>
          <div
            className="journey-summary"
            id="pipeline-summary"
            role="tabpanel"
            aria-labelledby={`pipeline-step-${selected}`}
            tabIndex={0}
          >
            <div className="journey-summary-copy">
              {journeySteps.map((step, index) => (
                <p key={step.label} hidden={index !== selected}>
                  {step.summary}
                </p>
              ))}
            </div>
            <div className="journey-summary-meta">
              {journeySteps.map((step, index) => (
                <span key={step.label} hidden={index !== selected}>
                  {step.detail}
                </span>
              ))}
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
