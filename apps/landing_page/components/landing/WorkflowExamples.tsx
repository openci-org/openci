"use client";
import Image from "next/image";
import editorCover from "../../../website/public/images/landing/guide-start.webp";
import { useState } from "react";
import { moveTab, CopyCode } from "./controls";
import { workflowCode } from "./workflow-code";
import { translator, type Locale } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";

export function WorkflowExamples({
  locale,
  highlighted,
}: {
  locale: Locale;
  highlighted: string[];
}) {
  const t = translator(locale);
  const docs = `/${locale}/docs/`;
  const examples = [
    {
      id: "flutter",
      icon: "terminal",
      marketing: true,
      label: t("解析・テスト", "Analyze & test"),
      tabSummary: t(
        "静的解析とユニットテストをDartで並べて、PRごとに自動検証。",
        "Run static analysis and unit tests together on every pull request.",
      ),
      title: t("変更のたびに品質を確かめる。", "Check every change."),
      body: t(
        "静的解析とユニットテストを同じワークフローに並べます。プルリクエストで同じチェックを実行できます。",
        "Run static analysis and unit tests together, then use the same checks on pull requests.",
      ),
      file: "openci/flutter_ci.dart",
      guide: "flutter/",
    },
    {
      id: "android",
      icon: "box",
      marketing: true,
      label: "Android",
      tabSummary: t(
        "テスト配布用APKからGoogle Play向けApp Bundleまで一括生成。",
        "Build staging APKs and Google Play App Bundles in one workflow.",
      ),
      title: t("テスト用とストア用をビルドする。", "Build for testers and the store."),
      body: t(
        "ステージング用のAPKと、Google Playに提出するApp Bundleを生成します。",
        "Build a staging APK and an Android App Bundle for Google Play.",
      ),
      file: "openci/android_release.dart",
      guide: "flutter/",
    },
    {
      id: "testflight",
      icon: "rocket",
      marketing: false,
      label: "TestFlight",
      tabSummary: t(
        "チームのシークレットで署名キーを管理し、IPAをTestFlightへ。",
        "Manage signing credentials in team secrets and ship IPAs to TestFlight.",
      ),
      title: t("署名済みのIPAをTestFlightへ。", "Send a signed IPA to TestFlight."),
      body: t(
        "署名済みIPAのパスとApp Store Connectのキーを渡してアップロードします。キーはチームのシークレットで管理できます。",
        "Upload a signed IPA using its path and your App Store Connect API key. Keep the key in your team’s secrets.",
      ),
      file: "openci/ios_deploy.dart",
      guide: "secrets/",
    },
  ];

  const [selected, setSelected] = useState(0);
  return (
    <>
      <section id="workflow" className="container module-box" data-reveal="">
        <header id="apis" className="module-header">
          <div>
            <span className="eyeline">FLUTTER WORKFLOW API</span>
            <h2 className="section-title">
              {t("テストも配布も、", "Test and ship")}
              <br />
              {t("いつもの", "with ")}
              <em>Dart</em>
              {t("で。", ".")}
            </h2>
          </div>
          <p className="prose">
            {t(
              "ワークフローもDartで書くので、エディタの補完が使えます。変更はアプリと同じプルリクエストでレビューできます。",
              "Use editor autocomplete to write your workflows in Dart. Review changes alongside the app in the same pull request.",
            )}
          </p>
        </header>
        <div className="module-split">
          <div
            className="module-tabs"
            role="tablist"
            aria-label={t("Dart APIの実行例", "Dart API examples")}
            aria-orientation="vertical"
          >
            {examples.map((ex, i) => (
              <button
                key={ex.id}
                onClick={() => setSelected(i)}
                onKeyDown={(event) => moveTab(event, i, examples.length, true)}
                type="button"
                role="tab"
                id={"tab-" + ex.id}
                aria-controls={"workflow-" + ex.id}
                aria-selected={i === selected}
                tabIndex={i === selected ? 0 : -1}
              >
                <Icon name={ex.icon} marketing={ex.marketing} />
                <span>
                  <strong>{ex.label}</strong>
                  <span>{ex.tabSummary}</span>
                </span>
              </button>
            ))}
          </div>
          <div className="scene-stage">
            <Image
              className="scene-backdrop"
              src={editorCover}
              alt=""
              width="720"
              height="546"
              loading="lazy"
            />
            {examples.map((ex, i) => (
              <div
                key={ex.id}
                className="example editor-window"
                role="tabpanel"
                id={"workflow-" + ex.id}
                aria-labelledby={"tab-" + ex.id}
                hidden={i !== selected}
                tabIndex={0}
              >
                <div className="code-block">
                  <div className="editor-bar">
                    <span className="window-dots" aria-hidden="true">
                      <i />
                      <i />
                      <i />
                    </span>
                    <span className="editor-file">{ex.file}</span>
                    <CopyCode code={workflowCode[i]} locale={locale} />
                  </div>
                  <div dangerouslySetInnerHTML={{ __html: highlighted[i] }} />
                </div>
                <div className="editor-caption">
                  <h3>{ex.title}</h3>
                  <p>{ex.body}</p>
                  <a className="text-link" href={docs + ex.guide}>
                    {t("ガイドを読む", "Read the guide")} <Icon name="external" marketing />
                  </a>
                </div>
              </div>
            ))}
          </div>
        </div>
        <a className="module-footer-link" href={docs + "flutter/"}>
          {t("Flutter API一覧を見る", "Explore the Flutter API reference")}{" "}
          <Icon name="external" marketing />
        </a>
      </section>
    </>
  );
}
