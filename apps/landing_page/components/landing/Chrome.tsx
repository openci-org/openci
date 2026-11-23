"use client";
import { useEffect, useRef, useSyncExternalStore } from "react";
import { type Locale, locales, translator } from "../../../website/src/lib/i18n";
import { navigationLinks } from "../../../website/src/lib/product-links";
import { languageHref } from "../../../website/src/lib/language-url";
import { BrandMark, Icon } from "./Icon";

function subscribeLocation(callback: () => void) {
  window.addEventListener("hashchange", callback);
  return () => window.removeEventListener("hashchange", callback);
}
export function Header({ locale, path = "" }: { locale: Locale; path?: string }) {
  const t = translator(locale),
    home = `/${locale}/`;
  const details = useRef<HTMLDetailsElement>(null);
  const location = useSyncExternalStore(
    subscribeLocation,
    () => window.location.href,
    () => "",
  );
  const links = navigationLinks(locale);
  useEffect(() => {
    const menu = details.current!;
    const close = () => {
      menu.open = false;
    };
    const pointer = (event: PointerEvent) => {
      if (event.target instanceof Node && !menu.contains(event.target)) close();
    };
    const escape = (event: globalThis.KeyboardEvent) => {
      if (event.key === "Escape" && menu.open) {
        close();
        menu.querySelector("summary")?.focus();
      }
    };
    const media = matchMedia("(min-width: 801px)");
    document.addEventListener("pointerdown", pointer);
    document.addEventListener("keydown", escape);
    media.addEventListener("change", close);
    return () => {
      document.removeEventListener("pointerdown", pointer);
      document.removeEventListener("keydown", escape);
      media.removeEventListener("change", close);
    };
  }, []);
  return (
    <header className="product-nav">
      <div className="container nav-bar">
        <a className="wordmark" href={home}>
          <BrandMark />
          OpenCI
        </a>
        <nav className="desktop-links" aria-label={t("メインナビゲーション", "Main navigation")}>
          {links.map(([href, label]) => (
            <a key={href} href={href}>
              {label}
            </a>
          ))}
        </nav>
        <div className="nav-actions">
          <nav className="language-switcher" aria-label={t("言語を選択", "Choose language")}>
            {locales.map((lang) => {
              const target = `/${lang}/${path}`;
              return (
                <a
                  key={lang}
                  href={location ? languageHref(target, new URL(location)) : target}
                  hrefLang={lang}
                  lang={lang}
                  data-language-link=""
                  aria-current={lang === locale ? "page" : undefined}
                >
                  {lang === "en" ? "English" : "日本語"}
                </a>
              );
            })}
          </nav>
          <a className="action primary dashboard-link" href="https://dashboard.openci.org/">
            {t("ダッシュボード", "Dashboard")} <Icon name="external" marketing />
          </a>
          <details className="mobile-nav" ref={details}>
            <summary aria-label={t("メニュー", "Menu")}>
              <Icon name="menu" />
            </summary>
            <nav
              aria-label={t("モバイルナビゲーション", "Mobile navigation")}
              onClick={() => {
                if (details.current) details.current.open = false;
              }}
            >
              {[...links, ["https://dashboard.openci.org/", t("ダッシュボード", "Dashboard")]].map(
                ([href, label]) => (
                  <a key={href} href={href}>
                    {label}
                    <Icon name="external" marketing />
                  </a>
                ),
              )}
            </nav>
          </details>
        </div>
      </div>
    </header>
  );
}

function stored(key: string, value?: string) {
  try {
    if (value !== undefined) localStorage.setItem("openci-" + key, value);
    return localStorage.getItem("openci-" + key);
  } catch {
    return null;
  }
}

export function DisplayPreferences({ locale }: { locale: Locale }) {
  const t = translator(locale);
  const controls = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const host = controls.current!;
    const root = document.documentElement;
    const dark = matchMedia("(prefers-color-scheme: dark)");
    const reduced = matchMedia("(prefers-reduced-motion: reduce)");
    const themeButton = host.querySelector<HTMLButtonElement>("[data-theme]")!;
    const motionButton = host.querySelector<HTMLButtonElement>("[data-motion]")!;
    let theme = stored("theme"),
      pause = stored("paused") === "true";
    const sync = () => {
      const isDark = theme ? theme === "dark" : dark.matches;
      const still = reduced.matches || pause;
      root.dataset.theme = isDark ? "dark" : "light";
      root.dataset.motion = still ? "paused" : "active";
      motionButton.disabled = reduced.matches;
      themeButton.setAttribute("aria-pressed", String(isDark));
      motionButton.setAttribute("aria-pressed", String(still));
    };
    const toggleTheme = () => {
      theme = root.dataset.theme === "dark" ? "light" : "dark";
      stored("theme", theme);
      sync();
    };
    const toggleMotion = () => {
      pause = !pause;
      stored("paused", String(pause));
      sync();
    };
    themeButton.addEventListener("click", toggleTheme);
    motionButton.addEventListener("click", toggleMotion);
    dark.addEventListener("change", sync);
    reduced.addEventListener("change", sync);
    host.hidden = false;
    sync();
    return () => {
      themeButton.removeEventListener("click", toggleTheme);
      motionButton.removeEventListener("click", toggleMotion);
      dark.removeEventListener("change", sync);
      reduced.removeEventListener("change", sync);
    };
  }, []);
  useEffect(() => {
    const items = document.querySelectorAll<HTMLElement>("[data-reveal]");
    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries)
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
    });
    for (const item of items)
      if (item.getBoundingClientRect().top > window.innerHeight) {
        item.classList.add("will-reveal");
        observer.observe(item);
      }
    return () => {
      observer.disconnect();
      items.forEach((item) => item.classList.remove("will-reveal"));
    };
  }, []);
  return (
    <div
      ref={controls}
      className="display-controls"
      role="group"
      aria-label={t("表示設定", "Display preferences")}
      hidden
    >
      <button
        type="button"
        data-motion=""
        aria-label={t("アニメーションを一時停止", "Pause animation")}
      >
        <Icon name="pause" />
        <Icon name="play" marketing />
      </button>
      <button type="button" data-theme="" aria-label={t("ダークモード", "Dark mode")}>
        <Icon name="moon" />
        <Icon name="sun" />
      </button>
    </div>
  );
}
