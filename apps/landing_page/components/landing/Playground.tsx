"use client";
import { useEffect, useRef, useState } from "react";
import { type Locale, translator } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";
import { Landscape } from "./Landscape";

export function Playground({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const workflows = [
    {
      id: "test",
      label: t("PRのテスト", "Test a pull request"),
      file: "flutter_ci.dart",
      prompt: t(
        "プルリクエストの変更を解析して、Flutterのユニットテストを実行。",
        "Check a pull request for analyzer issues, then run the Flutter unit tests.",
      ),
      log: [
        "flutter pub get",
        "flutter analyze",
        "flutter test",
        t("すべてのテストが通りました。", "All tests passed."),
      ],
    },
    {
      id: "android",
      label: t("Androidビルド", "Build for Android"),
      file: "android_release.dart",
      prompt: t(
        "Androidアプリをビルドして、テスト配布用のAPKを作成。",
        "Build the staging flavor of the Android app and package an APK for testers.",
      ),
      log: [
        "flutter pub get",
        "flutter build apk --flavor staging",
        t("APKをパッケージ中", "Packaging the APK"),
        "app-staging-release.apk",
      ],
    },
    {
      id: "ios",
      label: t("TestFlightに配布", "Ship to TestFlight"),
      file: "ios_deploy.dart",
      prompt: t(
        "iOSアプリを署名して、ビルドをTestFlightにアップロード。",
        "Sign an iOS build and upload the IPA to TestFlight.",
      ),
      log: [
        t("署名の準備中", "Preparing signing credentials"),
        "flutter build ipa",
        t("IPAをアップロード中", "Uploading the IPA"),
        t("TestFlightへのアップロード完了。", "TestFlight upload complete."),
      ],
    },
  ];
  const [index, setIndex] = useState(0);
  const [step, setStep] = useState(-1);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const workflow = workflows[index];
  const last = workflow.log.length - 1;
  const running = step >= 0 && step < last;
  useEffect(() => {
    if (!running) return;
    const root = document.documentElement;
    const next = () => setStep((previous) => Math.min(previous + 1, last));
    const finishIfPaused = () => {
      if (root.dataset.motion === "paused") {
        clearTimeout(timer.current);
        setStep(last);
      }
    };
    timer.current = setTimeout(next, 820);
    const motion = new MutationObserver(finishIfPaused);
    motion.observe(root, { attributes: true, attributeFilter: ["data-motion"] });
    return () => {
      clearTimeout(timer.current);
      motion.disconnect();
    };
  }, [step, last, running]);
  function choose(value: string) {
    clearTimeout(timer.current);
    setIndex(workflows.findIndex((item) => item.id === value));
    setStep(-1);
  }
  const action = step === last ? t("デモを再生", "Replay demo") : t("デモを実行", "Run demo");
  return (
    <div className="lake" id="playground">
      <Landscape />
      <div className="run-console">
        <p className="run-prompt">{workflow.prompt}</p>
        <div className="run-tools">
          <label className="scenario-select">
            <Icon name="terminal" marketing />
            <select
              aria-label={t("デモのワークフロー", "Demo workflow")}
              value={workflow.id}
              onChange={(event) => choose(event.target.value)}
            >
              {workflows.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.label}
                </option>
              ))}
            </select>
            <Icon name="down" />
          </label>
          <span className="scenario-file">{workflow.file}</span>
          <button
            type="button"
            className="run-button"
            aria-disabled={running}
            aria-label={action}
            title={action}
            onClick={() => {
              if (!running)
                setStep(document.documentElement.dataset.motion === "paused" ? last : 0);
            }}
          >
            {running ? (
              <span className="run-spinner" />
            ) : (
              <Icon name={step === last ? "replay" : "up"} />
            )}
          </button>
        </div>
        <div className="run-status" role="status" aria-atomic="true">
          <span className="run-indicator" data-finished={step === last} aria-hidden="true" />
          <span>
            {step < 0
              ? t("ワークフローを選んで、デモを実行。", "Choose a workflow and run the demo.")
              : workflow.log[step]}
          </span>
          {step >= 0 && (
            <span className="run-count">
              {step + 1} / {last + 1}
            </span>
          )}
        </div>
      </div>
      <span className="landscape-credit">
        Blanca Lake, Washington ·{" "}
        <a href="https://unsplash.com/photos/4qKVQYOluDk">Yoshi Takekawa</a>
      </span>
    </div>
  );
}
