import { Playground } from "./Playground";
import { translator, type Locale } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";

export function Hero({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const docs = `/${locale}/docs/`;
  const pricing = `/${locale}/pricing/`;
  const features = [
    {
      icon: "cpu",
      title: t("Apple SiliconのMac", "Apple Silicon Macs"),
      text: t(
        "FlutterアプリのテストからiOSビルドまで、OpenCIが用意したmacOSランナーで実行できます。",
        "Run Flutter tests and build iOS apps on macOS runners managed by OpenCI.",
      ),
      link: t("Cloudの料金を見る", "See cloud pricing"),
      href: pricing,
    },
    {
      icon: "code",
      title: t("Dartで書けるAPI", "APIs written for Dart"),
      text: t(
        "解析、テスト、ストアへのアップロード。アプリと同じDartで、必要な処理を組み合わせます。",
        "Combine analysis, tests and store uploads in the same language you use for your app.",
      ),
      link: t("APIの例を見る", "Explore the APIs"),
      href: "#apis",
    },
    {
      icon: "person",
      title: t("Flutter開発歴10年", "10 years building with Flutter"),
      text: t(
        "Flutterアプリを10年作ってきた開発者が、日々のテストやリリースに使う道具としてOpenCIを開発しています。",
        "OpenCI is built by a developer with ten years of Flutter experience, for the tests and releases that come with shipping real apps.",
      ),
      link: t("最初のテストを動かす", "Run your first test"),
      href: "#quickstart",
    },
  ];
  const facts = [
    {
      value: t("¥1 / 分", "1¢ / min"),
      label: t("VM準備完了後から課金（税込）", "Billed after VM setup, tax included"),
    },
    {
      value: "Apple Silicon",
      label: t("Flutter専用のmacOSランナー", "Dedicated macOS runners for Flutter"),
    },
    {
      value: "Dart 100%",
      label: t("YAML不要、補完と型チェック付き", "No YAML, full editor autocomplete"),
    },
    {
      value: t("同時実行制限なし", "No concurrency cap"),
      label: t("チーム全員の並列ジョブに対応", "Run team builds in parallel"),
    },
  ];
  return (
    <>
      <section className="container intro" aria-labelledby="intro-heading">
        <a className="claim" href={pricing + "#comparison"}>
          <span>CLOUD</span>
          {t("世界最安", "World’s lowest-priced")}
          <sup>*</sup>
          {t("のmacOSランナー", " macOS runners")}
        </a>
        <h1 id="intro-heading">
          {locale === "ja" ? (
            <>
              <em>Flutter</em>専用のCIを、
            </>
          ) : (
            <>
              CI for <em>Flutter,</em>
            </>
          )}
          <br />
          <strong>
            {locale === "ja" ? (
              "1分1円で。"
            ) : (
              <>
                <span>1 cent</span> per minute.
              </>
            )}
          </strong>
        </h1>
        <p>
          {t(
            "Apple SiliconのMacで、ビルドとテストを自動化。",
            "Automate builds and tests on Apple Silicon Macs.",
          )}
          <br />
          {t(
            "TestFlightへの配布も、DartのAPIで書けます。",
            "Ship to TestFlight with APIs you can call from Dart.",
          )}
        </p>
        <div className="actions">
          <a className="action" href="#playground">
            {t("デモを試す", "Try the demo")}
          </a>
          <a className="action primary" href="https://dashboard.openci.org/">
            {t("OpenCIをはじめる", "Start with OpenCI")} <Icon name="external" marketing />
          </a>
        </div>
      </section>

      <section
        className="container"
        aria-label={t("ワークフローのデモと特徴", "Try a workflow and explore features")}
      >
        <Playground locale={locale} />
        <div className="features" id="features">
          {features.map((f) => (
            <article key={f.href}>
              <Icon name={f.icon} marketing={f.icon === "cpu"} />
              <h2>{f.title}</h2>
              <p>{f.text}</p>
              <a className="text-link" href={f.href}>
                {f.link} <Icon name="external" marketing />
              </a>
            </article>
          ))}
        </div>
      </section>
      <section
        className="container facts-strip"
        data-reveal=""
        aria-label={t("OpenCIの基本仕様", "OpenCI key facts")}
      >
        <div className="facts-grid">
          {facts.map((fact) => (
            <div key={fact.value}>
              <strong>{fact.value}</strong>
              <span>{fact.label}</span>
            </div>
          ))}
        </div>
        <p className="facts-caption">{t("ワークフローで使えるツール", "IN YOUR WORKFLOW")}</p>
        <div className="tool-marks">
          <a href={docs + "flutter/"}>
            <Icon name="layers" marketing />
            Flutter
          </a>
          <a href={docs + "workflows/"}>
            <Icon name="code" />
            Dart
          </a>
          <a href={docs + "triggers/"}>
            <Icon name="github" />
            GitHub
          </a>
          <a href={docs + "self-hosting/"}>
            <Icon name="cpu" marketing />
            macOS
          </a>
        </div>
      </section>
    </>
  );
}
