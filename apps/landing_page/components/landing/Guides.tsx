import Image from "next/image";
import startCover from "../../../website/public/images/landing/guide-start.webp";
import signingCover from "../../../website/public/images/landing/guide-signing.webp";
import hostingCover from "../../../website/public/images/landing/guide-hosting.webp";
import { translator, type Locale } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";

export function Guides({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const docs = `/${locale}/docs/`;
  const pricing = `/${locale}/pricing/`;
  const steps = [
    {
      title: t("SDKを追加", "Add the SDK"),
      text: t(
        "Flutterプロジェクトのルートで、ワークフロー用のSDKを開発依存に追加します。",
        "Add the workflow SDK as a development dependency at the root of your Flutter project.",
      ),
      points: [
        t("pubspec.yaml の dev_dependencies に追加", "Added under dev_dependencies"),
        t("既存の Flutter ツールチェーンをそのまま利用", "Uses your existing Flutter toolchain"),
      ],
      metaLabel: t("コマンド", "COMMAND"),
      command: "flutter pub add --dev openci_workflow",
      label: t("SDKを見る", "View the SDK"),
      href: "https://pub.dev/packages/openci_workflow",
    },
    {
      title: t("ワークフローを作成", "Write a workflow"),
      text: t(
        "リポジトリ直下のopenciディレクトリにDartファイルを置き、テスト内容と実行するブランチを指定します。",
        "Create a Dart file in the openci directory. Define the tests and the branches that should run them.",
      ),
      points: [
        t(
          "解析・テスト・ビルド・配布を関数呼び出しで記述",
          "Compose checks, builds, and deploys as Dart calls",
        ),
        t("アプリの変更と同じプルリクエストでレビュー可能", "Review CI changes alongside app code"),
      ],
      metaLabel: t("ワークフローファイル", "WORKFLOW FILE"),
      command: "openci/flutter_ci.dart",
      label: t("ファイルの記入例", "See an example"),
      href: docs + "quickstart/",
    },
    {
      title: t("ローカルからCIへ", "Go from local to CI"),
      text: t(
        "手元で実行を確認したら、GitHub Appとリポジトリを連携します。指定したイベントで同じ処理が動きます。",
        "Run the workflow locally, then connect your repository to the GitHub App to run it on the events you choose.",
      ),
      points: [
        t("手元の Mac と同じ挙動をクラウドでも再現", "Same Dart workflow locally and in the cloud"),
        t(
          "PR・ブランチ・タグなど必要なイベントに紐付け",
          "Trigger on PRs, branches, or release tags",
        ),
      ],
      metaLabel: t("ローカル実行", "RUN LOCALLY"),
      command: "dart run openci/flutter_ci.dart",
      label: t("トリガーの設定", "Configure triggers"),
      href: docs + "triggers/",
    },
  ];
  const stack = [
    {
      label: "FLUTTER",
      icon: "layers",
      marketing: true,
      href: docs + "flutter/",
    },
    {
      label: "DART SDK",
      icon: "code",
      marketing: false,
      href: "https://pub.dev/packages/openci_workflow",
    },
    {
      label: "GITHUB APP",
      icon: "github",
      marketing: false,
      href: docs + "triggers/",
    },
    {
      label: "APPLE SILICON",
      icon: "cpu",
      marketing: true,
      href: pricing,
    },
    {
      label: "TESTFLIGHT",
      icon: "rocket",
      marketing: false,
      href: docs + "secrets/",
    },
    {
      label: "GOOGLE PLAY",
      icon: "smartphone",
      marketing: false,
      href: docs + "flutter/",
    },
    {
      label: "TEAM SECRETS",
      icon: "lock",
      marketing: false,
      href: docs + "secrets/",
    },
    {
      label: "SELF-HOSTED",
      icon: "server",
      marketing: false,
      href: docs + "self-hosting/",
    },
  ];
  const guides = [
    {
      image: startCover,
      path: "quickstart/",
      category: t("クイックスタート", "QUICKSTART"),
      meta: t("約5分", "5 MIN"),
      title: t("最初のワークフローを動かす", "Run your first workflow"),
      text: t(
        "SDKを追加し、手元でテストを実行するまで。",
        "Install the SDK and run a test on your own machine.",
      ),
    },
    {
      image: signingCover,
      path: "secrets/",
      category: t("シークレット管理", "SIGNING & SECRETS"),
      meta: t("iOS / Android", "IOS / ANDROID"),
      title: t("署名キーをチームで管理する", "Manage signing keys"),
      text: t(
        "配布に使うキーを登録し、ワークフローから参照する方法。",
        "Store distribution credentials and use them in a workflow.",
      ),
    },
    {
      image: hostingCover,
      path: "self-hosting/",
      category: t("セルフホスト", "SELF-HOSTING"),
      meta: "APPLE SILICON",
      title: t("自分のMacでCIを運用する", "Run CI on your own Mac"),
      text: t(
        "Apple SiliconのMacとFirebaseを使うセルフホストの構成。",
        "Set up a self-hosted runner with an Apple Silicon Mac and Firebase.",
      ),
    },
  ];
  return (
    <>
      <section className="container section-pad" id="get-started" data-reveal="">
        <div id="quickstart" className="section-head">
          <div>
            <span className="eyeline">{t("クイックスタート", "QUICKSTART")}</span>
            <h2 className="section-title">
              {t("手元のFlutterアプリで", "Start with your own")}
              <br />
              {t("はじめる。", "Flutter app.")}
            </h2>
          </div>
          <p>
            {t(
              "解析とテストを手元で確かめてから、プルリクエストに接続します。",
              "Try your checks locally, then connect them to pull requests.",
            )}
          </p>
        </div>
        <ol className="steps">
          {steps.map((s, i) => (
            <li key={s.command}>
              <div className="step-title-col">
                <small>{String(i + 1).padStart(2, "0")}</small>
                <h3>{s.title}</h3>
              </div>
              <div className="step-body-col">
                <p>{s.text}</p>
                <ul className="step-points" role="list">
                  {s.points.map((point) => (
                    <li key={point}>{point}</li>
                  ))}
                </ul>
              </div>
              <div className="step-meta-col">
                <span className="step-meta-label">{s.metaLabel}</span>
                <code>{s.command}</code>
                <a className="text-link" href={s.href}>
                  <span>{s.label}</span> <Icon name="external" marketing />
                </a>
              </div>
            </li>
          ))}
        </ol>
      </section>

      <section
        id="integrations"
        className="container integrations-box"
        data-reveal=""
        aria-labelledby="integrations-heading"
      >
        <div className="integrations-lead">
          <span className="eyeline">{t("いつものツールと連携", "YOUR STACK, CONNECTED")}</span>
          <div>
            <h2 id="integrations-heading" className="section-title">
              {t("使い慣れた道具と、", "Works with the tools")}
              <br />
              {t("そのままつながる。", "you already trust.")}
            </h2>
            <p className="prose">
              {t(
                "GitHub、TestFlight、Google Play、セルフホストの Mac まで。Flutter 開発のワークフローに無理なく馴染みます。",
                "From GitHub and TestFlight to Google Play and self-hosted Macs, OpenCI fits right into your Flutter stack.",
              )}
            </p>
          </div>
        </div>
        <div className="integrations-grid">
          {stack.map((item) => (
            <a key={item.label} href={item.href}>
              <Icon name={item.icon} marketing={item.marketing} />
              <span className="integration-arrow" aria-hidden="true">
                <Icon name="external" marketing />
              </span>
              <span className="integration-label">{item.label}</span>
            </a>
          ))}
        </div>
      </section>

      <section className="tinted section-pad" id="guides" data-reveal="">
        <div className="container">
          <div className="guides-eyeline-row">
            <span className="eyeline">{t("ドキュメント", "DOCUMENTATION")}</span>
          </div>
          <div className="section-head">
            <h2 className="section-title">{t("開発者ガイド", "Developer guides")}</h2>
            <p>
              {t(
                "手元でのテストから、チームでの運用まで。",
                "From local tests to running CI for your team.",
              )}
            </p>
          </div>
          <div className="guides">
            {guides.map((g) => (
              <a key={g.path} href={docs + g.path}>
                <div className="cover">
                  <Image src={g.image} alt="" width="720" height="546" loading="lazy" />
                  <span className="guide-open" aria-hidden="true">
                    <Icon name="external" marketing />
                  </span>
                </div>
                <div className="guide-meta">
                  <span>{g.category}</span>
                  <span>{g.meta}</span>
                </div>
                <h3>{g.title}</h3>
                <p>{g.text}</p>
                <span className="text-link">
                  {t("ガイドを読む", "Read the guide")} <Icon name="external" marketing />
                </span>
              </a>
            ))}
          </div>
        </div>
      </section>

      <section className="container closing-banner" data-reveal="">
        <h2 className="section-title">
          {t("最初のFlutterテストを", "Run your first Flutter test")}
          <br />
          {t("OpenCIで動かす。", "with OpenCI.")}
        </h2>
        <p>
          {t(
            "Dartで書いて、Apple Siliconで回す。1分1円のシンプルなCI。",
            "Write in Dart, run on Apple Silicon, pay 1 cent per minute.",
          )}
        </p>
        <div className="actions">
          <a className="action primary" href="https://dashboard.openci.org/">
            {t("ダッシュボードを開く", "Open dashboard")} <Icon name="external" marketing />
          </a>
          <a className="action light-outline" href={docs + "quickstart/"}>
            {t("導入ガイド", "Quickstart guide")}
          </a>
        </div>
      </section>
    </>
  );
}
